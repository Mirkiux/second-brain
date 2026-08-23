# Terraform — Second Brain schema

Provisions the eleven databases from [`../data-model.md`](../data-model.md) using the community [`delize/notion`](https://registry.terraform.io/providers/delize/notion) provider. Scope is deliberately narrow: **schema only**. Actual Notes, Decisions, Experiments and every other knowledge entry flow through the API/CLI/MCP layer from [step 4](../build_order.md#4-thin-rest-api--the-keystone) onward, never through `notion_database_entry` — Terraform's plan/apply/drift model doesn't belong on top of an ever-growing, agent-written knowledge stream. The one exception is a handful of genuinely static reference rows (an initial Topic list, your Workplace entries) if you want those version-controlled too.

For the full prerequisites-through-`apply` walkthrough, start at the [repo README](../README.md) — this file is technical reference for what's in here, not the onboarding guide.

## Before you trust this in production

- **`delize/notion` is a small, actively-maintained community provider (v0.9.0, no official 1.0 yet), not an official one.** Fine for one-time or occasional schema scaffolding; pin the version (already done in `versions.tf`) and read every plan.
- **Two-way relations are unverified.** The provider's relation resource doesn't expose a synced/dual-property flag. `relations.tf` defines both directions explicitly for the two edges where bidirectional browsing matters most (Project↔Repo, Repo↔Work Item). For every other relation, check after the first `apply` whether Notion mirrored a property on the other side automatically — if not and you want it, add the reverse resource.
- **Source's raw-content attachment field isn't provider-supported yet** — there's no Files & Media property resource in `delize/notion`. Add that one field by hand in the Notion UI after applying; it's a single manual step, not a recurring one.
- Destroying a `notion_database` resource archives it in Notion rather than deleting it — recoverable, but don't treat `terraform destroy` as harmless because of that.

## Files

| File | Contents |
|---|---|
| `versions.tf` | Provider pin, `NOTION_TOKEN`-based auth |
| `variables.tf` | `root_page_id` |
| `databases.tf` | The eleven `notion_database` resources |
| `properties_spine.tf` | Fields for Workplace / Project / Repo / Work Item |
| `properties_knowledge.tf` | Fields for Research Question / Experiment / Note / Decision / Source, plus the common-metadata `for_each` block |
| `properties_crosscutting.tf` | Fields for Person / Topic |
| `relations.tf` | Every edge from the data model's relation tables, including the `for_each`-generated optional scope relations |
| `outputs.tf` | Database IDs, for the API layer's config |
