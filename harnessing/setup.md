# Second Brain — Setup Instructions

This is the canonical reference for setting up this repo on a new machine: installing Terraform, connecting Notion (MCP server or CLI), and optionally provisioning the schema. It is tool-agnostic — the same instructions apply whether loaded via a Claude Code skill, a Kiro steering file, or any other mechanism.

Vendor-agnostic: every step below is a plain shell command or a manual action, independent of which AI tool is running it. Detect what's missing, install or configure it, verify it, and stop and report rather than guess if a target OS/client combination has no verified path below.

**Scope discipline matters here more than usual.** This covers three independent things — installing Terraform, connecting Notion (MCP server or CLI), and provisioning the schema. They are not a package deal. Do only what was actually asked for.

**Provisioning is per-workspace, not per-machine.** `terraform apply` creates the 11 databases in the user's Notion workspace once — full stop. A second laptop cloning this repo has zero local Terraform state (`.gitignore` excludes it) even when the schema has existed in Notion for months. Step 2 below exists specifically to catch that case by asking Notion, not the local filesystem — get that step right and steps 3–5 correctly do nothing on a returning user's machine.

## 0. Confirm scope before doing anything

Ask, or infer from the request, which of these the user wants right now:

- Terraform installed
- Notion connected — and if so, MCP server or CLI. If the environment blocks MCP servers (some corporate laptops do, while still allowing CLI tools), or the user says as much, that decides it: CLI. Otherwise default to MCP.
- The schema provisioned (`terraform apply`)

If the request only mentions one of these — e.g. "help me connect the MCP server via OAuth" — do only that one and stop. Don't install Terraform or run `terraform apply` as a side effect of a connect-Notion-only request, and don't connect Notion as a side effect of a Terraform-only request. Mandatory manual steps (below) are only needed for whichever of the three is actually in scope.

If Terraform install and/or provisioning are in scope — including a general "set up second brain" ask that doesn't rule them out — connecting Notion (step 1) isn't optional even if the user didn't mention it explicitly: it's the only way step 2 can check whether provisioning is even still needed. Skip step 1 only when neither Terraform install nor provisioning is in scope at all.

## 1. Connect to Notion — MCP server or CLI

Do this first whenever step 0 leaves Terraform install or provisioning in scope, even if the user only asked for those — step 2 needs an active connection to check Notion itself. Which transport was decided in step 0. **Don't default to MCP if the user said MCP is blocked in this environment** — go straight to the CLI branch below instead of asking again. Skip this step entirely if it's already connected: `claude mcp list` (or equivalent) shows `notion`, or `ntn --version` succeeds with `NOTION_API_TOKEN` already set.

### MCP path

Ask once which sub-path: hosted OAuth (default — no token to manage) or self-hosted with an integration token (see root [`README.md`](../README.md) part 1 if the user doesn't have one yet — reuse an existing one rather than creating a new integration if this is a returning user's second machine). Full per-client table: [`harnessing/mcp/README.md`](mcp/README.md).

**Hosted OAuth:**
1. Run the registration command for whichever client is running this skill — e.g. in Claude Code: `claude mcp add notion --transport http https://mcp.notion.com/mcp`. For other clients, see the table; if a client isn't listed there, check its current MCP docs rather than guessing at flag or field names.
2. That command will surface an OAuth URL or open one automatically. State it plainly and tell the user to open it and approve access.
3. **Then actually wait.** Poll the client's own MCP status/list command every few seconds (e.g. `claude mcp list`) until `notion` shows connected, printing a short "waiting for OAuth approval in your browser…" note each time rather than going silent. Do not report success, and do not move on to anything else, until the connection shows as active — or the user explicitly says to stop waiting.

**Self-hosted:** write the `NOTION_TOKEN`-based config block from `harnessing/mcp/README.md` into the client's MCP config file, using the integration token from root README part 1. No OAuth wait needed on this path — it's synchronous.

### CLI path — when MCP servers aren't allowed

Full detail (install table per OS, why the token is reusable, the command-to-MCP-tool mapping): [`harnessing/cli/README.md`](cli/README.md).

1. Install `ntn` per OS — Windows: `winget install Notion.ntn`; macOS/Linux: `curl -fsSL https://ntn.dev | bash`; any OS with Node 22+/npm 10+: `npm install --global ntn`. Verify with `ntn --version`.
2. Authenticate by reusing the integration token from root README part 1 — set `NOTION_API_TOKEN` to that same value, just a different env var name than Terraform's `NOTION_TOKEN`. This is synchronous: no OAuth wait, no browser, and no extra page-sharing step since the integration is already shared with the Second Brain page. **Architectural constraint, not a preference**: don't ask the user to export this in a terminal they opened themselves, and don't try to export it yourself across this agent's own separate tool calls either — hand the export to the user's own terminal.
3. Verify: `ntn pages get <root_page_id>` should return the Second Brain page as Markdown. If the user doesn't have the page ID handy, `ntn api v1/search -d '{"query":"Second Brain","filter":{"property":"object","value":"page"}}'` finds it.

## 2. Check whether the schema is already provisioned — ask Notion, not local state

Do this right after step 1 connects, before installing Terraform or asking for provisioning credentials.

**Search Notion for the schema itself:**
- MCP: call `notion-search` for `"Second Brain"` (type: page). If found, `notion-fetch` it and check its child databases against the 11 names in [`data-model.md`](../data-model.md): Workplace, Project, Repo, Work Item, Research Question, Experiment, Note, Decision, Source, Person, Topic.
- CLI: `ntn api v1/search -d '{"query":"Second Brain","filter":{"property":"object","value":"page"}}'`. If found, `ntn pages get <id>` and check for the same 11 names among its children.

Then:
- **All 11 found** → schema already exists. Steps 3–5 are out of scope — skip to step 6.
- **No "Second Brain" page found, or found with none of the 11 databases** → genuinely first-time setup. Proceed to steps 3–5.
- **Found with some but not all 11** → don't guess. List what's there vs. missing and ask the user how to proceed.

Also check locally for context only — never use this to override the Notion check:
- `terraform -version` — is Terraform installed and >= 1.5?
- Does `terraform/.terraform/` exist? — has `terraform init` run on this machine?
- `terraform state list` — did *this machine* ever run `apply`? (Not authoritative for workspace state.)

Report findings before moving on.

## 3. Terraform

Only if step 2 found the schema not yet provisioned, and Terraform isn't already installed.

- **Windows:** `winget install HashiCorp.Terraform` (fallback: `choco install terraform`, or `scoop install terraform`)
- **macOS:** `brew install terraform`
- **Linux:** add HashiCorp's apt/yum repo per [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install), or download the binary and put it on `PATH`.

Verify: `terraform -version` should report >= 1.5.

## 4. Credentials for Terraform

Skip entirely if step 2 already found the schema provisioned, or if the user only wants Terraform installed or Notion connected.

**Architectural constraint**: don't ask the user to export credentials in a terminal they opened themselves, and don't try to export them yourself across separate tool calls. Have the user run this block themselves in one continuous terminal session:

```shell
# bash / Git Bash
export NOTION_TOKEN="..."
export TF_VAR_root_page_id="..."
cd terraform
terraform init && terraform validate && terraform plan
```
```powershell
# PowerShell
$env:NOTION_TOKEN = "..."
$env:TF_VAR_root_page_id = "..."
cd terraform
terraform init; terraform validate; terraform plan
```

Give the user this block and step back. Once they report the plan looks right, resume at step 5.

## 5. Provisioning

Only if the original request included provisioning and step 2 found it not yet applied.

**Default path**: the user runs `terraform apply` themselves in the same terminal session as step 4.

**If the user explicitly wants the agent to run `terraform apply`** — two opt-in options, each with a stated tradeoff:
- **One-shot combined command**: ask for the token and page ID in this conversation, run export + apply as a single invocation. The token enters the conversation transcript.
- **Local gitignored env script**: user creates `terraform/.env.local` with the two export lines; agent runs `source terraform/.env.local && terraform apply` as one invocation without seeing the secret.

Either way: show the plan, get explicit confirmation, then apply.

## 6. Report

State what was found already in place, what was done, what's still pending, and what was deliberately not touched because it was out of scope.
