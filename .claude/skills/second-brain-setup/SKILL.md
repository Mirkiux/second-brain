---
name: second-brain-setup
description: Install prerequisites for the Second Brain project — Terraform and the Notion MCP server — and connect Notion. Use when setting up this repo on a new machine, when Terraform or the Notion MCP server is missing, or when asked to "set up second brain," "install second brain prerequisites," or "connect Notion MCP."
---

# Second Brain — prerequisite installer

Vendor-agnostic: every step below is a plain shell command or a manual action, independent of which AI tool is running it. Detect what's missing, install or configure it, verify it, and stop and report rather than guess if a target OS/client combination has no verified path below.

## 1. Terraform

Check first:
```shell
terraform -version
```
If missing, install per OS:

- **Windows:** `winget install HashiCorp.Terraform` (fallback: `choco install terraform`, or `scoop install terraform`)
- **macOS:** `brew install terraform`
- **Linux:** add HashiCorp's apt/yum repo per [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install), or download the binary and put it on `PATH`.

Re-run `terraform -version` and confirm it reports >= 1.5.

## 2. Notion MCP server

Default to the hosted OAuth server — no token to create or manage. Full per-client table: [`harnessing/mcp/README.md`](../../../harnessing/mcp/README.md). Summary:

- Detect which client is running this skill.
- Claude Code: `claude mcp add notion --transport http https://mcp.notion.com/mcp`, then approve the browser OAuth prompt on first use.
- Other clients (VS Code, Cursor, Codex, Kiro, …): register `https://mcp.notion.com/mcp` as an HTTP-transport MCP server through that client's own MCP config — see the table for what's verified; if the client isn't listed there, check its current MCP docs rather than guessing at flag or field names.
- Verify with the client's own MCP list command — `notion` should show connected with its tools available.

If this machine needs the self-hosted, token-based server instead (air-gapped, or read-only scoping needed) — do step 3 first, then follow the "Self-hosted" section of `harnessing/mcp/README.md`.

## 3. Notion integration + page share

Needed for Terraform always; needed for the MCP server only if step 2 went the self-hosted route. Both sub-steps are manual by Notion's own design — there is no API to automate either, the same reason there's no API to mint yourself an OAuth app on most platforms:

1. Create an integration at [notion.so/my-integrations](https://www.notion.so/my-integrations) with Read/Update/Insert content capabilities, and copy its token.
2. Share the parent Notion page with that integration from the page's `···` → **Connections** menu.

Full walkthrough: root [`README.md`](../../../README.md), steps 2–3.

## 4. Report

State plainly what got installed or configured automatically, what's still pending (usually just the OAuth browser click, or the two manual steps in step 3), and point to [`terraform/README.md`](../../../terraform/README.md) for provisioning the schema next.
