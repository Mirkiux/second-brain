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

**Architectural constraint, not a preference: don't ask the user to export these in a terminal they opened themselves, and don't try to export them yourself across separate tool calls either.** Neither works here. A terminal the user opens is a different OS process from whatever runs this agent's shell commands — environment variables never cross that boundary. And this agent's own shell invocations don't share state with each other either; each one starts fresh, so `export` in one call and `terraform apply` in the next would fail the same way even without a human terminal involved at all. (This is specific to how Claude Code executes commands — tools that let a human type directly into the same terminal session the agent drives, like Kiro, don't have this problem. Don't assume the same pattern transfers.)

What actually works — the human runs the credential-dependent commands themselves, in one continuous terminal session, right through to `terraform plan`:

```shell
# bash / Git Bash — typed by the human, one continuous session
export NOTION_TOKEN="..."
export TF_VAR_root_page_id="..."
cd terraform
terraform init && terraform validate && terraform plan
```
```powershell
# PowerShell — typed by the human, one continuous session
$env:NOTION_TOKEN = "..."
$env:TF_VAR_root_page_id = "..."
cd terraform
terraform init; terraform validate; terraform plan
```

Give the user this block and step back for this specific part — don't attempt to run it. Once they report back that `plan` looks right, resume at step 4 to review it together and decide on `apply`. If the user explicitly wants the agent to run `terraform apply` itself despite this, see the two opt-in options in step 4 — both have a real tradeoff the user should choose deliberately, not have assumed on their behalf.

## 3. Notion MCP server — only if it's in scope

Ask once which path: hosted OAuth (default — no token to manage) or self-hosted with the token from step 2 (only offer this if step 2 already happened). Full per-client table: [`harnessing/mcp/README.md`](../../../harnessing/mcp/README.md).

**Hosted OAuth:**
1. Run the registration command for whichever client is running this skill — e.g. in Claude Code: `claude mcp add notion --transport http https://mcp.notion.com/mcp`. For other clients, see the table; if a client isn't listed there, check its current MCP docs rather than guessing at flag or field names.
2. That command will surface an OAuth URL or open one automatically. State it plainly and tell the user to open it and approve access.
3. **Then actually wait.** Poll the client's own MCP status/list command every few seconds (e.g. `claude mcp list`) until `notion` shows connected, printing a short "waiting for OAuth approval in your browser…" note each time rather than going silent. Do not report success, and do not move on to anything else, until the connection shows as active — or the user explicitly says to stop waiting.

**Self-hosted:** write the `NOTION_TOKEN`-based config block from `harnessing/mcp/README.md` into the client's MCP config file, using the token collected in step 2. No OAuth wait needed on this path — it's synchronous.

## 4. Provisioning — only if explicitly asked for, and only with a plan the user has seen

Only do this if the original request included provisioning, not just getting prerequisites ready.

**Default path:** the user ran `init`/`validate`/`plan` themselves per step 2. Review the plan output with them — it should show exactly 11 `notion_database` resources plus their properties and relations, nothing else — then have them run `terraform apply` themselves too, in that same terminal, for the same reason step 2 wasn't delegated to the agent.

**If the user explicitly wants the agent to run `terraform apply` itself** — accept this only as a deliberate choice, and pick one:

- **One-shot combined command:** ask for the token and page ID directly in this conversation, then run the export and `terraform apply` as a single tool invocation so the variables survive for that one command. Tell the user plainly, before doing it, that this puts the token's value into the conversation itself — a real if modest and revocable exposure, not something to do by default.
- **Local, gitignored env script the agent never reads:** have the user create a small file themselves, outside the agent's view, containing the two export/`$env:` lines, saved under a path already covered by `.gitignore` (e.g. `terraform/.env.local` — confirm it's ignored before touching it). Then run `source terraform/.env.local && terraform apply` (bash) or the PowerShell dot-sourcing equivalent as a single invocation — the agent never needs to see or type the actual secret.

Either opt-in path still means: show the plan, get explicit confirmation, then apply.

## 5. Report

State plainly what was done, what's still pending, and — just as importantly — what was deliberately **not** touched because it was out of scope for what was actually asked.
