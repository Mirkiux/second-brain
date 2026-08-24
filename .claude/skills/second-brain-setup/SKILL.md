---
name: second-brain-setup
description: Install prerequisites for the Second Brain project — Terraform and a way for agents to reach Notion (the MCP server, or the ntn CLI where MCP servers aren't allowed) — connect Notion, and optionally provision the schema. Checks Notion itself (not just local state) for an already-provisioned schema before touching Terraform, since provisioning is a one-time, per-workspace action, not a per-machine one. Use when setting up this repo on a new machine, when Terraform, the Notion MCP server, or the Notion CLI is missing, or when asked to "set up second brain," "install second brain prerequisites," "connect Notion MCP," "set up the Notion CLI," or "provision the second brain schema."
---

# Second Brain — prerequisite installer

Vendor-agnostic: every step below is a plain shell command or a manual action, independent of which AI tool is running it. Detect what's missing, install or configure it, verify it, and stop and report rather than guess if a target OS/client combination has no verified path below.

**Scope discipline matters here more than usual.** This skill covers three independent things — installing Terraform, connecting Notion (MCP server or CLI), and provisioning the schema. They are not a package deal. Do only what was actually asked for.

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

Ask once which sub-path: hosted OAuth (default — no token to manage) or self-hosted with an integration token (see root [`README.md`](../../../README.md) part 1 if the user doesn't have one yet — reuse an existing one rather than creating a new integration if this is a returning user's second machine). Full per-client table: [`harnessing/mcp/README.md`](../../../harnessing/mcp/README.md).

**Hosted OAuth:**
1. Run the registration command for whichever client is running this skill — e.g. in Claude Code: `claude mcp add notion --transport http https://mcp.notion.com/mcp`. For other clients, see the table; if a client isn't listed there, check its current MCP docs rather than guessing at flag or field names.
2. That command will surface an OAuth URL or open one automatically. State it plainly and tell the user to open it and approve access.
3. **Then actually wait.** Poll the client's own MCP status/list command every few seconds (e.g. `claude mcp list`) until `notion` shows connected, printing a short "waiting for OAuth approval in your browser…" note each time rather than going silent. Do not report success, and do not move on to anything else, until the connection shows as active — or the user explicitly says to stop waiting.

**Self-hosted:** write the `NOTION_TOKEN`-based config block from `harnessing/mcp/README.md` into the client's MCP config file, using the integration token from root README part 1. No OAuth wait needed on this path — it's synchronous.

### CLI path — when MCP servers aren't allowed

Full detail (install table per OS, why the token is reusable, the command-to-MCP-tool mapping): [`harnessing/cli/README.md`](../../../harnessing/cli/README.md).

1. Install `ntn` per OS — Windows: `winget install Notion.ntn`; macOS/Linux: `curl -fsSL https://ntn.dev | bash`; any OS with Node 22+/npm 10+: `npm install --global ntn`. Verify with `ntn --version`.
2. Authenticate by reusing the integration token from root README part 1 — set `NOTION_API_TOKEN` to that same value, just a different env var name than Terraform's `NOTION_TOKEN`. If this is a returning user's second-or-later machine, that's the *existing* integration's token (reuse it — don't create a new integration), not a fresh one. This is synchronous: no OAuth wait, no browser, and no extra page-sharing step since the integration is already shared with the Second Brain page. **Architectural constraint, not a preference** (same one that applies to Terraform credentials in step 4): don't ask the user to export this in a terminal they opened themselves, and don't try to export it yourself across this agent's own separate tool calls either — neither shares environment state with the shell that would run `ntn`. Hand the export to the user's own terminal.
3. Verify: `ntn pages get <root_page_id>` should return the Second Brain page as Markdown. If the user doesn't have the page ID handy, `ntn api v1/search -d '{"query":"Second Brain","filter":{"property":"object","value":"page"}}'` finds it — it's not a secret, just the ID from the page's URL.

## 2. Check whether the schema is already provisioned — ask Notion, not local state

This is the step that makes steps 3–5 correctly do nothing for a returning user on a new machine. Do it right after step 1 connects, before installing Terraform or asking for provisioning credentials — its result is what decides whether steps 3–5 run at all.

**Search Notion for the schema itself:**
- MCP: call `notion-search` for `"Second Brain"` (type: page). If a page with that exact title comes back, `notion-fetch` it and check its child databases against the 11 names in [`data-model.md`](../../../data-model.md): Workplace, Project, Repo, Work Item, Research Question, Experiment, Note, Decision, Source, Person, Topic.
- CLI: `ntn api v1/search -d '{"query":"Second Brain","filter":{"property":"object","value":"page"}}'`. If found, `ntn pages get <id>` on the result and check for the same 11 names among its children.

Then:
- **All 11 found** → the schema already exists in this workspace. **Steps 3, 4, and 5 are out of scope from here — don't install Terraform, don't ask for `NOTION_TOKEN`/`TF_VAR_root_page_id` for provisioning, don't run `terraform plan` or `apply`, on this or any machine, unless the user explicitly asks for something beyond using the existing knowledge base (e.g. wanting local drift-detection via `terraform import`, which is its own separate, explicit ask — never assume it's wanted).** Skip straight to step 6 to report. This is the expected outcome on a second-or-later machine.
- **No "Second Brain" page found, or found with none of the 11 databases as children** → genuinely first-time setup for this workspace. Proceed to steps 3–5 as scoped in step 0.
- **Found the page with some but not all 11, or with unexpected extras** → don't guess. Say so plainly, list what's there vs. missing, and ask the user how they want to proceed rather than assuming either a fresh `apply` or a no-op is correct.

Also check locally, for information only — **never use this to override the Notion check above, in either direction:**

- **Terraform CLI:** `terraform -version`. Success and >= 1.5 means step 3 is already done.
- **Already initialized:** check whether `terraform/.terraform/` exists. If not, `terraform init` hasn't run on this machine yet — expected on a fresh clone, since that directory is gitignored (only `.terraform.lock.hcl` itself is committed).
- **Local state, if present:** `terraform state list` from the `terraform/` directory tells you only whether *this specific machine* ran `apply` — it says nothing about the workspace as a whole. A machine can have full local state and still be behind the workspace (someone else applied more since), or have zero local state on a workspace that's fully provisioned (this machine never ran `apply`, another one did). The Notion check above is authoritative; this is context, e.g. for choosing whether `terraform plan` would show drift versus a clean import gap.

Report findings before moving on: what's already in place, and which steps below actually still need doing.

## 3. Terraform

Only if step 2 found the schema not yet provisioned in this workspace, and Terraform isn't already installed. Install per OS:

- **Windows:** `winget install HashiCorp.Terraform` (fallback: `choco install terraform`, or `scoop install terraform`)
- **macOS:** `brew install terraform`
- **Linux:** add HashiCorp's apt/yum repo per [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install), or download the binary and put it on `PATH`.

Re-run `terraform -version` and confirm it reports >= 1.5.

## 4. Credentials for Terraform — only if provisioning is in scope and step 2 found it not yet applied

Skip entirely if the user only wants Terraform installed, only wants Notion connected (MCP or CLI), or step 2 already found the schema provisioned in this workspace. Terraform needs an Internal/Access-token integration regardless of which transport step 1 used to connect Notion — walk the user through root `README.md` part 1 if they haven't done it yet (Notion doesn't expose an API for either sub-step there, so this part can't be automated further). If step 1 already connected via a self-hosted MCP server or the CLI, this is the same token — no need to collect it twice.

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

Give the user this block and step back for this specific part — don't attempt to run it. Once they report back that `plan` looks right, resume at step 5 to review it together and decide on `apply`. If the user explicitly wants the agent to run `terraform apply` itself despite this, see the two opt-in options in step 5 — both have a real tradeoff the user should choose deliberately, not have assumed on their behalf.

## 5. Provisioning — only if explicitly asked for, and only with a plan the user has seen

Only do this if the original request included provisioning, not just getting prerequisites ready, and step 2 didn't already find the schema provisioned in this workspace.

**Default path:** the user ran `init`/`validate`/`plan` themselves per step 4. Review the plan output with them — freshly, it should show exactly 11 `notion_database` resources plus their properties and relations, nothing else; if step 2 found a partial deployment, it should show only the remaining diff — then have them run `terraform apply` themselves too, in that same terminal, for the same reason step 4 wasn't delegated to the agent.

**If the user explicitly wants the agent to run `terraform apply` itself** — accept this only as a deliberate choice, and pick one:

- **One-shot combined command:** ask for the token and page ID directly in this conversation, then run the export and `terraform apply` as a single tool invocation so the variables survive for that one command. Tell the user plainly, before doing it, that this puts the token's value into the conversation itself — a real if modest and revocable exposure, not something to do by default.
- **Local, gitignored env script the agent never reads:** have the user create a small file themselves, outside the agent's view, containing the two export/`$env:` lines, saved under a path already covered by `.gitignore` (e.g. `terraform/.env.local` — confirm it's ignored before touching it). Then run `source terraform/.env.local && terraform apply` (bash) or the PowerShell dot-sourcing equivalent as a single invocation — the agent never needs to see or type the actual secret.

Either opt-in path still means: show the plan, get explicit confirmation, then apply.

## 6. Report

State plainly what was found already in place (steps 1–2, including whether the schema already existed in the workspace), what was done, what's still pending, and — just as importantly — what was deliberately **not** touched because it was out of scope for what was actually asked.
