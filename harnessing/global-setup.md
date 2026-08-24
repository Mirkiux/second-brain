# Global Setup — Wiring harnessing/ into Any Working Directory

By default, AI tools only load instructions from the repo they are opened in. This means `harnessing/` skills and workflows are only available when the working directory is `second-brain/` itself — not when working on `grafana-resources`, `grafana-misc-infra`, or any other repo.

This file documents how to wire `harnessing/` globally for each AI tool, so it is always available regardless of working directory. The approach: register user-level config files that point to `second-brain/harnessing/` by absolute path. A `git pull` on `second-brain` updates the canonical files and all tools pick up the changes immediately — no changes needed to any work repo.

**Prerequisite:** `second-brain` must be cloned locally. All paths below assume:
```
~/Proyectos/other/second-brain/
```
Adjust if you clone it elsewhere.

---

## Kiro — user-level steering files

Kiro loads `~/.kiro/steering/*.md` globally for every workspace. Add thin pointer files there that reference `harnessing/` by absolute path.

Create one file per skill/workflow you want always available. Use `inclusion: manual` so they only load on demand (not on every session):

```bash
# jira
cat > ~/.kiro/steering/atlassian-jira.md << 'EOF'
---
inclusion: manual
---
Read /Users/x351122/Proyectos/other/second-brain/harnessing/atlassian/jira.md
EOF

# confluence
cat > ~/.kiro/steering/atlassian-confluence.md << 'EOF'
---
inclusion: manual
---
Read /Users/x351122/Proyectos/other/second-brain/harnessing/atlassian/confluence.md
EOF

# rovo
cat > ~/.kiro/steering/atlassian-rovo.md << 'EOF'
---
inclusion: manual
---
Read /Users/x351122/Proyectos/other/second-brain/harnessing/atlassian/rovo.md
EOF

# generic ticket workflow
cat > ~/.kiro/steering/generic-ticket-workflow.md << 'EOF'
---
inclusion: manual
---
Read /Users/x351122/Proyectos/other/second-brain/harnessing/workflows/generic-ticket-workflow.md
EOF
```

For the second-brain usage instructions themselves (always-on):

```bash
cat > ~/.kiro/steering/second-brain.md << 'EOF'
---
inclusion: always
---
Read /Users/x351122/Proyectos/other/second-brain/harnessing/AGENT_INSTRUCTIONS.md
EOF
```

**Verify:** open Kiro in any repo, type `#` in chat — the steering files should appear in the list.

---

## Claude Code — global CLAUDE.md

Claude Code loads `~/.claude/CLAUDE.md` for every project. Add references to the canonical files there:

```bash
cat >> ~/.claude/CLAUDE.md << 'EOF'

## Second Brain harnessing

@/Users/x351122/Proyectos/other/second-brain/harnessing/AGENT_INSTRUCTIONS.md

## Atlassian tools and ticket workflow (load on demand only)

- Jira CLI: /Users/x351122/Proyectos/other/second-brain/harnessing/atlassian/jira.md
- Confluence CLI: /Users/x351122/Proyectos/other/second-brain/harnessing/atlassian/confluence.md
- Rovo Dev CLI: /Users/x351122/Proyectos/other/second-brain/harnessing/atlassian/rovo.md
- Generic ticket workflow: /Users/x351122/Proyectos/other/second-brain/harnessing/workflows/generic-ticket-workflow.md
EOF
```

If `~/.claude/CLAUDE.md` does not exist yet, create it:
```bash
touch ~/.claude/CLAUDE.md
```

**Note:** Claude Code's `@` syntax eagerly includes files. Keep AGENT_INSTRUCTIONS.md lightweight or use link references instead of `@` for the on-demand skills.

---

## Cursor — user-level rules

Cursor supports user-level rules in `~/.cursor/rules/`. Add `.mdc` files there:

```bash
mkdir -p ~/.cursor/rules

cat > ~/.cursor/rules/second-brain.mdc << 'EOF'
---
description: Second Brain knowledge base usage
alwaysApply: true
---
Read /Users/x351122/Proyectos/other/second-brain/harnessing/AGENT_INSTRUCTIONS.md before using the knowledge base.
EOF

cat > ~/.cursor/rules/atlassian.mdc << 'EOF'
---
description: Jira, Confluence, Rovo Dev CLI usage
alwaysApply: false
---
When asked to work with Jira, Confluence, or Rovo Dev:
- Jira: /Users/x351122/Proyectos/other/second-brain/harnessing/atlassian/jira.md
- Confluence: /Users/x351122/Proyectos/other/second-brain/harnessing/atlassian/confluence.md
- Rovo: /Users/x351122/Proyectos/other/second-brain/harnessing/atlassian/rovo.md
EOF

cat > ~/.cursor/rules/workflows.mdc << 'EOF'
---
description: Generic ticket workflow
alwaysApply: false
---
When asked to follow the ticket workflow, read:
/Users/x351122/Proyectos/other/second-brain/harnessing/workflows/generic-ticket-workflow.md
EOF
```

**Verify:** Cursor Settings → Rules — user-level rules should appear there.

---

## GitHub Copilot — personal instructions

Copilot reads `.github/copilot-instructions.md` per repo only — there is no user-level equivalent. The best workaround is to add a reference in each repo's copilot instructions file, or to rely on Kiro/Claude Code for global access.

If you want Copilot to have access in a specific repo:
```bash
mkdir -p ~/Proyectos/Grafana/grafana-resources/.github
cat > ~/Proyectos/Grafana/grafana-resources/.github/copilot-instructions.md << 'EOF'
Read /Users/x351122/Proyectos/other/second-brain/harnessing/AGENT_INSTRUCTIONS.md before using the knowledge base.
EOF
```

---

## Keeping up to date

All global config files above contain absolute paths to the canonical files in `second-brain/harnessing/`. To get the latest instructions in any tool:

```bash
cd ~/Proyectos/other/second-brain
git pull
```

No changes to global config files are needed after the initial setup — the pointers are permanent, the content they point to evolves.

---

## New machine setup

On a new machine:
1. Clone `second-brain`: `git clone https://github.com/Mirkiux/second-brain.git ~/Proyectos/other/second-brain`
2. Run the shell commands above for each tool you use
3. Set `NOTION_API_TOKEN` (see `harnessing/cli/README.md`)

This is a one-time setup per machine. The global config files are not committed anywhere — they live in your home directory and reference the cloned repo.
