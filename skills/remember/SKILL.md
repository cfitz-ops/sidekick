---
name: remember
description: |
  Save context to memory. Triggered by "remember that...", "save this", or /sidekick:remember.
  Determines the right memory space, creates or updates the file, and confirms.
---

> **Memory path:** All `~/.claude/memory/` references below use the memory directory resolved at session start (see orient Step 0). Resolved from `.sidekick/config.yml` or `SIDEKICK_MEMORY_DIR`.

## Step 1 — Parse what to save

Extract the core fact or context from the user's message. Identify:
- The subject (person, project, decision, tool, preference, or knowledge item)
- The relevant details (role, status, rationale, context)
- Whether this is new information or a correction to something already saved

If the request is ambiguous, ask one clarifying question before proceeding.

---

## Step 2 — Determine the memory space

Route to exactly one space using these rules, in order:

| What the user wants to save | Space | Example path |
|-----------------------------|-------|--------------|
| A person — name, role, context, relationship | `relationships/` | `relationships/alice.md` |
| A project or initiative | `projects/` | `projects/my-web-app.md` |
| A tool or platform choice and its rationale | `decisions/` | `decisions/chose-netlify.md` |
| A process or workflow decision | `decisions/` | `decisions/weekly-review.md` |
| Role, background, or a standing preference | `identity/` | `identity/preferences.md` |
| Tribal or institutional knowledge | `knowledge/` | `knowledge/deploy-process.md` |
| A recurring habit, working style, or approach | `patterns/` | `patterns/morning-routine.md` |

When the item could fit two spaces, prefer the more specific one (e.g., a tool choice goes to `decisions/`, not `knowledge/`).

---

## Step 3 — Check for an existing file

Before creating a new file, scan the target space for a relevant existing file:

```bash
ls ~/.claude/memory/{space}/ 2>/dev/null
```

- If a matching file exists: update it — add or revise the relevant section, update the `modified` date in frontmatter.
- If no matching file exists: create a new one using the appropriate template from `templates/`.

---

## Step 4 — Write the file

Use this frontmatter for all new files:

```
---
name: {descriptive-name}
type: {identity | relationship | project | decision | pattern | knowledge}
created: {today's date YYYY-MM-DD}
modified: {today's date YYYY-MM-DD}
status: active
---
```

For updates, keep `created` unchanged. Set `modified` to today's date.

Use the matching template from `templates/` as a guide for content structure:
- `templates/identity.md` — for identity files
- `templates/relationship.md` — for people
- `templates/project.md` — for projects
- `templates/decision.md` — for decisions (include context, options, decision, rationale)
- `templates/pattern.md` — for recurring behaviors
- `templates/knowledge.md` — for tribal/institutional knowledge

Write content that is useful and specific. Avoid vague summaries — include the details that would actually help Claude understand the context later.

**Never save credentials, tokens, API keys, or passwords.** If the user attempts to save any of these, decline and explain why.

---

## Step 5 — Confirm

Output a single confirmation line:

```
Saved: {brief summary} → {path}
```

Examples:
- `Saved: Alice joined the product team as PM → relationships/alice.md`
- `Saved: Chose Netlify over Heroku for my-web-app (cost + DX) → decisions/chose-netlify.md`
- `Saved: Prefer concise responses without preamble → identity/preferences.md`

Do not output the file contents. Do not summarize what you did at length. One line.

---

## Step 6 — Update index.md (significant changes only)

Update `~/.claude/memory/index.md` if the save is significant enough to affect the hot cache:
- A new active project was added
- A new key relationship was established
- An identity-level change occurred (new role, major tool switch, changed working preference)

For minor saves (a detail added to an existing file, a one-off decision), skip the index update.

When updating index.md, revise only the relevant section — do not rewrite the whole file.

---

## Handling "Undo that" / "Forget that"

If the user says "undo that", "forget that", or "revert that":

1. Identify the last file written this session.
2. If the file was newly created: delete it.
3. If the file was updated: restore the previous content (remove the addition, revert the modified date).
4. Confirm: `Reverted: {path}`

If there is nothing to undo this session, say so.

---

## Handling corrections

If the user says "actually..." or corrects something previously saved:

1. Find the relevant file.
2. Update the incorrect information with the corrected version.
3. Update the `modified` date.
4. Confirm: `Updated: {what changed} → {path}`
