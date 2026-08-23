# Terraform — Second Brain schema

Provisions the eleven databases from [`../data-model.md`](../data-model.md) using the community [`delize/notion`](https://registry.terraform.io/providers/delize/notion) provider. Scope is deliberately narrow: **schema only**. Actual Notes, Decisions, Experiments and every other knowledge entry flow through the API/CLI/MCP layer from [step 4](../README.md#4-thin-rest-api--the-keystone) onward, never through `notion_database_entry` — Terraform's plan/apply/drift model doesn't belong on top of an ever-growing, agent-written knowledge stream. The one exception is a handful of genuinely static reference rows (an initial Topic list, your Workplace entries) if you want those version-controlled too.

## One-time setup

1. Create a Notion integration at [notion.so/my-integrations](https://www.notion.so/my-integrations) and copy its token.
2. Create (or pick) the Notion page that will be the parent of all eleven databases, and **share it with the integration** from the page's `···` menu — the API can't see anything you haven't explicitly shared, and nothing in Terraform can do this step for you.
3. Copy that page's ID (the 32-character string in its URL) into `terraform.tfvars` (copy `terraform.tfvars.example` — never commit the real file).
4. Export the token as an environment variable rather than putting it in any `.tf`/`.tfvars` file:
   ```shell
   export NOTION_TOKEN="secret_..."
   ```
5. `terraform init`, then `terraform plan` and read it before `terraform apply`.

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
