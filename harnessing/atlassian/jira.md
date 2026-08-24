# jiraCli — Agent Instructions

This is the canonical reference for how an agent uses the Jira CLI (`jira`). It is tool-agnostic — the same instructions apply whether loaded via a Kiro skill, a Claude Code `CLAUDE.md` reference, a Cursor rule, or any other mechanism.

Workplace-specific values (base URL, project keys, username, credential env var name) are NOT embedded here. Retrieve them from the active Workplace entry in the knowledge base before starting any Jira operation.

## Installation & Auth

- CLI: `jira` (go-jira or ankitpokhrel/jira-cli — verify with `jira version`)
- Auth: API token via environment variable. The variable name is workplace-specific — read it from the Workplace entry in Notion.
- Config file: `~/.config/.jira/.config.yml`

## Activation

Load this skill only when:
- The user explicitly asks to search, view, create, or update a Jira issue
- The ticket-workflow is active (it activates this skill implicitly at Step 1)

Do not auto-activate for general coding or file editing tasks.

## Workflows

### Search issues

```bash
jira issue list --jql "<JQL query>" --plain
```

1. Build a JQL query from the user's request
2. Present results as a numbered list: issue key, summary, status, assignee
3. Ask if the user wants to view a specific issue in detail

Common JQL patterns:
- My open issues: `assignee = currentUser() AND resolution = Unresolved ORDER BY updated DESC`
- Issues in a project: `project = <PROJECT-KEY> AND status != Done ORDER BY created DESC`
- Search by text: `summary ~ "<keyword>" OR description ~ "<keyword>"`
- Issues in a sprint: `sprint in openSprints() AND project = <PROJECT-KEY>`

### Get issue details

```bash
PAGER=cat jira issue view <ISSUE-KEY>
```

- Accept issue references by key (e.g., `PROJ-123`) or by number from search results
- Shows summary, description, status, assignee, reporter, priority, labels, and comments
- **Always prefix with `PAGER=cat`** — without it, the CLI opens `less` and blocks execution waiting for the user to press `q`

### Create an issue

```bash
jira issue create --project <PROJECT-KEY> --summary "<summary>" --type Task --no-input
```

- Prompt for required fields if not provided: project key, summary, issue type
- Optional flags: `--description "<text>"`, `--assignee <email>`, `--priority High`, `--label <label>`
- Common issue types: `Task`, `Bug`, `Story`, `Epic`, `Subtask`

### Add a comment

```bash
jira issue comment add <ISSUE-KEY> --body "<comment text>" --no-input
```

### Update an issue

Update summary or description:
```bash
jira issue edit <ISSUE-KEY> --summary "<new summary>" --no-input
```

Change status (transition):
```bash
jira issue move <ISSUE-KEY> "<Status Name>"
```

List available transitions first if unsure:
```bash
jira issue move <ISSUE-KEY> --list
```

Assign to someone:
```bash
jira issue assign <ISSUE-KEY> <email>
```

### List projects

```bash
jira project list --plain
```

## Gotchas

- **Always use `PAGER=cat` with `jira issue view`** — the pager blocks non-interactive execution
- `--plain` is not available on all subcommands — if it errors with "unknown flag: --plain", remove it and use `PAGER=cat` instead
- Use `--no-input` on create/edit commands to avoid interactive prompts
- Never expose the API token value in responses — reference it by variable name only
- For bulk operations, chain commands using shell loops
