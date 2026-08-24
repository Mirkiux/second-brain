# Second Brain — Agent Instructions

This is the one canonical copy of how an AI agent should use this knowledge base. Every per-tool file (`CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `.cursor/rules/second-brain.mdc`, `.kiro/steering/second-brain.md`) points here instead of repeating it — one source, several thin adapters, same reasoning as [`data-model.md`](../data-model.md)'s repeating patterns.

## Where the data lives right now

Until [build order](../build_order.md) step 4 (the thin REST API) exists, agents reach the knowledge base **directly through Notion** — via whichever of these two transports the environment actually allows:

- **MCP servers allowed (default):** the Notion MCP server — see [`mcp/README.md`](mcp/README.md) for per-client setup. Use its tools directly (`notion-search`, `notion-fetch`, `notion-create-pages`, `notion-update-page`, `notion-query-data-sources`, …).
- **MCP servers blocked (some corporate environments allow CLI tools but not MCP):** Notion's official `ntn` CLI instead — see [`cli/README.md`](cli/README.md) for install, auth, and the command-to-MCP-tool mapping. Same operations, run as shell commands instead of tool calls; the "before writing anything" rules below apply identically either way.

If you're unsure which applies, check what's already connected before assuming: an MCP `notion` connection listed by the client, or `ntn --version` succeeding plus `NOTION_API_TOKEN` set, tells you which path this environment is already on.

Once step 4 ships, talk to that API instead of Notion directly — through either transport; the API is where dedup, staleness checks, and embeddings live, and bypassing it re-creates the exact curation gap this project exists to avoid.

## Schema awareness

Read [`data-model.md`](../data-model.md) before writing anything. The short version: eleven databases in three layers (structural spine, knowledge entities, cross-cutting), held together by four patterns — self-relations for lineage, Status for lifecycle, optional most-specific scope, Topic tags for retrieval. Every rule below is one of those four patterns applied to a specific situation.

## Before writing anything

1. **Search first.** Check Notes, Decisions, and Topics for existing entries on the same subject before creating a new one. This project's whole premise is that knowledge accumulates instead of being re-derived — skipping the search defeats it.
2. **If it contradicts something that exists:** don't edit the old entry in place. Decide which case you're in:
   - Clearly wrong, new information corrects it → create the new entry, link it via `Supersedes`, set the old entry's Status to `Superseded`.
   - Genuinely ambiguous, both claims look credible → create the new entry, link it via `Conflicts With`, set Status to `Disputed` on both, and **stop** — surface it, don't resolve it yourself. This is the one case where silent action is the wrong move even for a trusted agent.
3. **Scope it to the most specific level that applies** (Work Item over Repo over Project over Workplace) — don't fill in every scope relation, just the narrowest one.
4. **Tag Topics.** This is what lets a lesson from one project surface in an unrelated one later — an untagged Note is much less useful than a tagged one.
5. **Set Provenance to `Agent`, and Epistemic Status honestly.** `Confirmed` means verified, not "I'm fairly confident" — use `Hypothesis` or `Speculation` when that's what it actually is.

## Research work (Research Question / Experiment)

Don't force exploratory work into a ticket-shaped Note. State the Hypothesis before running anything, record the Conclusion honestly even when it's `Refuted` or `Abandoned` — those are the entries most likely to save future-you from repeating a dead end — and use `Branches From` when a result sends the work in a new direction instead of overwriting the prior attempt.

## What not to automate yet

Per [build order](../build_order.md) step 11: propose, don't commit, for anything non-trivial until an approval-gated flow exists. Read freely; write freely to your own session's Notes; treat Decisions and anything marked `Generalizable` as needing a human look before you create or supersede one.
