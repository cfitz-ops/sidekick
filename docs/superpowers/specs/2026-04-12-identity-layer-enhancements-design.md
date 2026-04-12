# Identity Layer Enhancements

**Date:** 2026-04-12
**Status:** Draft
**Scope:** Templates + skill awareness (Approach B)

## Motivation

Sidekick's differentiation from Claude's built-in auto memory is the personal identity layer — who the user is, their relationships, and cross-project decisions that follow them across repos and devices. Built-in memory handles project-scoped coding context well. Sidekick should lean into the person-scoped, cross-project niche.

The current relationship template is flat — a name, role, team, email, and freeform notes. It lacks structured fields for how someone relates to the user, their lifecycle status, interaction patterns, and sensitive context. The identity space also has no dedicated place for goals and priorities, which are the most actionable cross-conversation context for Claude to understand what someone is optimizing for.

## Design Principles

- **Frontmatter for enumerable values** that skills need to filter or scan quickly.
- **Body sections for narrative** that Claude reads and understands in context.
- **Optional fields** — if a user doesn't fill something in, it doesn't exist in the file. No noise.
- **Backward compatible** — existing files without new fields continue to work. Missing `relationship` is treated as unspecified. Missing `status` defaults to `active`.

---

## 1. Relationship Template

### Updated `templates/relationship.md`

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

### Field details

**Frontmatter fields:**

| Field | Values | Default | Purpose |
|-------|--------|---------|---------|
| `status` | `active`, `departing`, `incoming`, `former` | `active` | Lifecycle state. Skills can filter on this (e.g., orient deprioritizes `former`). |
| `relationship` | `peer`, `reports-to-me`, `my-manager`, `collaborator`, `client`, `mentor`, `mentee`, `external` | None (optional) | How this person relates to the user. Enables queries like "who reports to me?" |

**Body sections:**

| Section | Purpose |
|---------|---------|
| `**Context:**` | One-liner gloss — kept from current template. Quick orientation. |
| `## Interaction` | Longer-form: cadence (weekly 1:1, ad hoc), communication style, how you typically work together. |
| `## Notes` | General catch-all — unchanged from current template. |
| `## Sensitive` | Context Claude should know but not surface unprompted. e.g., "Kyla doesn't know about Tanya," "salary discussion in progress." |

---

## 2. Goals Template

### New file: `templates/goals.md`

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

Lives at `identity/goals.md` alongside `profile.md`, `preferences.md`, and `stack.md`. Changes more frequently than those — `modified` date signals staleness.

### Index surfacing

Goals must appear in `index.md` to be loaded at session start. Add a `## Goals` section after `## Identity` (or after `## Preferences`, depending on existing layout). Keep it to 1-3 lines — the hot cache summary, not the full file. Example:

```
## Goals
- Q2 2026: Scale Claude usage across the 20-person marketing team via skills library
- Longer-term: Build internal tools capability that reduces dependency on engineering
```

The `remember` skill updates this section when `identity/goals.md` is created or significantly changed (same logic as other index-worthy saves). The `reflect` skill refreshes it during end-of-session review.

---

## 3. Skill Changes

### 3a. `skills/remember/SKILL.md`

**Step 2 (routing table):** Add a new entry to the routing table:

| What the user wants to save | Space | Example path |
|-----------------------------|-------|--------------|
| Current priorities, goals, or focus areas | `identity/` | `identity/goals.md` |

Add guidance below the table for relationship routing:

> When routing to `relationships/`, also determine:
> - `relationship` value — infer from context (e.g., "my direct report" → `reports-to-me`). Don't ask unless ambiguous.
> - `status` value — default to `active`. Set `departing`, `incoming`, or `former` only when explicitly stated.

**Step 4 (file format):** Add a note below the generic frontmatter block:

> For relationship files, also include `relationship: {value}` in frontmatter. See `templates/relationship.md` for the full template including `## Interaction` and `## Sensitive` sections.

No changes to Steps 1, 3, 5, or 6.

### 3b. `skills/orient/SKILL.md`

**Step 3 (proactive capture):** Under "What to capture automatically," update the "New people" bullet to include:

> When capturing a new relationship, infer and set `relationship` and `status` frontmatter fields from conversation context. Default to `active`. Infer relationship type from context — don't ask.

Add a new bullet:

> - **Status changes:** If the user mentions someone is leaving, joining, or has left, update that person's `status` field (`departing`, `incoming`, `former`). This is a proactive capture — don't wait for the user to say "remember that."

No changes to Steps 0, 0b, 1, 1.5, or 2.

### 3c. `skills/recall/SKILL.md`

**New Step 3b (frontmatter-aware queries):** Insert after Step 3. When the user asks a question that maps to a frontmatter field, scan frontmatter directly:

- "Who reports to me?" → grep `relationships/` for `relationship: reports-to-me`
- "Who's leaving?" / "Who's departing?" → grep for `status: departing`
- "Who's incoming?" → grep for `status: incoming`
- "Show me my peers" → grep for `relationship: peer`

**Default lifecycle filtering:** Relationship queries that don't specify a status exclude `status: former` and `status: archived` results. "Who reports to me?" returns `active`, `departing`, and `incoming` only. To include former or archived: the user must explicitly ask ("who used to report to me?", "show former team members"). Explicit status queries ("who's departing?") work as-is since the user specified the filter.

**Step 5 (return results):** When displaying relationship results, include `relationship` and `status` from frontmatter if present:

```
relationships/kyla-kurstin.md — relationship (departing)
  Design and Web Lead, Marketing. Last day March 20, 2026.
```

**Sensitive content guardrail:** When selecting the 2-4 line excerpt for results, exclude content under `## Sensitive`. This section exists specifically for context that should not be surfaced unprompted. Only include sensitive content when the user explicitly asks about it — e.g., "what's sensitive about Kyla?", "what should I be careful about with X?", "anything I should know before meeting with Y?"

No changes to Steps 1, 2, 4, 6, or 7.

### 3d. `skills/reflect/SKILL.md`

**Index refresh:** When reflect refreshes `index.md` at session end, include a `## Goals` section if `identity/goals.md` exists. Summarize current priorities in 1-3 lines. If `identity/goals.md` does not exist, omit the section — no empty placeholder.

No other changes to reflect's existing behavior (conversation scanning, batch proposals, stale file archiving).

### 3e. `skills/setup/SKILL.md`

**Step 3 (conversational onboarding):** Add a fifth optional question:

> 5. "What are your current priorities or goals? (skip if you'd rather add these later)"

If answered: write `{SIDEKICK_ROOT}/memory/identity/goals.md` using `templates/goals.md`. Map the answer to "Current Priorities." Leave "Longer-Term Goals" empty.

If skipped: don't create the file.

No changes to Steps 0–2b or 4–6.

---

## 4. Backward Compatibility

- **Existing relationship files missing new fields:** Skills treat missing `relationship` as unspecified — no filtering, no errors. Missing `status` defaults to `active`.
- **Existing identity files:** Untouched. `goals.md` is additive.
- **Index format:** Adds a `## Goals` section. Existing indexes without it continue to work — orient loads what's there. The section gets added when goals are first saved.
- **Migration:** Not required. Existing files can be backfilled manually or updated naturally via proactive capture as people come up in conversation.

---

## 5. Files Changed

| File | Change |
|------|--------|
| `templates/relationship.md` | Add `relationship` frontmatter, document `status` values, add `## Interaction`, `## Sensitive` |
| `templates/goals.md` | New file |
| `skills/remember/SKILL.md` | Step 2 new routing entry for goals, guidance for relationship fields, Step 4 frontmatter note |
| `skills/orient/SKILL.md` | Step 3 proactive capture for new fields + status change detection |
| `skills/recall/SKILL.md` | New Step 3b frontmatter-aware queries with default lifecycle filtering, Step 5 display format + sensitive content guardrail |
| `skills/reflect/SKILL.md` | Goals-specific refresh: update `## Goals` section in `index.md` during end-of-session review when `identity/goals.md` has changed |
| `skills/setup/SKILL.md` | Step 3 optional Q5 for goals, Step 5 index generation includes `## Goals` section when goals file exists |

No other files change. No breaking changes.
