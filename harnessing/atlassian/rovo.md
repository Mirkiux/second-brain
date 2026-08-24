# rovoDev — Agent Instructions

This is the canonical reference for how an agent installs, authenticates, and uses the Atlassian Rovo Dev CLI (`acli rovodev`). It is tool-agnostic — the same instructions apply whether loaded via a Kiro skill, a Claude Code reference, or any other mechanism.

Workplace-specific values (username, API token env var name) are NOT embedded here. Retrieve them from the active Workplace entry in the knowledge base before authenticating.

## Activation

Load this skill only when:
- The user explicitly asks to start a Rovo Dev session
- The ticket-workflow is active and Path A (rovoDev available) is selected at Step 1

Do not auto-activate for general coding or file editing tasks.

## Installation & Setup

### Install

```bash
brew tap atlassian/acli
brew trust atlassian/acli
brew install acli
```

If the tap returns a 404, verify you are using `atlassian/acli` (not `atlassian-labs/tap/acli`).
If Homebrew flags the tap as untrusted, run `brew trust atlassian/acli` before installing.

### Authenticate

```bash
echo "<ATLASSIAN_API_TOKEN>" | acli login --email <username> --token-stdin
```

- Use the username and API token env var name from the Workplace entry in Notion
- **Never expose the token value in responses** — reference it by variable name only
- Authentication persists in the local profile — only needed once per machine

### Check availability (non-interactive)

Use this before attempting to start a session — it exits immediately without needing to hit the service:

```bash
# Stage 1: is the binary installed?
acli rovodev --version 2>/dev/null && echo "INSTALLED" || echo "NOT_INSTALLED"

# Stage 2 (only if INSTALLED): is the service accessible?
acli rovodev doctor 2>&1 | grep -qE "binary : not found|consent\.json : not found" && echo "UNAVAILABLE" || echo "AVAILABLE"
```

- `NOT_INSTALLED` → rovoDev cannot be used; fall back to jiraCli
- `UNAVAILABLE` → binary present but service disabled for this org; fall back to jiraCli
- `AVAILABLE` → proceed with rovoDev

## Workflows

### Start a session

```bash
cd <workspace-folder> && acli rovodev run
```

- Always navigate to the target codebase folder first
- Rovo Dev uses the working directory as its workspace context

### Code review

1. Start the session from the correct workspace folder
2. Ask Rovo to review specific files or areas — avoid open-ended scans on large repos
3. Request output in a structured format: issues found, severity, suggested fix

### Feature generation

1. Ask Rovo to read existing related files before generating anything
2. Request a Markdown outline of additions/edits before applying
3. Wait for user confirmation before applying edits
4. Instruct Rovo to use insertions over full file rewrites

### Refactor assistance

Ask Rovo to:
1. Identify the scope of the refactor (files, functions, patterns affected)
2. Summarize what will change and why
3. Apply changes incrementally, one logical unit at a time

## Communication Guidelines

When working within a Rovo Dev session:

- **Tone**: professional, concise, direct
- **Response style**: code changes first, then short bulleted rationales for structural decisions
- **Assumption boundary**: if a design requirement or API endpoint is unclear, stop and ask — do not generate placeholders or mock targets
- **Security auditing**: flag unhandled errors, missing type constraints, or visual regressions in every generated output
- **Script safety**: never suggest or execute interactive scripts or loops that could stall the compiler environment

## Gotchas

- `acli rovodev run` must be launched from the project directory
- For bulk or scripted operations, avoid interactive flags that expect terminal input
- Never expose authentication tokens in responses
