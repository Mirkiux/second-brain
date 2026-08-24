# Global Setup — Wiring harnessing/ into Any Working Directory

By default, AI tools only load instructions from the repo they are opened in. This means `harnessing/` skills and workflows are only available when the working directory is `second-brain/` itself — not when working on `grafana-resources`, `grafana-misc-infra`, or any other repo.

This file documents how to wire `harnessing/` globally for each AI tool so it is always available regardless of working directory. The approach: create a symlink from `~/.kiro/harnessing` into `second-brain/harnessing/`, then register user-level config files that reference via the symlink. A `git pull` on `second-brain` updates the canonical files and all tools pick them up immediately — no changes needed to any work repo.

**Prerequisite:** `second-brain` must be cloned locally. All paths below assume:
```
~/Proyectos/other/second-brain/
```
Adjust if you clone it elsewhere.

---

## Step 1 — Create the symlink (required for Kiro)

Kiro's file access is sandboxed to the current workspace and `~/.kiro/`. Absolute paths outside the workspace don't work. The solution is a symlink:

```bash
ln -s ~/Proyectos/other/second-brain/harnessing ~/.kiro/harnessing
```

Verify:
```bash
ls ~/.kiro/harnessing/AGENT_INSTRUCTIONS.md
```

This only needs to be done once per machine. After that, `git pull` on `second-brain` keeps the content current through the symlink automatically.

---

## Step 2 — Kiro: user-level steering files

Create global steering files in `~/.kiro/steering/` that reference via the symlink. Use `inclusion: manual` so they only load on demand:

```bash
# Always-on: second-brain knowledge base usage
cat > ~/.kiro/steering/second-brain.md << 'EOF'
---
inclusion: always
---
Read ~/.kiro/harnessing/AGENT_INSTRUCTIONS.md before using the knowledge base — that file is the single source of truth for how to read from and write to it.
EOF

# On demand: Jira CLI
cat > ~/.kiro/steering/atlassian-jira.md << 'EOF'
---
inclusion: manual
---
Read ~/.kiro/harnessing/atlassian/jira.md
EOF

# On demand: Confluence CLI
cat > ~/.kiro/steering/atlassian-confluence.md << 'EOF'
---
inclusion: manual
---
Read ~/.kiro/harnessing/atlassian/confluence.md
EOF

# On demand: Rovo Dev CLI
cat > ~/.kiro/steering/atlassian-rovo.md << 'EOF'
---
inclusion: manual
---
Read ~/.kiro/harnessing/atlassian/rovo.md
EOF

# On demand: Generic ticket workflow
cat > ~/.kiro/steering/generic-ticket-workflow.md << 'EOF'
---
inclusion: manual
---
Read ~/.kiro/harnessing/workflows/generic-ticket-workflow.md
EOF
```

**Verify:** open Kiro in any repo, type `#` in chat — the steering files should appear in the list.

---

## Step 3 — Claude Code: global CLAUDE.md

Claude Code loads `~/.claude/CLAUDE.md` for every project. Add references there:

```bash
cat >> ~/.claude/CLAUDE.md << 'EOF'

## Second Brain harnessing

Read ~/.kiro/harnessing/AGENT_INSTRUCTIONS.md before using the knowledge base.

## Atlassian tools and ticket workflow (load on demand only)

- Jira CLI: ~/.kiro/harnessing/atlassian/jira.md
- Confluence CLI: ~/.kiro/harnessing/atlassian/confluence.md
- Rovo Dev CLI: ~/.kiro/harnessing/atlassian/rovo.md
- Generic ticket workflow: ~/.kiro/harnessing/workflows/generic-ticket-workflow.md
EOF
```

If `~/.claude/CLAUDE.md` does not exist yet: `touch ~/.claude/CLAUDE.md`

**Note:** Claude Code's `@` syntax eagerly includes files. For on-demand skills, use plain text references rather than `@` so they don't load on every session.

---

## Step 4 — Cursor: user-level rules

Cursor supports user-level rules in `~/.cursor/rules/`:

```bash
mkdir -p ~/.cursor/rules

cat > ~/.cursor/rules/second-brain.mdc << 'EOF'
---
description: Second Brain knowledge base usage
alwaysApply: true
---
Read ~/.kiro/harnessing/AGENT_INSTRUCTIONS.md before using the knowledge base.
EOF

cat > ~/.cursor/rules/atlassian.mdc << 'EOF'
---
description: Jira, Confluence, Rovo Dev CLI usage
alwaysApply: false
---
When asked to work with Jira, Confluence, or Rovo Dev:
- Jira: ~/.kiro/harnessing/atlassian/jira.md
- Confluence: ~/.kiro/harnessing/atlassian/confluence.md
- Rovo: ~/.kiro/harnessing/atlassian/rovo.md
EOF

cat > ~/.cursor/rules/workflows.mdc << 'EOF'
---
description: Generic ticket workflow
alwaysApply: false
---
When asked to follow the ticket workflow, read:
~/.kiro/harnessing/workflows/generic-ticket-workflow.md
EOF
```

**Verify:** Cursor Settings → Rules — user-level rules should appear there.

---

## Step 5 — GitHub Copilot

Copilot reads `.github/copilot-instructions.md` per repo only — there is no user-level equivalent. For repos where you want Copilot to have access:

```bash
mkdir -p <repo>/.github
cat > <repo>/.github/copilot-instructions.md << 'EOF'
Read ~/.kiro/harnessing/AGENT_INSTRUCTIONS.md before using the knowledge base.
EOF
```

---

## Keeping up to date

All global config files reference via `~/.kiro/harnessing/` which is a symlink to `second-brain/harnessing/`. To get the latest instructions in any tool:

```bash
cd ~/Proyectos/other/second-brain
git pull
```

No changes to global config files are needed after the initial setup.

---

## New machine setup

On a new machine:
1. Clone `second-brain`: `git clone https://github.com/Mirkiux/second-brain.git ~/Proyectos/other/second-brain`
2. Create the symlink: `ln -s ~/Proyectos/other/second-brain/harnessing ~/.kiro/harnessing`
3. Run the shell commands in Steps 2–4 above for each tool you use
4. Set `NOTION_API_TOKEN` (see `harnessing/cli/README.md`)

This is a one-time setup per machine. The symlink and global config files live in your home directory — not committed to any repo.
