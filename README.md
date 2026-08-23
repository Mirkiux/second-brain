# Second Brain

A personal, accumulative knowledge base — Notion today, a knowledge graph once it earns it. The full plan is [`build_order.md`](build_order.md); the schema this guide provisions is [`data-model.md`](data-model.md). This file is everything you need to go from a blank Notion workspace to all eleven databases existing, in order.

## Prerequisites

- A Notion account (the free plan is enough — integrations don't require a paid workspace).
- [Terraform](https://developer.hashicorp.com/terraform) >= 1.5.
- Git.

## 1. Install Terraform

**Windows**
```powershell
winget install HashiCorp.Terraform
```
(Chocolatey: `choco install terraform`. Scoop: `scoop install terraform`.)

**macOS**
```shell
brew install terraform
```

**Linux**
Add HashiCorp's apt/yum repository per [their install docs](https://developer.hashicorp.com/terraform/install), or download the binary from the releases page and put it on your `PATH`.

Verify, on any OS:
```shell
terraform -version
```

## 2. Create a Notion integration

1. Go to [notion.so/my-integrations](https://www.notion.so/my-integrations) and click **New integration**.
2. Name it something recognizable — `second-brain-terraform` — and associate it with your workspace.
3. Under **Capabilities**, enable **Read content**, **Update content**, and **Insert content**. Leave the user-information capabilities off; nothing here needs them.
4. Save, then copy the **Internal Integration Secret** it gives you. Treat it like a password — it's the credential that lets Terraform create and modify things in your Notion workspace.

## 3. Create and share the parent page

1. In Notion, create a new page — call it **Second Brain**. This page becomes the parent of all eleven databases; Terraform creates them underneath it.
2. Open the page's `···` menu → **Connections** → add the integration you just created. This step can't be automated — the Notion API can't see anything you haven't explicitly shared with the integration, no matter what the token can otherwise do.
3. Copy the page's ID: the 32-character string at the end of its URL (`notion.so/Second-Brain-<32 characters>`). With or without dashes both work.

## 4. Configure this repo

```shell
git clone https://github.com/Mirkiux/second-brain.git
cd second-brain/terraform
cp terraform.tfvars.example terraform.tfvars
```

Paste the page ID from step 3 into `terraform.tfvars` as `root_page_id`.

Set the integration token as an environment variable — never put it in a `.tf` or `.tfvars` file, and `terraform.tfvars` is already gitignored so it won't get committed by accident:

```shell
# bash / Git Bash
export NOTION_TOKEN="secret_..."
```
```powershell
# PowerShell
$env:NOTION_TOKEN = "secret_..."
```

## 5. Provision the schema

```shell
terraform init
terraform validate
terraform plan
```

Read the plan before you go further — it should show exactly 11 `notion_database` resources being created, plus their properties and relations, and nothing else. Then:

```shell
terraform apply
```

Type `yes` to confirm.

## 6. Verify, and finish the two manual steps

- Open the **Second Brain** page in Notion — you should see all 11 databases listed under it.
- Spot-check the relations that matter most for bidirectional browsing: open a Repo entry and confirm you can see both its Projects and, from a Project entry, its Repos. If a mirror you want is missing somewhere else, `terraform/README.md` explains why and how to add it.
- Add the **Files & Media** property to the Source database by hand — this one field isn't Terraform-managed yet (see `terraform/README.md` for why).
- Pull the database IDs you'll need for the API layer next:
  ```shell
  terraform output -json database_ids
  ```

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `object_not_found` on apply | The parent page isn't shared with the integration — redo step 3.2. |
| `unauthorized` / 401 | `NOTION_TOKEN` isn't set, is stale, or was copied with extra whitespace. |
| Property or database "already exists" / 409 | A previous `apply` partially succeeded. Run `terraform plan` to see the actual drift before touching anything by hand. |
| `terraform plan` wants to recreate a property after a rename | Renaming most property resources here forces replacement — see the schema notes in `terraform/README.md`. |

## What's next

Schema provisioned means [build order](build_order.md) step 3 is done. Step 4 — the thin REST API — is next, and it's what everything after this point (CLI, MCP server, agents) will actually talk to instead of Notion directly.
