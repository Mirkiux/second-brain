# Second Brain

A personal, accumulative knowledge base — Notion today, a knowledge graph once it earns it. The full plan is [`build_order.md`](build_order.md); the schema this guide provisions is [`data-model.md`](data-model.md). This file is everything you need to go from a blank Notion workspace to all eleven databases existing, in order.

Three parts, in order: the one thing nothing can automate, then your choice of an agent or your own hands for the rest, then the schema itself.

## 1. Mandatory manual steps

Do this first, regardless of which path you take in part 2 or 3 below. Notion doesn't expose an API to create an integration or to share a page with one — the same reason there's no API to mint yourself an OAuth app on most platforms. No agent, script, or skill in this repo can do these two things for you.

1. Go to [app.notion.com/developers/connections](https://app.notion.com/developers/connections) (the older [notion.so/my-integrations](https://www.notion.so/my-integrations) link still redirects here) and click **New connection** (older Notion versions label the same button **New integration**).
2. Name it something recognizable — `second-brain-terraform`.
3. Under **Authentication method** (Notion's own screen describes each option — this is what to look for, whatever it's labeled in your language or UI version):
   - **Access token** *(current UI; older UI calls this "Internal")* — a static API token scoped to one workspace. **This is the one to pick.**
   - **OAuth** *(older UI: "Public")* — a rotating token pair for apps distributed across multiple workspaces via a browser consent flow. Don't pick this one — Terraform can't drive an interactive OAuth flow, and this is unrelated to the separate OAuth flow used by Notion's hosted MCP server in part 2/3 below, which isn't something you set up here at all.
4. Create it, then look for capability toggles — **Read content**, **Update content**, **Insert content** — and enable them; where exactly they appear has moved around between Notion UI versions, but the names haven't.
5. Copy the secret it gives you — labeled **Access Token** or **Internal Integration Secret** depending on your Notion UI version, same thing either way. Treat it like a password; it's the credential Terraform uses to create and modify things in your Notion workspace.
6. In Notion, create a new page — call it **Second Brain**. This becomes the parent of all eleven databases.
7. Open that page's `···` menu → **Connections** → add the integration you just created.
8. Copy the page's ID: the 32-character string at the end of its URL (`notion.so/Second-Brain-<32 characters>`). With or without dashes both work.

Keep the token and the page ID handy — both paths below, and the schema provisioning step, need them.

## 2. Install the rest using an agent

If you're working inside an AI coding tool that can run shell commands (Claude Code, Cursor, Copilot, Kiro, Codex, …), this repo ships a setup skill that does the remaining installation for you: **[`second-brain-setup`](.claude/skills/second-brain-setup/SKILL.md)**.

- In Claude Code, just ask it to set up the Second Brain prerequisites, or invoke the `second-brain-setup` skill by name.
- It installs Terraform for your OS, and registers the Notion MCP server — defaulting to the hosted, OAuth-based one, so there's no second token to manage (full per-client table in [`harnessing/mcp/README.md`](harnessing/mcp/README.md)).
- It will stop and ask you to do part 1 above if you haven't yet, and will prompt you for the one-time browser OAuth approval when the MCP connection first activates — that click is the only human step left on this path.
- Once it reports success, skip ahead to [part 4](#4-provision-the-schema).

What an agent should actually do with this knowledge base once connected — search-before-write, how to handle contradictions, scoping, tagging — is documented once in [`harnessing/AGENT_INSTRUCTIONS.md`](harnessing/AGENT_INSTRUCTIONS.md); every tool-specific file (`CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `.cursor/rules/`, `.kiro/steering/`) just points there.

## 3. Install the rest manually, no agent

Do this instead of part 2 if you'd rather run the commands yourself, or you're not working inside an agentic tool.

### Install Terraform

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

You do **not** need to separately install the Notion *Terraform provider* (`delize/notion`) — `terraform init` in part 4 downloads it automatically from the public Terraform Registry the first time you run it in this repo, pinned by the committed `.terraform.lock.hcl`. There's nothing to install here beyond the Terraform CLI itself.

### Connect the Notion MCP server (for agent use later — optional if you only want to provision the schema today)

Terraform doesn't use MCP at all — it talks to Notion directly via `NOTION_TOKEN`. This step is only needed once you actually want an AI agent to use the knowledge base. Register the hosted server as an HTTP-transport MCP server in your client of choice; see [`harnessing/mcp/README.md`](harnessing/mcp/README.md) for the exact command or config per client (Claude Code, VS Code, Cursor, Codex, Kiro, …) and the self-hosted, token-based alternative.

## 4. Provision the schema

```shell
git clone https://github.com/Mirkiux/second-brain.git
cd second-brain/terraform
cp terraform.tfvars.example terraform.tfvars
```

Paste the page ID from part 1 into `terraform.tfvars` as `root_page_id`.

Set the integration token as an environment variable — never put it in a `.tf` or `.tfvars` file, and `terraform.tfvars` is already gitignored so it won't get committed by accident:

```shell
# bash / Git Bash
export NOTION_TOKEN="secret_..."
```
```powershell
# PowerShell
$env:NOTION_TOKEN = "secret_..."
```

```shell
terraform init
```

This is the step that fetches the `delize/notion` provider — watch for a line like `Installing delize/notion...` in the output; that's the provider "installing" itself, automatically, with no separate action from you.

```shell
terraform validate
terraform plan
```

Read the plan before you go further — it should show exactly 11 `notion_database` resources being created, plus their properties and relations, and nothing else. Then:

```shell
terraform apply
```

Type `yes` to confirm.

## Verify, and finish the two manual steps

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
| `object_not_found` on apply | The parent page isn't shared with the integration — redo part 1, steps 6–7. |
| `unauthorized` / 401 | `NOTION_TOKEN` isn't set, is stale, or was copied with extra whitespace. |
| Property or database "already exists" / 409 | A previous `apply` partially succeeded. Run `terraform plan` to see the actual drift before touching anything by hand. |
| `terraform plan` wants to recreate a property after a rename | Renaming most property resources here forces replacement — see the schema notes in `terraform/README.md`. |

## What's next

Schema provisioned means [build order](build_order.md) step 3 is done. Step 4 — the thin REST API — is next, and it's what everything after this point (CLI, MCP server, agents) will actually talk to instead of Notion directly.
