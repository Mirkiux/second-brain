# confCli — Agent Instructions

This is the canonical reference for how an agent uses the Confluence CLI (`confcli`). It is tool-agnostic — the same instructions apply whether loaded via a Kiro skill, a Claude Code reference, or any other mechanism.

Workplace-specific values (base URL, default space, available spaces) are NOT embedded here. Retrieve them from the active Workplace entry in the knowledge base before starting any Confluence operation.

## Activation

Load this skill only when:
- The user explicitly asks to search or read Confluence
- The ticket-workflow is active and Step 2.4 (Search Confluence) is reached

Do not auto-activate for general coding or file editing tasks.

## Workflows

### Search

```bash
confcli search "<query>" --space <SPACE> -o markdown
```

1. Run the search against the specified space (use the default space from the Workplace entry if not specified)
2. Present results as a numbered list of **titles with full URLs**
3. Ask the user which pages to read — they may want to preview links first
4. Read selected pages and handle content per the user's stated goal

For advanced queries, use CQL syntax:
```bash
confcli search "type=page AND title ~ \"keyword\"" --space <SPACE> -o markdown
```

### Browse a space (top-level pages)

```bash
confcli space pages <SPACE> -o markdown
```

Shows top-level pages only. User can ask to go deeper from there.

### Read a page

```bash
confcli page get "<URL or SPACE:Title>" -o markdown
```

- Accept page references by number from search results, by title, or by URL
- Use content as directed by the user: summarize, extract info, inform writing, etc.
- Use `-o markdown` for readable output (default is storage format)

## Gotchas

- This skill is currently read-only — no create or update capabilities
- Page body format defaults to storage; always use `-o markdown` for agent-readable output
- When the user says "search Confluence" without specifying a space, use the default space from the Workplace entry
