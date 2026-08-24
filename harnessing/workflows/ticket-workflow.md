# Ticket Workflow — Agent Instructions

A structured protocol for working software tickets end-to-end: from understanding the ticket to MR approval, documentation, and knowledge base update.

This file contains the **generic, portable workflow**. Before Step 1, the agent must retrieve workplace-specific context from Notion (see "Workplace Context" below). Steps that reference project keys, GitLab groups, repo paths, or Confluence spaces use placeholders — fill them from the Workplace entry.

## Activation

Load this workflow only when explicitly requested. It is not always-on. When active, it implicitly activates:
- `harnessing/atlassian/jira.md` — for all Jira operations
- `harnessing/atlassian/confluence.md` — for Step 2.4
- `harnessing/atlassian/rovo.md` — for Path A operations

## Workplace Context — Load Before Step 1

Before starting the workflow, retrieve the active Workplace entry from Notion:

```bash
ntn api v1/search -d '{"query":"<workplace name>","filter":{"property":"object","value":"page"}}'
```

From the Workplace entry, read:
- **Jira base URL** and **default project key**
- **GitLab group URL** and **local repo root path** (e.g. `~/Proyectos/<ProjectName>/`)
- **Confluence base URL** and **default space**
- **Username** and **API token env var names** for Jira, Confluence, and rovo
- **Repo index** — list of known repos with local paths and descriptions

If the Workplace entry is missing or incomplete, stop and ask the user to provide the values before continuing.

---

Follow these steps **in order**. Pause at each APPROVAL GATE before proceeding. Never skip steps.

---

## STEP 1 — Read and Understand the Ticket

### Check rovoDev Availability

Run this check once. The result applies to all steps that would use rovoDev (Steps 1, 2.1, 2.3).

```bash
# Stage 1 — is the binary installed?
acli rovodev --version 2>/dev/null && echo "INSTALLED" || echo "NOT_INSTALLED"
```

If `NOT_INSTALLED` → use **Path B** for all rovoDev steps.

```bash
# Stage 2 — is the service accessible? (only if INSTALLED)
acli rovodev doctor 2>&1 | grep -qE "binary : not found|consent\.json : not found" && echo "UNAVAILABLE" || echo "AVAILABLE"
```

- `AVAILABLE` → use **Path A** below
- `UNAVAILABLE` → use **Path B** below

---

### Path A — rovoDev Available

```bash
acli rovodev run
# Request: "Please gather all available information about ticket <TICKET_KEY>:
# full description, acceptance criteria, all comments, linked issues,
# blocked-by/blocks relationships, and any referenced tickets that provide
# relevant context. Return a structured summary."
```

If gaps remain after reading the summary, issue targeted follow-up requests until context is sufficient.

### Path B — jiraCli Fallback

```bash
# 1. Full ticket details and comments
PAGER=cat jira issue view <TICKET_KEY> --comments 20

# 2. Linked tickets (repeat for each found)
PAGER=cat jira issue view <LINKED_TICKET_KEY> --comments 10

# 3. Related tickets by keyword
jira issue list --jql 'project = <PROJECT-KEY> AND (summary ~ "<keyword>" OR description ~ "<keyword>") AND status != Done ORDER BY updated DESC'
```

---

Present your own understanding to the user (not raw CLI output). Ask: "Does this match your understanding?"

**APPROVAL GATE**: Do not proceed until confirmed.

---

## STEP 1b — Check for Prior Work Documentation

```bash
ls ~/Proyectos/*/documentation/tickets/<TICKET_KEY>/ 2>/dev/null
```

- **Not found**: confirm "No prior documentation found. Proceeding as a fresh start." and continue.
- **Found**: read all files present (`README.md`, `lessons-learned.md`, `decisions.md`, `runbook.md`, `artifacts/`).

If found, present a structured summary:
1. What was done previously and current state
2. Repos and branches involved
3. Known gotchas or constraints
4. Open items or known issues

Use confirmed information to short-circuit Steps 2, 4, 6, and 7 where applicable.

**APPROVAL GATE**: Do not proceed until the user confirms the summary is accurate or clarifies what has changed.

---

## STEP 2 — Identify the Target Repository

Use this lookup strategy in strict order, stopping as soon as you have a confident answer:

### 2.1 — Read the Ticket

Review the Step 1 summary for explicit repo name, GitLab URL, branch name, or MR reference. If found, go to the approval gate.

If insufficient, issue a follow-up using the available path:
- **Path A**: ask rovoDev to look specifically for repo/branch/MR references in comments and linked issues
- **Path B**: `PAGER=cat jira issue view <TICKET_KEY> --comments 50`

### 2.2 — Check Known Repositories

Check the repo index from the Workplace entry. For each candidate, read its documentation file at `~/Proyectos/<ProjectName>/documentation/repos/<repo-name>/README.md`. If there's a clear match, state it and go to the approval gate.

### 2.3 — Search Similar Past Tickets

- **Path A**: ask rovoDev to find resolved/closed tickets with related keywords that reference a repo, branch, or MR
- **Path B**:
  ```bash
  jira issue list --jql 'project = <PROJECT-KEY> AND status in (Done, Resolved, Closed) AND (summary ~ "<keyword>" OR description ~ "<keyword>") ORDER BY updated DESC'
  PAGER=cat jira issue view <SIMILAR_TICKET_KEY> --comments 20
  ```

### 2.4 — Search Confluence

```bash
confcli search "<keyword>" --space <DEFAULT-SPACE> -o markdown
```

### 2.5 — Browse the SCM System

Use the SCM CLI (e.g., `glab`) to list repos in the workplace's group. GitLab group URL and credentials come from the Workplace entry.

---

State your finding and confidence source, then ask the user to confirm.

If the repo was not in the known list (found via 2.3–2.5), proceed to **Step 2b** to update the knowledge base.

**APPROVAL GATE**: Do not proceed until the target repository is confirmed.

---

## STEP 2b — Update Repo Knowledge Base (only if repo was new)

Create a new repo documentation file:
```
~/Proyectos/<ProjectName>/documentation/repos/<repo-name>/README.md
```

Structure:
```markdown
# <repo-name>

## Overview
- **SCM URL**: `<url>`
- **Local path**: `~/Proyectos/<ProjectName>/<repo-name>`
- **Description**: <what this repo does>
- **Relevant for**: <when to use this repo>

## Tooling          ← only if non-obvious tooling is required
## Access & Credentials  ← only if credentials or secrets are involved
## Deployment       ← only if there is a deployment runbook or process
```

Also update the repo index in the Workplace entry in Notion. Confirm to the user before continuing to Step 3.

---

## STEP 3 — Ensure the Repo is Cloned Locally

- Check if the repo exists at `~/Proyectos/<ProjectName>/<repo-name>/`
- If not, clone it from the SCM URL into the correct path
- Always end on `master` (or `main`) and pull latest

---

## STEP 4 — Ensure the Ticket Branch Exists

```bash
git fetch --all
git branch -r | grep <TICKET_KEY>
```

- **Branch exists remotely**: check it out locally
- **Branch does not exist**: create from latest master/main, push with `-u`

Always verify the local working branch matches the ticket key.

---

## STEP 5 — Pull Latest Changes on the Ticket Branch

```bash
git pull
```

Report the current HEAD commit and recent branch commits. Stop and ask the user how to resolve any merge conflicts before continuing.

---

## STEP 6 — Gather Additional Context

Generate a questionnaire tailored to the specific ticket. At minimum consider:

- Specific environments targeted (dev/qa/prod)?
- Dependencies on other tickets or external systems?
- Constraints (deadlines, backwards compatibility, tool versions)?
- Existing patterns or conventions in the repo to follow?
- Acceptance criteria not fully described in the ticket?
- Security, access, or IAM considerations?

Present as a numbered list. Wait for all answers.

**APPROVAL GATE**: Do not proceed until all questions are answered.

---

## STEP 7 — Create and Present the Execution Plan

Using Steps 1–6, create a detailed plan including:
- Files to be created or modified, with a brief description of each change
- Infrastructure or configuration implications
- Test strategy (unit, e2e, manual)
- Risks or edge cases
- Estimated number of steps

Ask: "Do you approve this plan, or would you like to adjust anything?"

**APPROVAL GATE**: Do not proceed until explicitly approved.

---

## STEP 8 — Iterate on the Plan

Incorporate feedback, re-present, repeat until the user gives explicit approval. Track what changed between iterations.

**APPROVAL GATE**: Final plan must be explicitly approved before execution.

---

## STEP 9 — Execute the Plan

For each step:
1. State what you are about to do
2. Do it
3. Report the result (success, output, or error)

If a step fails, stop immediately, report the full error, and ask the user how to proceed. Do not batch steps silently.

---

## STEP 10 — Create the Merge/Pull Request

Push the final branch state, then create an MR/PR with:
- Title: `[TICKET_KEY] <ticket summary>`
- Description: summary of changes, what was tested, notes for reviewer
- Source branch: ticket key branch
- Target branch: master/main

Share the URL and ask: "Please review the MR and let me know if you have any comments."

**APPROVAL GATE**: Do not proceed until the user confirms the MR or provides feedback.

---

## STEP 11 — Iterate on MR Feedback and Deployment Gate

### 11.1 — Iterate on MR Feedback

Summarize requested changes, implement on the ticket branch, push updates, inform the user. Repeat until approved.

### 11.2 — Check for Deployment Gate (CD CR or equivalent)

Read the repo's documentation file at `~/Proyectos/<ProjectName>/documentation/repos/<repo-name>/README.md`. Look for any deployment gate process (CD CR, change request, approval pipeline). If present, follow the repo-specific steps documented there. If not documented, ask the user.

### 11.3 — Verify SCM Approval Status

Always check the actual SCM approval status using the CLI before proceeding — never assume it from verbal confirmation alone.

**APPROVAL GATE**: MR must have all required SCM approvals AND any deployment gate process must have completed successfully.

---

## STEP 12 — Create Solution Documentation

Create a documentation summary including:
- **Problem**: what issue was addressed (reference the ticket)
- **Solution**: what was implemented and why this approach
- **Changes**: list of files changed with brief descriptions
- **How to verify**: steps to confirm the solution works
- **Links**: MR URL, related tickets, relevant documentation
- **Date**: today's date

Ask: "Does this documentation accurately reflect the work done?"

**APPROVAL GATE**: Documentation must be explicitly approved before publishing.

---

## STEP 13 — Save Documentation to Local Knowledge Base

### 13.1 — Save Ticket Documentation

Create:
```
~/Proyectos/<ProjectName>/documentation/tickets/<TICKET_KEY>/
```

Always create:
- **`README.md`** — problem, solution, repos, environments, outcome, date, links
- **`lessons-learned.md`** — gotchas, surprises, things to do differently next time

Create only when relevant:
- **`decisions.md`** — non-trivial decisions, alternatives considered, rationale
- **`runbook.md`** — step-by-step execution details for complex or recurring work
- **`artifacts/`** — any output files (reports, CSVs, JSONs) produced during the ticket

### 13.2 — Update Repo Knowledge Base

For each repo touched, evaluate whether anything learned should be added to its `README.md`. Consider: new tooling knowledge, gotchas, environment details, credential notes, updated deployment steps.

Confirm: "Local documentation saved to `~/Proyectos/<ProjectName>/documentation/tickets/<TICKET_KEY>/`. Repo knowledge base updated for: `<repos updated or 'no updates needed'>`."

---

## STEP 14 — Publish Documentation and Transition Ticket

Add the documentation as a comment on the ticket:
```bash
jira issue comment add <TICKET_KEY> --body "<documentation text>" --no-input
```

Transition the ticket to the appropriate "in review" status:
```bash
jira issue move <TICKET_KEY> --list   # check available statuses first
jira issue move <TICKET_KEY> "<review status>"
```

Confirm: "Documentation published to [TICKET_KEY] and ticket transitioned. The workflow is complete."

---

## General Rules

- **Never skip a step**, even if it seems unnecessary for a specific ticket
- **Always pause at APPROVAL GATEs** — explicit confirmation required before moving forward
- **If anything is unclear**, ask before acting
- **If a tool call fails**, stop and report the full error — do not attempt silent workarounds
- **Keep the user informed** at every step with clear, concise status updates
