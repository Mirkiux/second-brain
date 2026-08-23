# Second Brain Build Order

Eleven steps, two phases, one continuous sequence — ordered by what's cheap to change later versus what isn't, not by what's exciting to build first.

## Three rules governing the order below

Ship a thin slice end to end before building any single piece deep — a working loop with a weak knowledge base beats a perfect knowledge base with no loop around it. Do the things that are hard to retrofit early (schema, provenance, an API boundary you own) and defer the things that are easy to swap later (which database, which orchestration layer).

Don't move to Phase 2 on a calendar — move when the friction you're trying to solve actually shows up. The trigger criteria are called out below, between step 7 and step 8.

## Phase 1 — Ship

Notion, a thin API you own, and an MCP server — working end to end in days.

### 1. Define the schema — on paper, before any tool

Entity types (Note, Decision, Project, Source, Person), the relations between them, and the metadata every record carries: timestamp, provenance (human-authored vs. agent-written), confidence.

> **Why first:** the schema is the one thing every later layer inherits. An hour here prevents weeks of rework in the API, the CLI, and the eventual graph migration.

### 2. Phase 0 dry run — zero code

Point Claude Code (or Copilot, or Kiro) at Notion's own official MCP server, add one steering doc describing the schema, and use it for real work for one to two weeks.

> **Why:** a walking skeleton. This validates the workflow with an afternoon of setup instead of a month of engineering, and tells you what step 4 actually needs to do before you build it.

### 3. Build the Notion workspace to the schema

Databases and properties that mirror step 1 exactly — not a freeform notebook. This is what makes the later API layer thin instead of a translation mess.

### 4. Thin REST API — the keystone

A handful of endpoints your own: create, get, search, update / link, list-by-type. Generate embeddings on write and keep your own vector index alongside Notion, since Notion's native search is keyword-only. Add dedup and staleness checks at write time here — not later.

> **Why now, and why yours:** every consumer below (CLI, MCP, agents) talks to this, never to Notion directly. That's the boundary that lets you swap the backend in Phase 2 without touching anything downstream.

### 5. CLI — a thin wrapper

A handful of commands over the same API. Its job is scriptability — cron jobs, git hooks, calendar sync — more than daily human use.

### 6. MCP server — a thin protocol translator

Exposes the same API's operations as typed tools. No logic lives here that doesn't already live in step 4 — one source of truth, two transports.

### 7. Per-tool steering docs, not a custom harness

A short instructions file per environment — `CLAUDE.md`, `.cursorrules`, `copilot-instructions.md`, Kiro's steering docs — telling each agent when and how to call your tools.

> **Why this instead of building a harness:** MCP clients already give you the provider-agnostic layer. Writing per-tool instructions is a config task; a custom harness would be redundant infrastructure.

---

**Move to Phase 2 when two or more of these show up — not on a fixed date:**

- **Retrieval precision is visibly dropping** as the notes pile grows.
- **You need multi-hop relationship queries** Notion's database model can't express.
- **You're hitting Notion API rate limits** under real usage.
- **The schema needs a shape** Notion's flat databases can't represent.

---

## Phase 2 — Scale

Swap the backend behind the same interface, then earn autonomy step by step.

### 8. Confirm provenance and version history

Every record should already carry who or what wrote it and a change log — if step 4 included this from the start, there's nothing new to build here, only to verify.

### 9. Introduce a graph DB alongside a vector index

Graph for explicit relations and provenance queries; vector index for semantic similarity — a graph alone is weak at fuzzy retrieval. Migrate by swapping the adapter behind your Phase 1 API, one entity type at a time, never a rewrite.

> **Why the graph doesn't replace curation:** the accumulation-quality problem is solved by the dedup and staleness logic from step 4, not by the storage engine. The graph adds relationship reasoning on top of curation you should already have.

### 10. Extend the API, CLI, and MCP server with graph-native queries

Traversal and provenance queries the flat schema couldn't support. The contracts stay backward compatible — this is addition, not a breaking change.

### 11. Local agents — manual first, then approval-gated, then dockerized

Start with agents you trigger by hand. Move to agents that propose writes for you to confirm before they land. Only once that approval log shows a low error rate, hand narrow, well-scoped task types to dockerized, orchestrated agents — and expand scope gradually, not all at once.

> **Why in that order:** the real risk here is wrong information landing in a knowledge base you trust, not compute isolation. A pod boundary contains a runaway process; it doesn't catch a hallucinated fact. Trust is earned through the approval log, then autonomy follows.

## Reference — why this order, named

| Principle | Meaning here |
|---|---|
| **Walking skeleton** | Ship a thin slice that works end to end before building any single piece deep. Step 2 is this in its purest form. |
| **YAGNI** | Don't build the abstraction before real usage tells you its shape — the reason step 4 comes after step 2, not before it. |
| **Strangler fig** | Replace a system piece by piece behind a stable interface. The reason step 9 is a backend swap under step 4's API, not a rewrite of steps 1–7. |
| **Provenance by default** | Track who or what wrote each fact from the first write, not once autonomy makes it urgent — the reason step 8 is a checkpoint, not new construction. |
