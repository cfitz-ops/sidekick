# corey-skills Plugin Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone Claude plugin for Cowork with three personal productivity skills (context-loader, daily-brief, meeting-prep) that consume Sidekick's personal memory and external MCP connectors.

**Architecture:** Markdown-only plugin — no code, no build step. Skills are SKILL.md instruction files read by Claude at invocation time. Config is a JSON file with personal settings (Slack channels, memory path, user IDs). Plugin targets Cowork only.

**Tech Stack:** Markdown (skills), JSON (config, plugin manifest)

**Spec:** `docs/superpowers/specs/2026-03-25-personal-skills-plugin-design.md`

---

## File Structure

All files live in a new repo `corey-skills/`:

| File | Action | Purpose |
|------|--------|---------|
| `.claude-plugin/plugin.json` | Create | Plugin manifest (Cowork only) |
| `config.json` | Create | Personal config — Slack channels/IDs, memory path, user settings |
| `skills/context-loader/SKILL.md` | Create | Standalone context loading from Sidekick memory |
| `skills/daily-brief/SKILL.md` | Create | Morning briefing skill |
| `skills/meeting-prep/SKILL.md` | Create | Meeting preparation skill |
| `README.md` | Create | Setup and usage docs |
| `.gitignore` | Create | Standard ignores |

---

## Chunk 0: Sidekick Template Update

### Task 0: Add Email field to Sidekick's relationship template

The spec extends the relationship format with an `**Email:**` field for calendar attendee matching. Update the Sidekick template to match.

**Files:**
- Modify: `templates/relationship.md` (in the Sidekick repo)

- [ ] **Step 1: Update the template**

In the Sidekick repo (`~/Desktop/claude-projects/sidekick/`), edit `templates/relationship.md`. Add the `**Email:**` line between `**Team:**` and `**Context:**`:

```markdown
---
name: {person-name}
type: relationship
created: {date}
modified: {date}
status: active
---

**Role:** {role}
**Team:** {team}
**Email:** {email}
**Context:** {how you interact with this person}

## Notes
{notes}
```

- [ ] **Step 2: Commit to Sidekick on a feature branch**

```bash
cd ~/Desktop/claude-projects/sidekick
git checkout -b feature/relationship-email-field
git add templates/relationship.md
git commit -m "feat: add email field to relationship template for attendee matching"
```

- [ ] **Step 3: Push and create PR**

```bash
git push -u origin feature/relationship-email-field
gh pr create --title "Add email field to relationship template" --body "Adds **Email:** field to the relationship template for calendar attendee matching. Used by the corey-skills plugin's meeting-prep skill."
```

- [ ] **Step 4: Merge and return to main**

After PR is approved:

```bash
git checkout main
git pull
```

---

## Chunk 1: Repository Scaffold and Config

### Task 1: Create the repository and plugin manifest

**Files:**
- Create: `corey-skills/.claude-plugin/plugin.json`
- Create: `corey-skills/.gitignore`

- [ ] **Step 1: Create the repo directory and initialize git**

```bash
mkdir -p ~/Desktop/claude-projects/corey-skills/.claude-plugin
cd ~/Desktop/claude-projects/corey-skills
git init
```

- [ ] **Step 2: Write the plugin manifest**

Write to `.claude-plugin/plugin.json`:

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

- [ ] **Step 3: Write .gitignore**

Write to `.gitignore`:

```
.DS_Store
*.env
node_modules/
```

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/plugin.json .gitignore
git commit -m "feat: initialize corey-skills plugin with manifest"
```

---

### Task 2: Write config.json

**Files:**
- Create: `corey-skills/config.json`

- [ ] **Step 1: Write the config file**

Write to `config.json`:

```json
{
  "config_version": 1,
  "sidekick_memory_path": "~/.claude/.sidekick/memory/",
  "user_email": "corey@tigerdata.com",
  "user_timezone": "America/New_York",
  "slack_user_id": "UXXXXXXXXXX",
  "slack_display_name": "Corey Fitz",
  "slack_channels": [
    { "name": "#content-flywheel", "id": "CXXXXXXXXX1", "leadership": false },
    { "name": "#marketing-leadership", "id": "CXXXXXXXXX2", "leadership": true },
    { "name": "#marketing-private", "id": "CXXXXXXXXX3", "leadership": false },
    { "name": "#marketing-skills-private", "id": "CXXXXXXXXX4", "leadership": false },
    { "name": "#marketing", "id": "CXXXXXXXXX5", "leadership": false },
    { "name": "#marketing-web", "id": "CXXXXXXXXX6", "leadership": false },
    { "name": "#leads-management-team", "id": "CXXXXXXXXX7", "leadership": true },
    { "name": "#leads-marketing", "id": "CXXXXXXXXX8", "leadership": true },
    { "name": "#marketing-datatalks", "id": "CXXXXXXXXX9", "leadership": false },
    { "name": "#marketing-abl", "id": "CXXXXXXXXXA", "leadership": false },
    { "name": "external-freelance-writers", "id": "CXXXXXXXXXB", "leadership": false },
    { "name": "#marketing-tools-feedback", "id": "CXXXXXXXXXC", "leadership": false },
    { "name": "#sales-team", "id": "CXXXXXXXXXD", "leadership": false },
    { "name": "#revops-and-marketing-ops", "id": "CXXXXXXXXXE", "leadership": false },
    { "name": "#seo-geo-updates", "id": "CXXXXXXXXXF", "leadership": false },
    { "name": "#marketing-shared-services", "id": "CXXXXXXXXXG", "leadership": false },
    { "name": "#gtm-weekly-leads", "id": "CXXXXXXXXXH", "leadership": false },
    { "name": "#discussion-one-tiger", "id": "CXXXXXXXXXI", "leadership": false }
  ]
}
```

**Note:** Placeholder channel IDs (`CXXXXXXXXX1`, etc.) must be replaced with real Slack channel IDs before first use. Find IDs via `slack_search_channels` in Cowork or from Slack UI (channel details → About tab → bottom). Similarly, replace `slack_user_id` with the real value.

- [ ] **Step 2: Commit**

```bash
git add config.json
git commit -m "feat: add personal config with Slack channels and memory path"
```

---

## Chunk 2: Context-Loader Skill

### Task 3: Write the context-loader skill

**Files:**
- Create: `corey-skills/skills/context-loader/SKILL.md`

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p skills/context-loader
```

- [ ] **Step 2: Write the skill**

Write to `skills/context-loader/SKILL.md`:

```markdown
---
name: context-loader
description: |
  Load personal context from Sidekick memory into the current session. Reads the
  memory index, identity files, and relationships to build a people lookup table.
  Use when: /context-loader, "load my context", or as Step 0 of daily-brief/meeting-prep.
---

## Step 0 — Read config and resolve memory path

1. Read `config.json` from the plugin root directory.
2. Get the `sidekick_memory_path` value.
3. **Expand the path:** resolve `~` to the user's home directory (e.g., `~/.claude/.sidekick/memory/` → `/home/user/.claude/.sidekick/memory/`). All subsequent file operations use the expanded absolute path.
4. Verify the path exists. If it does not exist or is empty:
   > "Sidekick memory not found at `{path}`. Check `sidekick_memory_path` in config.json, or run `/sidekick:setup` to initialize memory."

   Continue without personal context — the session still works, just without enrichment.

---

## Step 1 — Load memory index

Read `{memory_path}/index.md`. This is the hot cache summary containing:
- Identity (role, responsibilities)
- Active projects (table)
- Key people (table)
- Preferences

Internalize this context silently — do not print it unless the user asks.

---

## Step 2 — Load identity files

Read all `.md` files in `{memory_path}/identity/`. These contain:
- Full profile (role, goals, responsibilities)
- Stack and tools
- Working preferences

Internalize silently.

---

## Step 3 — Build people lookup table

Read all `.md` files in `{memory_path}/relationships/`. For each file, extract:
- `name` from YAML frontmatter
- `**Email:**` field (if present)
- `**Role:**` field
- `**Team:**` field
- `**Context:**` field

Build a lookup table keyed by both name (case-insensitive) and email (if available). This table is used by daily-brief and meeting-prep to resolve people mentioned in Slack messages and calendar attendees.

---

## Step 4 — Confirm (standalone invocation only)

If invoked directly via `/context-loader` (not as Step 0 of another skill), confirm what was loaded:

> **Context loaded:**
> - Identity: {count} files
> - Relationships: {count} people
> - Projects: {count from index}
> - Memory path: `{expanded_path}`

If invoked as Step 0 of daily-brief or meeting-prep, skip this confirmation — the calling skill handles its own output.
```

- [ ] **Step 3: Commit**

```bash
git add skills/context-loader/SKILL.md
git commit -m "feat: add context-loader skill for Sidekick memory access"
```

---

## Chunk 3: Daily-Brief Skill

### Task 4: Write the daily-brief skill

**Files:**
- Create: `corey-skills/skills/daily-brief/SKILL.md`

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p skills/daily-brief
```

- [ ] **Step 2: Write the skill**

Write to `skills/daily-brief/SKILL.md`:

```markdown
---
name: daily-brief
description: |
  Daily morning briefing that aggregates calendar, Asana tasks, and Slack activity,
  enriched with personal context from Sidekick memory. Proposes memory saves for
  new people or projects discovered. Offers meeting-prep follow-up.
  Use when: /daily-brief, "brief me", "what's on my plate", "start my day".
---

## Step 0 — Load context

Run the context-loader logic inline:

1. Read `config.json` from the plugin root directory.
2. Get `sidekick_memory_path` and **expand `~`** to the user's home directory. All file operations use the expanded absolute path.
3. Read `{memory_path}/index.md` — internalize silently.
4. Read all files in `{memory_path}/identity/` — internalize silently.
5. Read all files in `{memory_path}/relationships/` — build a people lookup table keyed by name (case-insensitive) and email (if present in `**Email:**` field).
6. If the memory path doesn't exist or is empty, warn the user and continue without personal context.

Also read from `config.json`:
- `user_email`
- `user_timezone`
- `slack_user_id`
- `slack_display_name`
- `slack_channels` (array with `name`, `id`, and `leadership` fields)

---

## Step 1 — Pull calendar

Call `gcal_list_events` for today's date using `user_timezone` from config.

**Filter to real meetings only.** Skip events that match ANY of these:
- Summary contains "Focus Time", "OOO", "Working Location", "Lunch", or "Block" (case-insensitive)
- Has 0 attendees AND `transparency` is `"transparent"`
- `status` is `"cancelled"`

Keep everything else. For each kept event, note:
- Time and duration
- Summary (meeting title)
- Attendees (resolve against the people lookup table from Step 0)
- Location or video link if present

**If Google Calendar MCP is unavailable:** skip this step entirely. Note: "Calendar unavailable — skipped." Continue with remaining steps.

---

## Step 2 — Pull Asana tasks

Call `get_my_tasks` to retrieve all incomplete tasks assigned to the user.

**Request fields:** `name`, `due_on`, `due_at`, `completed`, `assignee_status`, `projects.name`

Group tasks client-side by due date:
- **Overdue** — `due_on` is before today's date
- **Due today** — `due_on` is today
- **Due this week** — `due_on` is within the next 7 days (after today, up to and including 7 days from now)

Tasks with no `due_on` are excluded from the briefing.

**Do NOT use `search_tasks_preview`** — it renders a UI preview and does not return structured data suitable for reformatting.

**If Asana MCP is unavailable:** skip all task sections. Note: "Asana unavailable — skipped." Continue with remaining steps.

**If `get_my_tasks` fails due to missing workspace GID:** note the error and suggest adding `asana_workspace_gid` to config.json.

---

## Step 3 — Scan Slack

### Pass 1 — Configured channels

For each channel in `config.json`'s `slack_channels` array:

1. Call `slack_read_channel` with the channel `id` and `oldest` set to 12 hours ago (calculate UTC timestamp: current time minus 43200 seconds).
2. Scan messages for:
   - **Direct @mentions** of the user (contains `<@{slack_user_id}>`)
   - **Unanswered questions** directed at the user (mentions + question mark, or reply-requested patterns)
   - **Action items** — tasks, requests, or decisions that require response
3. For channels marked `"leadership": true`, surface ALL action items with higher priority — these appear in the "Leadership action items" section of the briefing.
4. Resolve sender names against the people lookup table from Step 0. If a sender matches a known relationship, include their role for context.

### Pass 2 — Workspace-wide @mentions

Call `slack_search_public_and_private` with:
- Query: `<@{slack_user_id}>`
- Date filter: last 12 hours

If the `<@user_id>` query syntax is not supported, fall back to `slack_search_public` with `slack_display_name` from config as a keyword search.

Deduplicate against Pass 1 results (same channel + same message timestamp = duplicate). Surface any mentions from channels NOT in the configured list — these are unexpected pings the user might have missed.

**If Slack MCP is unavailable:** skip both passes. Note: "Slack unavailable — skipped." Continue with remaining steps.

---

## Step 4 — Deliver briefing

Present a single scannable output in this order. Only include sections that have data — skip empty sections silently.

### Overdue
For each overdue Asana task:
> - **{task name}** — due {due_on} ({days} days overdue) · {project name}

### Due Today
For each task due today:
> - **{task name}** · {project name}

### Unanswered Slack Questions
For each unanswered question:
> - **{sender name}** ({role if known}) in {channel name}: "{message preview}" — {time}

### Leadership Action Items
For each action item from `"leadership": true` channels:
> - **{channel name}**: "{message preview}" — {sender name}, {time}

### Today's Schedule
For each meeting (chronological):
> - **{time}** — {meeting title}
>   Attendees: {names with roles from Sidekick where known}

### Due This Week
For each task due this week:
> - **{task name}** — due {due_on} ({day of week}) · {project name}

---

## Step 5 — Propose memory saves

Review all people and project names surfaced during the briefing. Compare against the people lookup table and projects from `index.md`.

For each NEW person (not in relationships/) who appeared in 2+ messages or is in a leadership channel:
> "I noticed **{name}** ({context where they appeared}). Want me to save them to Sidekick memory?"

For each NEW project name that appeared in Asana tasks but isn't in `index.md`:
> "I noticed a project called **{name}**. Want me to save it?"

**Wait for user confirmation before writing anything.**

If the user confirms:
- Write relationship files to `{memory_path}/relationships/{canonical-name}.md` using the canonical filename rule: lowercase, replace spaces with hyphens, strip punctuation. Check for existing files first to prevent duplicates.
- Write project files to `{memory_path}/projects/{slug}.md`.
- Use the Memory Write Format from the spec (Sidekick's YAML frontmatter format with `**Role:**`, `**Team:**`, `**Email:**`, `**Context:**`, `## Notes` for relationships; `**Goal:**`, `**Stack:**`, `## Current Status`, `## Next Steps` for projects).
- Update `{memory_path}/index.md`: add a row to the `## Key People` table (`| {Name} | {Role} | {Context} |`) or `## Active Projects` table (`| {Project} | {Status} | {One-liner} |`).

---

## Step 6 — Offer follow-up

If today's schedule has meetings:
> "Want me to prep notes for today's meetings? → `/meeting-prep`"

If not, end the briefing.
```

- [ ] **Step 3: Commit**

```bash
git add skills/daily-brief/SKILL.md
git commit -m "feat: add daily-brief skill with calendar, Asana, and Slack aggregation"
```

---

## Chunk 4: Meeting-Prep Skill

### Task 5: Write the meeting-prep skill

**Files:**
- Create: `corey-skills/skills/meeting-prep/SKILL.md`

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p skills/meeting-prep
```

- [ ] **Step 2: Write the skill**

Write to `skills/meeting-prep/SKILL.md`:

```markdown
---
name: meeting-prep
description: |
  Prepare for today's meetings by resolving attendees against Sidekick memory and
  Slack profiles, enriching with project context, and generating prep docs with
  suggested talking points. Proposes saving new relationships to Sidekick.
  Use when: /meeting-prep, "prep my meetings", "meeting notes".
---

## Step 0 — Load context

Run the context-loader logic inline:

1. Read `config.json` from the plugin root directory.
2. Get `sidekick_memory_path` and **expand `~`** to the user's home directory. All file operations use the expanded absolute path.
3. Read `{memory_path}/index.md` — internalize silently.
4. Read all files in `{memory_path}/identity/` — internalize silently.
5. Read all files in `{memory_path}/relationships/` — build a people lookup table keyed by name (case-insensitive) and email (if present in `**Email:**` field).
6. If the memory path doesn't exist or is empty, warn the user and continue without personal context.

Also read from `config.json`:
- `user_email`
- `user_timezone`

---

## Step 1 — Pull calendar

Call `gcal_list_events` for the target date (default: today) using `user_timezone` from config.

**Filter to real meetings only.** Skip events that match ANY of these:
- Summary contains "Focus Time", "OOO", "Working Location", "Lunch", or "Block" (case-insensitive)
- Has 0 attendees AND `transparency` is `"transparent"`
- `status` is `"cancelled"`

Keep everything else.

**If Google Calendar MCP is unavailable:** ask the user to paste their meeting details manually:
> "Google Calendar is not available. Paste your meeting details (title, time, attendees) and I'll prep from that."

Parse whatever the user provides and continue from Step 2.

---

## Step 2 — Present meeting list

Show each meeting with time and attendee count:

> **Today's meetings:**
> 1. **{time}** — {meeting title} ({N} attendees)
> 2. **{time}** — {meeting title} ({N} attendees)
> ...
>
> Which meetings should I prep? (all / numbers / skip)

Default to all if the user confirms without specifying.

---

## Step 3 — Resolve attendees

For each attendee in the selected meetings:

1. **Identify self** — skip the attendee entry where `self: true`. No email matching needed.

2. **Search Sidekick relationships:**
   - Match by email first (check the `**Email:**` field in each relationship file against the attendee's email from the calendar event).
   - If no email match, match by name (case-insensitive comparison of the `name` frontmatter field against the attendee's display name).
   - If found: extract `**Role:**`, `**Team:**`, `**Email:**`, `**Context:**`, and `## Notes` content.

3. **Fall back to Slack (if attendee not in Sidekick):**
   - Call `slack_search_users` with the attendee's name or email.
   - If found: call `slack_read_user_profile` with their Slack user ID. Extract role/title, timezone, and current status.
   - If Slack MCP is unavailable: show the attendee's name and email from the calendar event with no enrichment.

4. **Track unknown attendees** — keep a list of attendees not found in Sidekick memory for the save proposal in Step 6.

---

## Step 4 — Enrich with project context

For each selected meeting:

1. Check if the meeting title (or keywords from the title) matches any project in `{memory_path}/projects/`. Match against the `name` field in YAML frontmatter.
2. If a match is found, read the full project file and extract `**Goal:**`, `## Current Status`, and `## Next Steps`.
3. Include this context in the prep doc for that meeting.

---

## Step 5 — Deliver prep docs

For each selected meeting, present a prep document:

> ### {meeting title} — {time}
>
> **Attendees:**
> - **{Name}** — {Role}, {Team}. {Context from Sidekick or Slack}
> - **{Name}** — {Role}, {Team}. {Context from Sidekick or Slack}
> - {Name} — {email} (not in Sidekick or Slack)
>
> **Project context:** *(if matched)*
> {Goal, current status, next steps from Sidekick projects space}
>
> **Suggested talking points:**
> - {Based on attendee roles, project context, and meeting title}
> - {Based on relationships context and recent notes}

---

## Step 6 — Propose relationship saves

Review the list of unknown attendees (from Step 3, item 4). For attendees who seem worth remembering, propose saves:

**Worth remembering = any of:**
- Appears in 2+ meetings today
- Has a leadership or director+ title (from Slack profile)
- Is from a cross-functional team (not the user's direct team)

For each:
> "I found **{name}** ({role from Slack}, {team}) in your meetings but they're not in Sidekick. Save them?"

**Wait for user confirmation before writing anything.**

If the user confirms:
- Write to `{memory_path}/relationships/{canonical-name}.md` using the canonical filename rule: lowercase, replace spaces with hyphens, strip punctuation. Check for existing files first to prevent duplicates.
- Use Sidekick's relationship template format:
  ```
  ---
  name: {Person Name}
  type: relationship
  created: {today's date}
  modified: {today's date}
  status: active
  ---

  **Role:** {role from Slack or calendar}
  **Team:** {team from Slack or "Unknown"}
  **Email:** {email from calendar event}
  **Context:** {Met in {meeting title} on {date}. {Any additional context from Slack profile.}}

  ## Notes
  {Initial notes from meeting prep context}
  ```
- Update `{memory_path}/index.md`: add a row to the `## Key People` table: `| {Name} | {Role} | {Context} |`
```

- [ ] **Step 3: Commit**

```bash
git add skills/meeting-prep/SKILL.md
git commit -m "feat: add meeting-prep skill with attendee resolution and project enrichment"
```

---

## Chunk 5: README and Final Setup

### Task 6: Write README

**Files:**
- Create: `corey-skills/README.md`

- [ ] **Step 1: Write the README**

Write to `README.md`:

```markdown
# corey-skills

Personal productivity skills for Cowork. Combines Sidekick's personal memory with Asana, Slack, and Google Calendar to deliver daily briefings and meeting prep.

## Skills

| Skill | Trigger | What it does |
|-------|---------|--------------|
| **context-loader** | `/context-loader` | Loads Sidekick memory (identity, relationships) into the session |
| **daily-brief** | `/daily-brief` | Morning briefing: calendar, Asana tasks, Slack scan |
| **meeting-prep** | `/meeting-prep` | Meeting prep: attendee resolution, project context, talking points |

## Setup

### Prerequisites

- **Cowork** with these MCP connectors enabled:
  - Google Calendar
  - Asana
  - Slack
- **Sidekick** plugin installed with memory populated

### Configuration

1. Clone this repo and install as a Cowork plugin
2. Edit `config.json` with your real values:
   - `sidekick_memory_path` — path to your Sidekick memory directory
   - `slack_user_id` — your Slack user ID (find via `slack_read_user_profile`)
   - `slack_display_name` — your Slack display name
   - `slack_channels` — update channel IDs (find via `slack_search_channels` or Slack UI → channel details → About)
   - `user_email` — your work email (for calendar attendee matching)
3. Run `/context-loader` to verify memory access

### Channel IDs

Channel IDs are required by the Slack MCP tools. To find them:
- In Cowork: call `slack_search_channels` with the channel name
- In Slack: open channel details → scroll to bottom of About tab

### Graceful degradation

All MCP connectors are optional except Sidekick memory. If a connector is unavailable, the skill skips that section and notes what was missed. The briefing and prep still work with whatever's available.

## Architecture

This plugin reads from Sidekick memory but does not own it. Sidekick is the memory store; this plugin is the consumer.

- **Sidekick** → personal memory (identity, relationships, projects, decisions)
- **corey-skills** → productivity skills that combine memory with external tools
- **Claude auto memory** → project-scoped learnings (handled natively)

Memory writes (new people, new projects) go through Sidekick's file format and require user confirmation before saving.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with setup instructions and architecture overview"
```

---

### Task 7: Create GitHub repo and push

- [ ] **Step 1: Create the remote repo**

```bash
gh repo create cfitz-ops/corey-skills --private --source=. --push
```

- [ ] **Step 2: Verify**

```bash
gh repo view cfitz-ops/corey-skills
git log --oneline
```

Expected: 6 commits on `main`. Task 8 adds a 7th via PR after Slack IDs are populated.

---

### Task 8: Populate real Slack channel IDs

This task requires a Cowork session with Slack MCP connected.

- [ ] **Step 1: Look up each channel ID**

For each channel in `config.json`, call `slack_search_channels` with the channel name and `channel_types: "public_channel,private_channel"`. Record the returned channel ID.

- [ ] **Step 2: Look up Slack user ID**

Call `slack_read_user_profile` (no arguments — returns current user). Record the `user_id` and `display_name`.

- [ ] **Step 3: Create a feature branch and update config.json**

```bash
git checkout -b chore/populate-slack-ids
```

Replace all placeholder IDs (`CXXXXXXXXX1`, etc.) with real channel IDs. Replace `UXXXXXXXXXX` with real Slack user ID. Verify `slack_display_name` matches.

- [ ] **Step 4: Commit, push, and create PR**

```bash
git add config.json
git commit -m "chore: populate real Slack channel and user IDs"
git push -u origin chore/populate-slack-ids
gh pr create --title "Populate real Slack channel and user IDs" --body "Replaces placeholder IDs with real values from Slack."
```

Merge the PR, then return to main:

```bash
git checkout main
git pull
```

---

## Execution Notes

- **Tasks 1-6** can be done in Claude Code (just writing files).
- **Task 7** requires GitHub CLI (`gh`).
- **Task 8** must be done in Cowork with Slack MCP connected — it's the only environment where `slack_search_channels` is available.
- After Task 8, test the full flow in Cowork: `/context-loader` → `/daily-brief` → `/meeting-prep`.
- The `sidekick_memory_path` in config must point to a populated Sidekick memory directory. If using Cowork with a mounted folder, update the path to match the mount point (e.g., `/sessions/.../mnt/folder/.sidekick/memory/`).
