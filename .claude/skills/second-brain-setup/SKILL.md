---
name: second-brain-setup
description: Install prerequisites for the Second Brain project — Terraform and the Notion MCP server — connect Notion, and optionally provision the schema. Use when setting up this repo on a new machine, when Terraform or the Notion MCP server is missing, or when asked to "set up second brain," "install second brain prerequisites," "connect Notion MCP," or "provision the second brain schema."
---

# Second Brain — prerequisite installer

Vendor-agnostic: every step below is a plain shell command or a manual action, independent of which AI tool is running it. Detect what's missing, install or configure it, verify it, and stop and report rather than guess if a target OS/client combination has no verified path below.

**Scope discipline matters here more than usual.** This skill covers three independent things — installing Terraform, connecting the Notion MCP server, and provisioning the schema. They are not a package deal. Do only what was actually asked for.

## 0. Confirm scope before doing anything

Ask, or infer from the request, which of these the user wants right now:

- Terraform installed
- The Notion MCP server connected
- The schema provisioned (`terraform apply`)

If the request only mentions one of these — e.g. "help me connect the MCP server via OAuth" — do only that one and stop. Don't install Terraform or run `terraform apply` as a side effect of an MCP-only request, and don't connect the MCP server as a side effect of a Terraform-only request. Mandatory manual steps (below) are only needed for whichever of the three is actually in scope.

## 1. Terraform

Only if Terraform is in scope. Check first:
```shell
terraform -version
```
If missing, install per OS:

- **Windows:** `winget install HashiCorp.Terraform` (fallback: `choco install terraform`, or `scoop install terraform`)
- **macOS:** `brew install terraform`
- **Linux:** add HashiCorp's apt/yum repo per [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install), or download the binary and put it on `PATH`.

Re-run `terraform -version` and confirm it reports >= 1.5.

## 2. Credentials for Terraform — only if provisioning is in scope

Skip entirely if the user only wants Terraform installed, or only wants the MCP server connected. Terraform needs an Internal/Access-token integration regardless of what path step 3 takes for MCP — walk the user through root `README.md` part 1 if they haven't done it yet (Notion doesn't expose an API for either sub-step there, so this part can't be automated further).

Once the user has the token and the page ID, have them set both as environment variables in **this terminal session** — never write either to a file:

```shell
# bash / Git Bash
export NOTION_TOKEN="..."
export TF_VAR_root_page_id="..."
```
```powershell
# PowerShell
$env:NOTION_TOKEN = "..."
$env:TF_VAR_root_page_id = "..."
```

Confirm both are actually set before moving on (e.g. check the variables are non-empty) — without ever echoing the token's value back into the terminal or a log.

## 3. Notion MCP server — only if it's in scope

Ask once which path: hosted OAuth (default — no token to manage) or self-hosted with the token from step 2 (only offer this if step 2 already happened). Full per-client table: [`harnessing/mcp/README.md`](../../../harnessing/mcp/README.md).

**Hosted OAuth:**
1. Run the registration command for whichever client is running this skill — e.g. in Claude Code: `claude mcp add notion --transport http https://mcp.notion.com/mcp`. For other clients, see the table; if a client isn't listed there, check its current MCP docs rather than guessing at flag or field names.
2. That command will surface an OAuth URL or open one automatically. State it plainly and tell the user to open it and approve access.
3. **Then actually wait.** Poll the client's own MCP status/list command every few seconds (e.g. `claude mcp list`) until `notion` shows connected, printing a short "waiting for OAuth approval in your browser…" note each time rather than going silent. Do not report success, and do not move on to anything else, until the connection shows as active — or the user explicitly says to stop waiting.

**Self-hosted:** write the `NOTION_TOKEN`-based config block from `harnessing/mcp/README.md` into the client's MCP config file, using the token collected in step 2. No OAuth wait needed on this path — it's synchronous.

## 4. Provisioning — only if explicitly asked for, and only with a plan the user has seen

Only do this if the original request included provisioning, not just getting prerequisites ready.

```shell
cd terraform
terraform init
terraform validate
terraform plan
```

Show the plan to the user and get explicit confirmation before running `terraform apply` — this creates real databases in their live Notion workspace, so it never runs silently as a continuation of some other request.

```shell
terraform apply
```

## 5. Report

State plainly what was done, what's still pending, and — just as importantly — what was deliberately **not** touched because it was out of scope for what was actually asked.
