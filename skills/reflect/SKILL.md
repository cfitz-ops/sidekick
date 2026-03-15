---
name: reflect
description: |
  End-of-session memory review. Scans the conversation for context worth capturing,
  proposes saves as a batch, and flags stale memory files. Triggered by session end
  hook, "let's wrap up", or /sidekick:reflect.
---

## Step 1 — Scan the conversation for capturable context

Review the full conversation. Look for these signals:

- **New people:** Anyone mentioned by name with a role, relationship, or notable context not already in memory
- **New projects or initiatives:** Any new effort, product, or goal discussed substantively
- **Decisions made:** Any choice with a rationale — what was decided, what alternatives existed, why this option won
- **Tool or platform choices:** Anything newly adopted, rejected, or switched
- **Corrections:** Anything the user said that contradicts existing memory
- **Patterns and preferences revealed:** Working style, communication preferences, recurring approaches

For each candidate, ask: "Would this be useful context in a future conversation?" If the answer is "probably not" or "maybe", skip it.

**Err toward less, not more.** 2–4 captures per session is typical. Do not propose every detail discussed — only what has lasting value.

Do not propose:
- Ephemeral task details (one-off debugging, temp file paths, scratch notes)
- Anything already in memory
- Sensitive data (credentials, tokens, passwords, API keys — never)
- Uncommitted brainstorming the user was thinking through aloud but didn't decide on
- Generic observations that aren't specific to this user

---

## Step 2 — Present the proposed batch

If there is nothing worth capturing, say: "Nothing new to save from this session." Then proceed to Step 4 (stale check).

If there are captures to propose, present them as a numbered list. For each item, show:

```
1. {What} → {path}
   "{one-sentence summary of what would be saved}"
```

Example:

```
Here's what I'd save from this session:

1. Bob Chen → relationships/bob-chen.md
   "Head of engineering at Acme Corp; working with you on the my-web-app integration"

2. Chose Postgres over MySQL → decisions/chose-postgres.md
   "Selected Postgres for my-web-app DB; cited branching workflow and free tier"

3. Prefer async code review over sync pairing → patterns/code-review.md
   "You mentioned preferring written async feedback over live pairing sessions"

Save all, pick some, or skip? (e.g., "all", "1 3", "skip", or edit a specific item)
```

Wait for the user's response before writing anything.

---

## Step 3 — Write approved saves

Process the user's response:

- `"all"` → write every proposed item
- `"1 3"` or `"1, 3"` → write only the numbered items
- `"skip"` or `"none"` → write nothing, proceed to Step 4
- An edit to a specific item (e.g., "for #2, the reason was actually cost, not branching") → apply the correction, then write

For each approved item, use the same file logic as the remember skill:

1. Check for an existing file in the target space.
2. If exists: update it, revise the modified date.
3. If not: create a new file using the appropriate template from `templates/`.

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

Confirm each write with a one-liner: `Saved: {summary} → {path}`

After all saves are complete, update `~/.claude/memory/index.md` if any of the saves are significant (new project, new key relationship, identity-level change). Revise only the affected sections.

---

## Step 4 — Stale memory check

Scan all `.md` files in `~/.claude/memory/` (all spaces, excluding `index.md`):

```bash
find ~/.claude/memory -name "*.md" -not -name "index.md" 2>/dev/null
```

For each file, read the `modified` date from the YAML frontmatter. Flag any file where the modified date is 30 or more days before today.

If no stale files exist: skip this step silently.

If stale files exist, list them:

```
Stale memory (not updated in 30+ days):
- projects/old-initiative.md (last modified: 2025-12-01)
- relationships/alex.md (last modified: 2025-11-15)

Archive any of these? Archiving sets status to "archived" so they're excluded from future context loads. (e.g., "archive 1", "archive all", or "skip")
```

Wait for the user's response:

- `"archive 1"` or `"archive projects/old-initiative.md"` → open that file, set `status: archived` in the frontmatter, update `modified` date. Confirm: `Archived: {path}`
- `"archive all"` → archive every listed file
- `"skip"` or no response → leave files as-is

Do not delete stale files. Only set `status: archived`.

---

## Step 5 — Wrap up

After saves and stale check are complete, output a brief summary:

- How many items were saved (if any)
- How many files were archived (if any)
- One line if nothing changed: "Memory up to date."

Keep the summary under 4 lines. Do not recite what was saved — the confirmation lines from Step 3 already covered that.
