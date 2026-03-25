# Personal Skills Plugin — Design Spec

**Date:** 2026-03-25
**Author:** Corey Fitz + Claude
**Status:** Draft

---

## Overview

A standalone Claude plugin containing personal productivity skills that consume Sidekick's personal memory and external MCP connectors (Asana, Slack, Google Calendar). Scoped to Cowork only. No code, no build step — just markdown skills and a config file.

**Goals:**
- Morning briefing that aggregates calendar, tasks, Slack activity, enriched with personal context from Sidekick memory
- Meeting preparation with attendee resolution against Sidekick's relationships space
- Richer context loading beyond Sidekick's orient hook

**Non-goals:**
- Replacing Sidekick (it stays the memory layer — this plugin is a consumer)
- Writing an MCP server (file-based memory access is sufficient for 3 skills)
- Claude Code support (Google Calendar requires Cowork's MCP connectors)
- Task sync / write-back to Asana (Asana is read-only source of truth)

**Relationship to Sidekick:**
- Sidekick = portable, cross-device personal memory store (identity, relationships, decisions, patterns, knowledge)
- This plugin = productivity skills that read from Sidekick and combine it with external tools
- Claude's auto memory = project-scoped learnings (handled natively, not by either plugin)

---

## Architecture

```
corey-skills/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest (Cowork only)
├── config.json               # Personal config (Slack channels, user IDs, memory path)
├── skills/
│   ├── context-loader/
│   │   └── SKILL.md
│   ├── daily-brief/
│   │   └── SKILL.md
│   └── meeting-prep/
│       └── SKILL.md
└── README.md
```

### How it fits together

```
┌──────────────────────────────────────────────────┐
│  Cowork Session                                  │
│                                                  │
│  ┌─────────────┐  ┌──────────┐                   │
│  │ daily-brief │  │ meeting- │                   │
│  │ skill       │  │ prep     │                   │
│  └──────┬──────┘  └────┬─────┘                   │
│         │              │                         │
│         ▼              ▼                         │
│  ┌─────────────────────────────┐                 │
│  │     context-loader          │                 │
│  │  (reads Sidekick memory)    │                 │
│  └──────────────┬──────────────┘                 │
│                 │                                │
│     ┌───────────┼───────────┐                    │
│     ▼           ▼           ▼                    │
│  ┌────────┐ ┌────────┐ ┌──────────┐             │
│  │ Asana  │ │ Slack  │ │ Calendar │             │
│  │ MCP    │ │ MCP    │ │ MCP      │             │
│  └────────┘ └────────┘ └──────────┘             │
└──────────────────────────────────────────────────┘
                 │
                 ▼
    ┌─────────────────────────┐
    │  Sidekick Memory        │
    │  (read via file path)   │
    │                         │
    │  index.md               │
    │  identity/              │
    │  relationships/         │
    │  projects/              │
    │  decisions/             │
    │  patterns/              │
    │  knowledge/             │
    └─────────────────────────┘
```

---

## Personal Config

`config.json` at the plugin root stores non-secret personal configuration:

```json
{
  "sidekick_memory_path": "~/.claude/.sidekick/memory/",
  "user_email": "corey@tigerdata.com",
  "user_timezone": "America/New_York",
  "slack_user_id": "UXXXXXXXXXX",
  "slack_channels": [
    "#content-flywheel",
    "#marketing-leadership",
    "#marketing-private",
    "#marketing-skills-private",
    "#marketing",
    "#marketing-web",
    "#leads-management-team",
    "#leads-marketing",
    "#marketing-datatalks",
    "#marketing-abl",
    "external-freelance-writers",
    "#marketing-tools-feedback",
    "#sales-team",
    "#revops-and-marketing-ops",
    "#seo-geo-updates",
    "#marketing-shared-services",
    "#gtm-weekly-leads",
    "#discussion-one-tiger"
  ]
}
```

This file is committed to the repo (private repo, no secrets). Credentials for external services are handled by the Cowork MCP connectors themselves.

---

## Skills

### context-loader

**Trigger:** Runs automatically at the start of daily-brief and meeting-prep. Also invokable manually via `/context-loader`.

**What it does:**

1. Reads `config.json` to get the Sidekick memory path
2. Reads `index.md` for the high-level summary (identity, active projects, key people, preferences)
3. Reads all files in `identity/` for full profile context
4. Reads all files in `relationships/` to build a people lookup table (name → role, context, relationship)
5. Holds this context in the conversation for the calling skill to use

**What it does NOT do:**
- Write to Sidekick memory (daily-brief and meeting-prep can propose saves, but context-loader is read-only)
- Replace orient — orient is Sidekick's session hook, context-loader is this plugin's way of pulling richer context than just the index

**Graceful degradation:** If the memory path doesn't exist or is empty, warn the user and continue. The calling skill still works — it just won't have personal context enrichment.

### daily-brief

**Trigger:** `/daily-brief`, "brief me", "what's on my plate", "start my day"

**MCP dependencies:** Slack, Google Calendar, Asana. All optional — only context-loader is required.

**What it does:**

1. **Load context** — runs context-loader to get identity, relationships, preferences
2. **Pull calendar** — today's events from Google Calendar, filtered to real meetings (skip focus time, personal blocks, working locations)
3. **Pull Asana tasks** — all tasks assigned to user across the workspace, grouped into: overdue, due today, due this week
4. **Scan Slack (two passes):**
   - **Pass 1 — Configured channels:** reads the 18 configured channels for messages since last session. Filters for: direct @mentions, unanswered questions directed at user, action items from leadership channels. Resolves names against the relationships table from context-loader.
   - **Pass 2 — Workspace-wide @mentions:** searches across all channels (public and private) for @mentions of the user, deduplicated against Pass 1. Catches mentions in channels not in the configured list.
5. **Deliver briefing** — single scannable output:
   - In-progress / focus items (from Asana)
   - Unanswered Slack questions (who asked, when, which channel)
   - Today's schedule (meetings with attendee context from Sidekick)
   - Due today (Asana tasks)
   - Due this week
   - Overdue
6. **Propose memory saves** — if new people or projects surfaced in Slack that aren't in Sidekick memory, propose them: "I noticed 2 new people. Want me to save them?" User confirms before any writes.
7. **Offer follow-up** — "Want me to prep notes for today's meetings?" → hands off to meeting-prep

**Graceful degradation:** If any MCP connector is unavailable, skip that section and note what was skipped. The briefing still delivers whatever's available.

### meeting-prep

**Trigger:** `/meeting-prep`, "prep my meetings", "meeting notes"

**MCP dependencies:** Google Calendar, Slack (for profile lookups). Context-loader required.

**What it does:**

1. **Load context** — runs context-loader
2. **Pull calendar** — events for target date (default: today), filtered to real meetings
3. **Present meeting list** — shows each meeting with time and attendees. Asks which ones to prep (default: all)
4. **Resolve attendees** — for each attendee in selected meetings:
   - Search Sidekick relationships by name and email
   - If found: pull role, relationship context, recent notes
   - If not found: pull Slack profile (role, timezone, status) as fallback
5. **Enrich with project context** — if a meeting name matches a known project in Sidekick's projects space, pull that context
6. **Deliver prep docs** — for each meeting: who's in the room, what you know about them, relevant project context, suggested talking points
7. **Propose relationship saves** — for attendees not in Sidekick memory who seem worth remembering (recurring meeting participants, leadership, cross-functional contacts), offer to save them. User confirms.

**Graceful degradation:** If Google Calendar is unavailable, ask the user to paste meeting details manually. Attendee resolution and context enrichment still work.

**Config values needed (from `config.json`):**
- `user_email` — to identify self in attendee lists
- `user_timezone` — for calendar queries

---

## Design Decisions

1. **Standalone plugin, not inside Sidekick.** Sidekick is the portable memory layer; this is the Cowork-only consumer. Different scopes, different platforms, different release cadences.
2. **File-based memory access, not MCP server.** Three skills don't justify a Node.js server. config.json stores the memory path. If more consumers emerge later, wrap the file layer in an MCP API.
3. **Cowork only.** Google Calendar MCP is only available in Cowork. Claude Code support can be added if/when those connectors become available there.
4. **Asana is read-only.** No task sync or write-back. Asana is the source of truth. Daily-brief reads from it but doesn't modify anything.
5. **Explicit memory path in config.json.** Sidekick's orient hook doesn't reliably fire in Cowork. Rather than replicating the detection cascade, context-loader reads from a configured path.
6. **Approval-gated memory writes.** Both daily-brief and meeting-prep can propose saves to Sidekick memory for new people/projects. Nothing is saved without user confirmation.
7. **Two-pass Slack scan.** Configured channels get a full activity scan. Workspace-wide search catches @mentions outside those channels. Deduplicated to avoid noise.

---

## What This Doesn't Do

- **No task sync** — Asana is read-only. No bidirectional sync.
- **No content workflows** — weekly roundups, LinkedIn articles, design requests stay in marketing-skills.
- **No MCP server** — files are the access layer. If more consumers need Sidekick data, add the MCP server then.
- **No Claude Code support** — Cowork only for now.
- **No meeting notes storage** — meeting-prep generates prep docs but doesn't create persistent meeting notes files. That could be added later.

---

## Future Additions

- **weekly-review** — end-of-week summary of completed tasks, meetings attended, decisions made
- **Claude Code support** — if Google Calendar becomes available outside Cowork
- **Meeting notes** — persistent scratch space in Sidekick's knowledge space for during/after meetings
- **MCP server** — if Sidekick needs a stable API for multiple consumers
