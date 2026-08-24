# Notion CLI (`ntn`) — for environments where MCP servers aren't allowed

Notion's official CLI. Use this path instead of [`mcp/README.md`](../mcp/README.md) when the environment permits CLI tools but blocks MCP servers outright — some corporate laptops draw exactly that line. Same underlying Notion API either way, just a different transport, and (see below) the same credential.

## Install

| OS | Command |
|---|---|
| Windows | `winget install Notion.ntn` (x64 only) |
| macOS / Linux | `curl -fsSL https://ntn.dev \| bash` |
| Any, if you'd rather use npm (needs Node.js 22+, npm 10+) | `npm install --global ntn` |

Verify: `ntn --version`.

## Authenticate — reuse the token from root README part 1, no separate login needed

**Yes, the token is reusable.** The internal integration token you created in root [`README.md`](../../README.md) part 1 — the same one Terraform's `NOTION_TOKEN` and the self-hosted MCP path use — is a plain integration secret, not something scoped to MCP specifically. `ntn` reads it from a differently-named environment variable, `NOTION_API_TOKEN`, and once that's set it's used automatically for every command — no `ntn login`, no browser, no separate page-sharing step, because the integration was already shared with the **Second Brain** page in part 1.

```shell
# bash / Git Bash
export NOTION_API_TOKEN="ntn_..."   # same value as NOTION_TOKEN from part 1
```
```powershell
# PowerShell
$env:NOTION_API_TOKEN = "ntn_..."
```

Verify it works:

```shell
ntn pages get <root_page_id>
```

This should print the **Second Brain** page back as Markdown. `ntn doctor` also reports general CLI health if something looks wrong.

### Alternative: `ntn login` (only if you'd rather authenticate as yourself than reuse the integration token)

`ntn login` opens a browser, you approve access, and it stores workspace-scoped credentials in your OS keychain — a separate identity from the integration, with your own permissions rather than the integration's. On a remote machine or container with no browser, use `ntn login --no-browser` for a two-step flow: it prints a code and a URL to open on another device, then `ntn login poll` on the original machine redeems it once you've approved. If `NOTION_API_TOKEN` is set, it always takes precedence over a keychain login — unset it if you want `ntn login`'s credentials to actually take effect.

## Command reference for agent operations

No dedicated `search` or `query` subcommand exists for every case — those go through the generic `ntn api` escape hatch, which wraps the raw Notion REST API (`Notion-Version` header and auth handled for you).

| Operation | MCP tool equivalent | `ntn` command |
|---|---|---|
| Search the workspace | `notion-search` | `ntn api v1/search -d '{"query":"..."}'` |
| Read a page | `notion-fetch` | `ntn pages get <page-id>` — returns Markdown |
| Map a database to its data source(s) | (implicit) | `ntn datasources resolve <database-id>` |
| Query a database | `notion-query-data-sources` | `ntn datasources query <data-source-id> -d '{"filter": {...}}'` |
| Create a plain sub-page | `notion-create-pages` | `ntn pages create --parent page:<parent-id> --content '## Title\n\nBody...'` |
| Create a row in one of the 11 databases | `notion-create-pages` | `ntn api v1/pages -d '{"parent":{"data_source_id":"<id>"},"properties":{"Name":{"title":[{"text":{"content":"..."}}]}}}'` — resolve the data source ID first |
| Update a page's properties | `notion-update-page` | `ntn api v1/pages/<page-id> -d '{"properties": {...}}'` |

`ntn api` infers GET vs POST from whether a body is given; force a method with `-X PATCH`/`-X DELETE`. For anything not covered above: `ntn api ls` lists every endpoint, `ntn api <path> --help` shows its supported methods, and `ntn api <path> --spec` shows its request/response schema — check these before guessing at a field name.

## What can't be automated, either way

Same root cause as the MCP path: creating the integration and sharing the **Second Brain** page with it (root README part 1) are manual, browser-only steps by Notion's own design — no API exists for either. The CLI path has one less browser step than hosted MCP, though: reusing the integration token means no OAuth consent screen at all.
