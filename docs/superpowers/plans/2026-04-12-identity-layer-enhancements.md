# Identity Layer Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enrich Sidekick's relationship templates with structured frontmatter (relationship type, lifecycle status) and body sections (interaction, sensitive), add a goals template to the identity space, and update skills to leverage the new fields.

**Architecture:** Templates define the data shape. Skills (remember, orient, recall, reflect, setup) gain awareness of the new fields — routing, proactive capture, filtered queries, sensitive content guardrails, and goals-aware index generation. `templates/index.md` is the canonical source of truth for section order.

**Tech Stack:** Markdown skill files, YAML frontmatter, bash grep for frontmatter queries.

**Spec:** `docs/superpowers/specs/2026-04-12-identity-layer-enhancements-design.md`

---

### Task 1: Update relationship template

**Files:**
- Modify: `templates/relationship.md`

- [ ] **Step 1: Replace the relationship template with the updated version**

Replace the full contents of `templates/relationship.md` with:

```markdown
---
name: {person-name}
type: relationship
created: {date}
modified: {date}
status: active
relationship: {peer | reports-to-me | my-manager | collaborator | client | mentor | mentee | external}
---

**Role:** {role}
**Team:** {team}
**Email:** {email}
**Context:** {how you interact with this person}

## Interaction
{cadence, communication preferences, how you typically work together}

## Notes
{notes}

## Sensitive
{context Claude should know but not surface unprompted}
```

Changes from current template:
- Added `relationship` field to frontmatter
- `status` values documented as: `active`, `departing`, `incoming`, `former`
- Added `## Interaction` section between `**Context:**` and `## Notes`
- Added `## Sensitive` section after `## Notes`

- [ ] **Step 2: Verify the file renders correctly**

Run: `head -20 templates/relationship.md`

Expected: YAML frontmatter with `relationship` field, body starts with `**Role:**`

- [ ] **Step 3: Commit**

```bash
git add templates/relationship.md
git commit -m "feat: enrich relationship template with structured fields

Add relationship type frontmatter, lifecycle status values,
interaction section, and sensitive content section."
```

---

### Task 2: Create goals template

**Files:**
- Create: `templates/goals.md`

- [ ] **Step 1: Create the goals template file**

Write `templates/goals.md`:

```markdown
---
name: goals
type: identity
created: {date}
modified: {date}
status: active
---

## Current Priorities
{what you're focused on right now — this quarter, this month, this sprint}

## Longer-Term Goals
{where you're headed — career, skill development, team objectives}
```

- [ ] **Step 2: Verify the file exists and is well-formed**

Run: `cat templates/goals.md`

Expected: YAML frontmatter with `name: goals`, `type: identity`, two `##` sections.

- [ ] **Step 3: Commit**

```bash
git add templates/goals.md
git commit -m "feat: add goals template to identity space"
```

---

### Task 3: Update index template

**Files:**
- Modify: `templates/index.md`

- [ ] **Step 1: Add the `## Goals` section to the index template**

Current `templates/index.md` has this section order:
1. `## Identity`
2. `## Active Projects`
3. `## Key People`
4. `## Preferences`
5. `## Quick Reference`

Insert `## Goals` between `## Preferences` and `## Quick Reference`. The full updated file:

```markdown
# Context Index

## Identity
{identity_summary}

## Active Projects
| Project | Status | One-liner |
|---------|--------|-----------|
{projects_table}

## Key People
| Name | Role | Context |
|------|------|---------|
{people_table}

## Preferences
{top_preferences}

## Goals
{goals_summary}

## Quick Reference
- Identity details: `identity/`
- Relationships: `relationships/`
- Projects: `projects/`
- Decisions: `decisions/`
- Patterns: `patterns/`
- Knowledge: `knowledge/`
```

- [ ] **Step 2: Verify section order**

Run: `grep "^## " templates/index.md`

Expected output:
```
## Identity
## Active Projects
## Key People
## Preferences
## Goals
## Quick Reference
```

- [ ] **Step 3: Commit**

```bash
git add templates/index.md
git commit -m "feat: add Goals section to index template

Canonical placement between Preferences and Quick Reference.
All index writers (setup, remember, reflect) use this as source of truth."
```

---

### Task 4: Update remember skill

**Files:**
- Modify: `skills/remember/SKILL.md`

- [ ] **Step 1: Add goals routing entry to Step 2**

In `skills/remember/SKILL.md`, find the routing table in Step 2 (around line 32-44). Add a new row after the "Role, background, or a standing preference" entry and before "Tribal or institutional knowledge":

```markdown
| Current priorities, goals, or focus areas | `identity/` | `identity/goals.md` |
```

- [ ] **Step 2: Add relationship field guidance below the routing table**

After the routing table's closing line ("When the item could fit two spaces..."), add:

```markdown
**Relationship field guidance:** When routing to `relationships/`, also determine:
- `relationship` value — infer from context (e.g., "my direct report" → `reports-to-me`, "my manager" → `my-manager`, "works on the same team" → `peer`). Don't ask unless ambiguous.
- `status` value — default to `active`. Set `departing`, `incoming`, or `former` only when explicitly stated by the user.
```

- [ ] **Step 3: Add template notes to Step 4**

In Step 4 (around line 76-85), after the existing template reference list, add two items:

After the line `- templates/knowledge.md — for tribal/institutional knowledge`, add:

```markdown
- `templates/goals.md` — for goals and priorities (routes to `identity/goals.md`)

**Template overrides:**
- For relationship files, also include `relationship: {value}` in frontmatter. See `templates/relationship.md` for the full template including `## Interaction` and `## Sensitive` sections.
- For goals saves, use `templates/goals.md` (not the generic `templates/identity.md`). This ensures the `## Current Priorities` / `## Longer-Term Goals` structure is consistent.
```

- [ ] **Step 4: Verify the changes are coherent**

Run: `grep -n "goals\|relationship\|Sensitive\|Interaction" skills/remember/SKILL.md`

Expected: New references to goals routing, relationship field guidance, goals template override, and relationship template sections.

- [ ] **Step 5: Commit**

```bash
git add skills/remember/SKILL.md
git commit -m "feat: add goals routing and relationship field guidance to remember skill

- New routing entry: priorities/goals → identity/goals.md
- Relationship saves now infer relationship type and status
- Step 4 points to goals.md and relationship.md templates explicitly"
```

---

### Task 5: Update orient skill

**Files:**
- Modify: `skills/orient/SKILL.md`

- [ ] **Step 1: Update the "New people" bullet in Step 3 proactive capture**

In `skills/orient/SKILL.md`, find the "New people" bullet under "What to capture automatically" (around line 103). Replace:

```markdown
- **New people:** Any person mentioned with enough context to be useful — name, role, relationship to the user, why they matter. Write to `relationships/{person-name}.md`.
```

With:

```markdown
- **New people:** Any person mentioned with enough context to be useful — name, role, relationship to the user, why they matter. Write to `relationships/{person-name}.md`. When capturing, infer and set `relationship` and `status` frontmatter fields from conversation context. Default `status` to `active`. Infer `relationship` type from context (e.g., "my direct report" → `reports-to-me`) — don't ask unless ambiguous.
```

- [ ] **Step 2: Add status change bullet**

After the "Corrections" bullet (around line 106), add a new bullet:

```markdown
- **Status changes:** If the user mentions someone is leaving, joining, or has left, update that person's `status` field (`departing`, `incoming`, `former`). This is a proactive capture — don't wait for the user to say "remember that."
```

- [ ] **Step 3: Verify the changes**

Run: `grep -n "status\|relationship.*frontmatter\|Status changes" skills/orient/SKILL.md`

Expected: New references to relationship/status frontmatter inference and the status changes bullet.

- [ ] **Step 4: Commit**

```bash
git add skills/orient/SKILL.md
git commit -m "feat: add relationship field inference and status change capture to orient

- New people captures now infer relationship type and status
- Status changes (departing, incoming, former) are proactive captures"
```

---

### Task 6: Update recall skill

**Files:**
- Modify: `skills/recall/SKILL.md`

- [ ] **Step 1: Add Step 3b — frontmatter-aware queries**

In `skills/recall/SKILL.md`, after Step 3 (content search, ends around line 41), insert a new section:

```markdown
---

## Step 3b — Frontmatter-aware queries

When the user asks a question that maps to a frontmatter field, scan frontmatter directly instead of relying on content grep:

- "Who reports to me?" → grep `relationships/` for `relationship: reports-to-me`
- "Who's leaving?" / "Who's departing?" → grep for `status: departing`
- "Who's incoming?" → grep for `status: incoming`
- "Show me my peers" → grep for `relationship: peer`

```bash
grep -l "relationship: {value}" ~/.claude/memory/relationships/ 2>/dev/null
```

**Default lifecycle filtering:** Relationship queries that don't specify a status exclude `status: former` and `status: archived` results. "Who reports to me?" returns `active`, `departing`, and `incoming` only. To include former or archived, the user must explicitly ask ("who used to report to me?", "show former team members"). Explicit status queries ("who's departing?") work as-is since the user specified the filter.
```

- [ ] **Step 2: Update Step 5 — display format and sensitive guardrail**

In Step 5 (return results, around line 63-75), after the existing format example, add:

```markdown
When displaying relationship results, include `relationship` and `status` from frontmatter if present:

```
relationships/kyla-kurstin.md — relationship (departing)
  Design and Web Lead, Marketing. Last day March 20, 2026.
```

**Sensitive content guardrail:** When selecting the 2-4 line excerpt for results, exclude content under `## Sensitive`. This section exists specifically for context that should not be surfaced unprompted. Only include sensitive content when the user explicitly asks about it — e.g., "what's sensitive about Kyla?", "what should I be careful about with X?", "anything I should know before meeting with Y?"
```

- [ ] **Step 3: Verify the changes**

Run: `grep -n "3b\|lifecycle\|Sensitive\|former\|archived" skills/recall/SKILL.md`

Expected: References to Step 3b, lifecycle filtering, sensitive guardrail, former, and archived.

- [ ] **Step 4: Commit**

```bash
git add skills/recall/SKILL.md
git commit -m "feat: add frontmatter queries, lifecycle filtering, and sensitive guardrail to recall

- New Step 3b: frontmatter-aware queries for relationship type and status
- Default lifecycle filtering excludes former and archived
- Sensitive content excluded from default excerpts"
```

---

### Task 7: Update reflect skill

**Files:**
- Modify: `skills/reflect/SKILL.md`

- [ ] **Step 1: Add goals-aware index refresh to Step 3**

In `skills/reflect/SKILL.md`, find Step 3 (write approved saves, around line 76-106). After the line about updating `index.md` (line 105: "After all saves are complete, update `~/.claude/memory/index.md` if any of the saves are significant..."), add:

```markdown
When refreshing `index.md`, include a `## Goals` section if `identity/goals.md` exists. Summarize current priorities in 1-3 lines. Place it between `## Preferences` and `## Quick Reference` per the canonical order in `templates/index.md`. If `identity/goals.md` does not exist, omit the section — no empty placeholder.
```

- [ ] **Step 2: Verify the change**

Run: `grep -n "Goals\|goals" skills/reflect/SKILL.md`

Expected: New reference to goals-aware index refresh.

- [ ] **Step 3: Commit**

```bash
git add skills/reflect/SKILL.md
git commit -m "feat: add goals-aware index refresh to reflect skill

Index refresh now includes ## Goals section when identity/goals.md exists,
following canonical placement from templates/index.md."
```

---

### Task 8: Update setup skill

**Files:**
- Modify: `skills/setup/SKILL.md`

- [ ] **Step 1: Add optional Q5 for goals in Step 3**

In `skills/setup/SKILL.md`, find Step 3 (conversational onboarding, around line 134-149). After question 4 and before the "After collecting all answers:" block, add:

```markdown
5. "What are your current priorities or goals? (skip if you'd rather add these later)"
```

Then update the "After collecting all answers:" block. After the line about writing `identity/preferences.md`, add:

```markdown
- If Q5 was answered: write `{SIDEKICK_ROOT}/memory/identity/goals.md` using `templates/goals.md`. Map the answer to "Current Priorities." Leave "Longer-Term Goals" empty.
- If Q5 was skipped: do not create the file.
```

- [ ] **Step 2: Add goals to Step 5 index generation**

In Step 5 (generate index.md, around line 194-200), after the existing instruction to generate the index, add:

```markdown
If `identity/goals.md` was created in Step 3, include a `## Goals` section in the generated index. Summarize current priorities in 1-3 lines. Place it between `## Preferences` and `## Quick Reference` per the canonical order in `templates/index.md`. If goals were skipped, omit the section.
```

- [ ] **Step 3: Verify the changes**

Run: `grep -n "goals\|Goals\|Q5\|priorities" skills/setup/SKILL.md`

Expected: References to Q5, goals.md, goals template, and goals index section.

- [ ] **Step 4: Commit**

```bash
git add skills/setup/SKILL.md
git commit -m "feat: add optional goals onboarding and goals-aware index generation to setup

- New Q5 asks for current priorities (skippable)
- Step 5 includes Goals section in index when goals file exists"
```

---

### Task 9: Final verification

**Files:** None (read-only verification)

- [ ] **Step 1: Verify all 8 files are modified**

Run: `git log --oneline main..HEAD`

Expected: 8 commits, one per task (Tasks 1-8).

- [ ] **Step 2: Verify spec coverage**

Cross-check each item from the spec's "Files Changed" table:

| Spec requirement | Task |
|-----------------|------|
| `templates/relationship.md` — relationship frontmatter, status values, Interaction, Sensitive | Task 1 |
| `templates/goals.md` — new file | Task 2 |
| `templates/index.md` — Goals section between Preferences and Quick Reference | Task 3 |
| `skills/remember/SKILL.md` — goals routing, relationship guidance, template notes | Task 4 |
| `skills/orient/SKILL.md` — proactive capture for new fields + status changes | Task 5 |
| `skills/recall/SKILL.md` — frontmatter queries, lifecycle filtering, sensitive guardrail | Task 6 |
| `skills/reflect/SKILL.md` — goals-aware index refresh | Task 7 |
| `skills/setup/SKILL.md` — Q5 goals, Step 5 index generation | Task 8 |

- [ ] **Step 3: Verify no unintended changes**

Run: `git diff --stat main..HEAD`

Expected: Only the 8 files listed above, plus the spec and plan docs.

- [ ] **Step 4: Read each modified skill file end-to-end**

Read each of the 5 modified skills in full to confirm:
- New content integrates cleanly with existing steps
- Step numbering is consistent
- No contradictions between skills (e.g., remember and orient agree on frontmatter fields)
- No dangling references to steps or templates that don't exist
