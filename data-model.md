# Second Brain Data Model

Eleven databases in three layers, connected by four repeating patterns. Referenced from [step 1](README.md#1-define-the-schema--on-paper-before-any-tool) of the build order.

## Overview

- **Structural spine** — `Workplace → Project ↔ Repo ↔ Work Item`. Where the work happened.
- **Knowledge entities** — `Research Question`, `Experiment`, `Note`, `Decision`, `Source`. What was learned.
- **Cross-cutting** — `Person`, `Topic`. Independent of the spine; the retrieval layer that lets knowledge from one project surface in another.

```
Workplace ─1:N→ Project ─N:N↔ Repo ─N:N↔ Work Item
                                          │  optional scope (most specific level)
        ┌───────────────┬─────────────┬──┴──────────┬─────────┐
Research Question ← Experiment   Note ↺        Decision ↺   Source
        │                                        │             │
        └──────────────── Topic / Person (tags, authorship) ───┘
```

## Four repeating patterns

Every entity below is built from the same four moves — learn these once, not per-entity.

| Pattern | What it means |
|---|---|
| **Self-relations for lineage** | Supersedes, Conflicts with, Branches from — never edit history in place, add a new record and link it. |
| **Status for lifecycle** | Every knowledge entity carries a state (Active, Superseded, Disputed, Answered, Abandoned…) so retrieval can exclude what's no longer current. |
| **Optional, most-specific scope** | Relate to the single most specific spine level that applies (Work Item over Repo over Project over Workplace) — higher levels are implied, not duplicated. |
| **Topic tags for retrieval** | Cross-cutting, independent of the spine — the mechanism that lets a lesson from one project surface in an unrelated one. |

## Structural spine

| Entity | Key fields | Relations |
|---|---|---|
| **Workplace** | Name, Kind (Personal / Employer / Client) | → Project (1:N) |
| **Project** | Name, Status | ← Workplace · ↔ Repo (N:N) |
| **Repo** | Name, URL, Kind (Project-specific / General) | optional ↔ Project (empty for General) · ↔ Work Item (N:N) · ↔ Topic |
| **Work Item** | Name, Type (Ticket / Session / Plan step), Status (Open / Closed) | ↔ Repo · ← Note / Decision / Source / Experiment (optional scope) |

## Knowledge entities

| Entity | Key fields | Relations |
|---|---|---|
| **Research Question** | Question, Status (Open / Answered / Abandoned) | optional → Project · ↔ Topic · ← Experiment (investigates) |
| **Experiment** ↺ *branches from* | Hypothesis, Method / config, Reproducibility metadata (code ref, dataset version, params), Result, Conclusion (Validated / Refuted / Inconclusive / Abandoned) | → Research Question · optional → Work Item |
| **Note** ↺ *supersedes* | Body, Subtype (Fact / Pattern / Gotcha / Preference / Open question), Reusability (Project-specific / Generalizable) | optional scope · ↔ Topic · → Person (author) · optional → Source (derived from) |
| **Decision** ↺ *supersedes · conflicts* | Context, Decision, Consequences, Status (Active / Superseded / Disputed / Deprecated) | optional scope · ↔ Topic · → Person · → Experiment (evidence) · optional → Source (derived from) |
| **Source** | Title, Reference / URL, Type, Raw content (Notion file attachment) | optional scope · ↔ Topic |

## Raw content — no new architecture needed

You already have a bronze / silver / gold pipeline — it's `Source → Note → Decision`.

- **Source = raw.** The untouched capture — transcript, scraped page, PDF, chat export. Attach the file to the Source page itself rather than pasting it into a Note; keep it as close to unprocessed as possible.
- **Note = processed.** An atomic, distilled claim linked back to the Source it came from via the `derived from` relation — this is already what a Note is by construction, once that relation is traceable.
- **Decision / Generalizable Note = curated.** The trusted, reusable output — already marked out by Status, Epistemic status, and Reusability. No fourth tier required.

## Cross-cutting

| Entity | Key fields | Relations |
|---|---|---|
| **Person** | Name, Role | ↔ any entity, as Author / Owner / Stakeholder |
| **Topic** | Name | ↔ Research Question / Note / Decision / Source (cross-project retrieval) |

## Common metadata — Note, Decision, Source, Research Question, Experiment

| Field | Purpose |
|---|---|
| **Created** | Timestamp, set once. |
| **Provenance** | Human-authored vs. agent-written. |
| **Confidence** | How sure the author was at write time. |
| **Epistemic status** | Confirmed / Hypothesis / Speculation — what *kind* of claim this is, distinct from confidence. |
| **Last-validated** | Separate from Created — flags an entry as due for recheck. |
| **Source link** | The PR, commit, transcript, or doc that grounds the claim. |
