# Notion MCP server — per-client setup

Two ways to connect an agent to Notion. Default to the hosted one — it's what [build order](../../build_order.md) step 2 assumes, and it sidesteps the manual integration-token step entirely.

## Hosted (default): OAuth, no token

Notion runs `https://mcp.notion.com/mcp` itself. The first connection opens a browser, you approve access, the client stores the credential and reuses it. No `NOTION_TOKEN`, no integration to create, no page to share for this path specifically — OAuth consent replaces all of that.

| Client | How to add it |
|---|---|
| Claude Code | `claude mcp add notion --transport http https://mcp.notion.com/mcp` |
| VS Code | Command Palette → **MCP: Add Server** → HTTP → paste the URL, or add to `.vscode/mcp.json` under `"servers"` with `"type": "http"`. |
| Cursor | Settings → MCP → **Add** → HTTP → paste the URL, or add to `.cursor/mcp.json` with `"url"` and `"type": "http"`. |
| Codex CLI | `codex mcp add` (interactive), or the equivalent block in Codex's config — check `codex mcp --help` for the current flag names on your installed version. |
| Kiro | Kiro's MCP settings UI, HTTP transport, same URL — check Kiro's current MCP docs for the exact field names, this project hasn't verified them directly. |

Verify with each client's own list command (`claude mcp list`, etc.) — you should see Notion's tools appear after the OAuth approval.

## Self-hosted: `NOTION_TOKEN`, for air-gapped or read-only-scoped setups

Runs `@notionhq/notion-mcp-server` locally via `npx` or Docker, authenticated with the **same internal integration token Terraform uses** — see the root [`README.md`](../../README.md) steps 2–3 for creating that integration and sharing the parent page. One token, two consumers, one manual bootstrap step instead of two.

```json
{
  "mcpServers": {
    "notionApi": {
      "command": "npx",
      "args": ["-y", "@notionhq/notion-mcp-server"],
      "env": { "NOTION_TOKEN": "ntn_..." }
    }
  }
}
```

Place that block in the client's MCP config file (`.cursor/mcp.json`, `claude_desktop_config.json`, `~/.copilot/mcp-config.json`, etc.) — the block itself is identical across clients, only the file it goes in differs.

## What can't be automated, either way

Creating the Notion integration and sharing a page with it are both manual, browser-only actions by Notion's own design — there's no API for either, the same way there's no API to mint yourself an OAuth app on most platforms. The hosted OAuth path above reduces this to "click approve in a browser once"; the self-hosted path needs the fuller integration-creation walkthrough in the root README. Neither can be scripted further than that.
