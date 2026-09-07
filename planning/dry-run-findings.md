# Phase 0 Dry-Run Findings

[`build_order.md`](../build_order.md) step 2 is a walking skeleton: use Notion through its
own transport for real work for a few weeks, and let that tell you *"what step 4 actually
needs to do before you build it."* This file is that feedback, accumulated as it shows up.

Status: **in dry run.** Steps 1–3 done, step 7 partially done (`harnessing/`). Steps 4–6
(own API, CLI, MCP server) not started. Transport in use on the WSL box: the `ntn` CLI
(the MCP server is Windows-only in the current setup — see
[[ntn login credentials in the OS keychain don't survive a bare WSL shell]]).

---

## Finding 1 — Notion's `/v1/search` is unusable for "search before write"

Verified live against the workspace, 2026-09-06. Full detail is a Gotcha Note in the KB
("Notion /v1/search matches titles only, tokenised OR, no stopword removal"). Summary:

| Behaviour | Consequence |
|---|---|
| Matches **titles only** — never `rich_text` (a Note's Body) or page content | Any entry whose overlap with the query is in the body is invisible |
| Tokenised, **any-token OR**, order-independent | Broad recall, no precision |
| **No stopword removal** (`and` → 10 hits, `the` → 22) | Natural-language queries ("MS Data Science", "Optimization and Computational Linear Algebra") return a pile of unrelated titles that share a common word |
| Prefix match on word starts; no relevance score; default sort = last-edited | Can't rank; can't tell a strong hit from an incidental one |

`AGENT_INSTRUCTIONS.md`'s rule 1 ("Search first") was only as good as this — i.e. not good.

### Interim mitigation (shipped)

[`harnessing/scripts/sb-search.mjs`](../harnessing/scripts/sb-search.mjs) — a local,
zero-dependency Node script:

- pulls every row of the 11 databases to `~/.cache/second-brain/kb.json` (one paginated
  `data_sources/*/query` per DB; ~170 rows today, sub-second);
- searches locally over **title + all rich_text bodies + Topic tag names**, ranked
  (phrase hit > title token > topic token > body token; superseded/disputed entries
  down-weighted);
- shells out to `ntn` so it reuses existing auth;
- auto-refreshes when the cache is > 12 h old; `--refresh` forces it.

`AGENT_INSTRUCTIONS.md` now mandates `sb-search` over `/v1/search`. This is a **bridge, not
step 4** — no embeddings, no semantic matching, no write-path dedup. It works only because
the KB is small enough to scan in full.

### What this pins down for step 4

The step-4 `search` endpoint must:

1. Search **body text and title**, not just title.
2. Return a **relevance score** and sort by it.
3. Do **semantic** retrieval (embeddings generated on write, own vector index) *and*
   keyword — the "GitLab CI gotcha surfaces during unrelated work" use case in
   `harnessing/AGENT_INSTRUCTIONS`/cv-crafter's `knowledge-base.md` is inherently semantic.
4. Filter by type, Topic, scope (Workplace/Project/Repo/Work Item), and Status (exclude
   `Superseded`/`Deprecated`/`Abandoned` by default).
5. Back a **write-time dedup check**: on create, run the incoming title+body through the
   same search; if an entry scores above a threshold, surface it to the caller before the
   write lands (this is where "supersede vs. new" gets decided).

Given the KB scale (hundreds, not millions), the vector index can be a flat file or
`sqlite-vec`/`lancedb` — not a separate service. `sb-search.mjs`'s cache + extraction
logic is a reasonable starting point for the endpoint's read path.

---

## Finding 2 — transport auth on WSL is fragile

`ntn login` stores its token in the OS keychain; a bare WSL shell has no keyring daemon, so
the token silently disappears between sessions (`ntn doctor` → "no token found"). Fixed by
re-running `ntn login`, but the durable answer is `NOTION_API_TOKEN` (the reusable
integration secret). Detail: KB Gotcha "ntn login credentials in the OS keychain don't
survive a bare WSL shell". Step 4/5/6 implication: whatever the API/CLI/MCP server uses for
Notion auth should be the **integration token via env**, not an interactive keychain login.

---

## Open questions still to resolve during the dry run

- Does the "most-specific scope" rule hold up in practice, or do entries keep wanting two
  scopes? (watch when writing session Notes)
- Are Topics converging on a stable vocabulary, or sprawling? (30 today; check for
  near-duplicates like "Agent-tooling" vs "Agent Harness Design")
- Is the Source → Note → Decision pipeline actually being used, or are raw captures going
  straight into Note bodies?
