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

### Plugin Manifest

`.claude-plugin/plugin.json`:

```json
{
  "name": "corey-skills",
  "version": "0.1.0",
  "description": "Personal productivity skills — daily briefing, meeting prep, and context loading from Sidekick memory",
  "platforms": ["cowork"],
  "author": {
    "name": "cfitz-ops"
  }
}
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
│    ┌────┴──────────────┴────┐                    │
│    │                        │                    │
│    ▼                        ▼                    │
│  ┌──────────────┐  ┌─────────────────────────┐   │
│  │ context-     │  │ MCP Connectors          │   │
│  │ loader       │  │ ┌───────┐ ┌───────────┐ │   │
│  │ (Sidekick    │  │ │ Asana │ │ Google    │ │   │
│  │  memory)     │  │ │       │ │ Calendar  │ │   │
│  └──────┬───────┘  │ ├───────┤ ├───────────┤ │   │
│         │          │ │ Slack │ │           │ │   │
│         │          │ └───────┘ └───────────┘ │   │
│         │          └─────────────────────────┘   │
└─────────┼────────────────────────────────────────┘
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
  "config_version": 1,
  "sidekick_memory_path": "~/.claude/.sidekick/memory/",
  "user_email": "corey@tigerdata.com",
  "user_timezone": "America/New_York",
  "slack_user_id": "UXXXXXXXXXX",
  "slack_channels": [
    { "name": "#content-flywheel", "id": "CXXXXXXXXX1" },
    { "name": "#marketing-leadership", "id": "CXXXXXXXXX2" },
    { "name": "#marketing-private", "id": "CXXXXXXXXX3" },
    { "name": "#marketing-skills-private", "id": "CXXXXXXXXX4" },
    { "name": "#marketing", "id": "CXXXXXXXXX5" },
    { "name": "#marketing-web", "id": "CXXXXXXXXX6" },
    { "name": "#leads-management-team", "id": "CXXXXXXXXX7" },
    { "name": "#leads-marketing", "id": "CXXXXXXXXX8" },
    { "name": "#marketing-datatalks", "id": "CXXXXXXXXX9" },
    { "name": "#marketing-abl", "id": "CXXXXXXXXXA" },
    { "name": "external-freelance-writers", "id": "CXXXXXXXXXB" },
    { "name": "#marketing-tools-feedback", "id": "CXXXXXXXXXC" },
    { "name": "#sales-team", "id": "CXXXXXXXXXD" },
    { "name": "#revops-and-marketing-ops", "id": "CXXXXXXXXXE" },
    { "name": "#seo-geo-updates", "id": "CXXXXXXXXXF" },
    { "name": "#marketing-shared-services", "id": "CXXXXXXXXXG" },
    { "name": "#gtm-weekly-leads", "id": "CXXXXXXXXXH" },
    { "name": "#discussion-one-tiger", "id": "CXXXXXXXXXI" }
  ]
}
```

Channel IDs are required — the Slack MCP tools operate on IDs, not names. Names are stored alongside for human readability. Channel IDs can be found via `slack_search_channels` or from the Slack UI (channel details → bottom of the About tab).

This file is committed to the repo (private repo, no secrets). Credentials for external services are handled by the Cowork MCP connectors themselves.

---

## Skills

### Context Loading Pattern

Context-loader logic is **inlined into each skill as Step 0**, not invoked as a separate slash command. This matches Sidekick's proven pattern (e.g., orient and recall both inline their path resolution). Context-loader also exists as a standalone skill for manual use.

The shared Step 0 logic:

1. Read `config.json` from the plugin root to get `sidekick_memory_path`
2. Read `{sidekick_memory_path}/index.md` for the high-level summary
3. Read all files in `{sidekick_memory_path}/identity/` for full profile
4. Read all files in `{sidekick_memory_path}/relationships/` to build a people lookup table
5. If the memory path doesn't exist or is empty, warn the user and continue without personal context

### context-loader

**Trigger:** `/context-loader`, "load my context"

**What it does:** Runs the shared Step 0 logic above as a standalone skill. Useful for manual context loading or debugging. Confirms what it loaded with a brief summary.

**What it does NOT do:**
- Write to Sidekick memory (read-only)
- Replace orient — orient is Sidekick's session hook, context-loader is this plugin's way of pulling richer context

### daily-brief

**Trigger:** `/daily-brief`, "brief me", "what's on my plate", "start my day"

**MCP dependencies:** Slack, Google Calendar, Asana. All optional — only context loading is required.

**What it does:**

1. **Step 0 — Load context** (inlined context-loader logic)
2. **Pull calendar** — today's events from Google Calendar via `gcal_list_events`, filtered to real meetings using these heuristics:
   - **Skip** events where summary contains "Focus Time", "OOO", "Working Location", "Lunch", or "Block"
   - **Skip** events with 0 attendees and `transparency: "transparent"`
   - **Skip** cancelled events (`status: "cancelled"`)
   - **Keep** everything else
3. **Pull Asana tasks** — call `get_my_tasks` to retrieve all incomplete tasks assigned to user. Group client-side into:
   - **Overdue** — `due_on` before today
   - **Due today** — `due_on` is today
   - **Due this week** — `due_on` within the next 7 days
   - Do NOT use `search_tasks_preview` — it renders a UI preview and does not return structured data suitable for reformatting.
4. **Scan Slack (two passes):**
   - **Pass 1 — Configured channels:** for each channel ID in `config.json`, call `slack_read_channel` with `oldest` set to 12 hours ago (UTC timestamp). Filter for: direct @mentions, unanswered questions directed at user, action items from leadership channels. Resolve names against the relationships table from Step 0.
   - **Pass 2 — Workspace-wide @mentions:** call `slack_search_public_and_private` with query `<@{slack_user_id}>` and date filter for last 12 hours. Deduplicate against Pass 1 results. Surface any mentions from channels not in the configured list.
5. **Deliver briefing** — single scannable output:
   - In-progress / focus items (from Asana)
   - Unanswered Slack questions (who asked, when, which channel)
   - Today's schedule (meetings with attendee context from Sidekick)
   - Due today (Asana tasks)
   - Due this week
   - Overdue
6. **Propose memory saves** — if new people or projects surfaced that aren't in Sidekick memory, propose them: "I noticed 2 new people. Want me to save them?" User confirms before any writes. Writes go directly to `{sidekick_memory_path}/relationships/` or `{sidekick_memory_path}/projects/` using Sidekick's YAML frontmatter format (see Memory Write Format below).
7. **Offer follow-up** — "Want me to prep notes for today's meetings?" → hands off to meeting-prep

**Graceful degradation:** If any MCP connector is unavailable, skip that section and note what was skipped. The briefing still delivers whatever's available.

### meeting-prep

**Trigger:** `/meeting-prep`, "prep my meetings", "meeting notes"

**MCP dependencies:** Google Calendar, Slack (for profile lookups). Context loading required.

**What it does:**

1. **Step 0 — Load context** (inlined context-loader logic)
2. **Pull calendar** — events for target date (default: today) via `gcal_list_events`, filtered using the same heuristics as daily-brief
3. **Present meeting list** — shows each meeting with time and attendees. Asks which ones to prep (default: all)
4. **Resolve attendees** — for each attendee in selected meetings:
   - Identify self using the `self: true` flag on the authenticated user's attendee entry (no email matching needed)
   - Search Sidekick relationships by name and email
   - If found: pull role, relationship context, recent notes
   - If not found: call `slack_search_users` by name/email, then `slack_read_user_profile` for role, timezone, status
5. **Enrich with project context** — if a meeting name matches a known project in Sidekick's projects space, pull that context
6. **Deliver prep docs** — for each meeting: who's in the room, what you know about them, relevant project context, suggested talking points
7. **Propose relationship saves** — for attendees not in Sidekick memory who seem worth remembering (recurring meeting participants, leadership, cross-functional contacts), offer to save them. User confirms. Writes use the Memory Write Format below.

**Graceful degradation:** If Google Calendar is unavailable, ask the user to paste meeting details manually. Attendee resolution and context enrichment still work.

---

## Memory Write Format

When daily-brief or meeting-prep proposes saving new people or projects to Sidekick memory, the files are written directly to the configured `sidekick_memory_path` using Sidekick's standard YAML frontmatter format.

**Relationship file** (`{sidekick_memory_path}/relationships/{name}.md`):

```yaml
---
name: {Person Name}
type: relationship
created: {YYYY-MM-DD}
modified: {YYYY-MM-DD}
status: active
---

{Role and context. How they relate to the user. Where they were encountered.}
```

**Project file** (`{sidekick_memory_path}/projects/{slug}.md`):

```yaml
---
name: {Project Name}
type: project
created: {YYYY-MM-DD}
modified: {YYYY-MM-DD}
status: active
---

{What the project is. Why it matters. Key context.}
```

After writing, update `{sidekick_memory_path}/index.md` to include a pointer to the new file.

---

## Design Decisions

1. **Standalone plugin, not inside Sidekick.** Sidekick is the portable memory layer; this is the Cowork-only consumer. Different scopes, different platforms, different release cadences.
2. **File-based memory access, not MCP server.** Three skills don't justify a Node.js server. config.json stores the memory path. If more consumers emerge later, wrap the file layer in an MCP API.
3. **Cowork only.** Google Calendar MCP is only available in Cowork. Claude Code support can be added if/when those connectors become available there.
4. **Asana is read-only.** No task sync or write-back. Asana is the source of truth. Daily-brief reads from it but doesn't modify anything. Uses `get_my_tasks` with client-side date grouping, not `search_tasks_preview`.
5. **Explicit memory path in config.json.** Sidekick's orient hook doesn't reliably fire in Cowork. Rather than replicating the detection cascade, context-loader reads from a configured path.
6. **Approval-gated memory writes.** Both daily-brief and meeting-prep can propose saves to Sidekick memory for new people/projects. Nothing is saved without user confirmation. Writes use Sidekick's standard frontmatter format.
7. **Two-pass Slack scan.** Configured channels (by ID) get a full activity scan. Workspace-wide search catches @mentions outside those channels. Deduplicated to avoid noise.
8. **12-hour scan window.** Rather than tracking session timestamps, the Slack scan defaults to a 12-hour lookback window. This covers overnight activity without requiring persistent state.
9. **Inlined context loading.** Each skill includes Step 0 (context-loader logic) inline rather than invoking a separate skill via slash command. This avoids relying on Claude self-invoking skills mid-execution, matching Sidekick's proven pattern.
10. **Channel IDs in config.** Slack MCP tools require channel IDs, not names. Storing both avoids 18 resolution calls per briefing.
11. **Calendar filtering by heuristic.** No standard calendar attribute labels "focus time" or "working location." Filtering uses summary keywords and attendee/transparency signals.

---

## What This Doesn't Do

- **No task sync** — Asana is read-only. No bidirectional sync.
- **No content workflows** — weekly roundups, LinkedIn articles, design requests stay in marketing-skills.
- **No MCP server** — files are the access layer. If more consumers need Sidekick data, add the MCP server then.
- **No Claude Code support** — Cowork only for now.
- **No meeting notes storage** — meeting-prep generates prep docs but doesn't create persistent meeting notes files. That could be added later.

---

## Maintenance Notes

- **Slack channel list** — channels get created, archived, and renamed over time. Review `config.json` quarterly and update channel IDs/names as needed.
- **Config version** — the `config_version` field allows future migrations if the config format changes.

---

## Future Additions

- **weekly-review** — end-of-week summary of completed tasks, meetings attended, decisions made
- **Claude Code support** — if Google Calendar becomes available outside Cowork
- **Meeting notes** — persistent scratch space in Sidekick's knowledge space for during/after meetings
- **MCP server** — if Sidekick needs a stable API for multiple consumers
- **Session timestamp tracking** — persist last-run timestamp to narrow the Slack scan window more precisely
