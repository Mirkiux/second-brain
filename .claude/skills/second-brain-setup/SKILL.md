---
name: second-brain-setup
description: Install prerequisites for the Second Brain project — Terraform and a way for agents to reach Notion (the MCP server, or the ntn CLI where MCP servers aren't allowed) — connect Notion, and optionally provision the schema. Checks Notion itself (not just local state) for an already-provisioned schema before touching Terraform, since provisioning is a one-time, per-workspace action, not a per-machine one. Use when setting up this repo on a new machine, when Terraform, the Notion MCP server, or the Notion CLI is missing, or when asked to "set up second brain," "install second brain prerequisites," "connect Notion MCP," "set up the Notion CLI," or "provision the second brain schema."
---

@harnessing/setup.md
