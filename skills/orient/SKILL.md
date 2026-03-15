---
name: orient
description: |
  Loads personal context at session start. Reads the memory index and orients Claude
  on who the user is, their active projects, preferences, and key relationships.
  Auto-triggered via SessionStart hook. Can also be invoked manually with /sidekick:orient.
---

## Step 0 — Resolve memory path

Determine the memory directory for this session. Check in order:

1. If `SIDEKICK_MEMORY_DIR` is set, use it. Skip to Step 1.
2. If `CLAUDE_CODE_IS_COWORK=1` (Cowork session):
   a. Find the user's mounted folder — look for writable directories under the session mount path that are not system directories (`outputs`, `uploads`, `.claude`, `.local-plugins`, `.skills`).
   b. If a mounted folder is found, use `{mounted-folder}/.sidekick-memory/` as the memory path.
   c. If no mounted folder is found, attempt `request_cowork_directory` to prompt the user to select one.
   d. If no folder is available (user declined or tool unavailable), fall back to `~/.claude/memory/` and warn:
      > "Running in ephemeral mode — memory will work this session but won't persist. Select a folder in Cowork to enable persistence."
   e. Once resolved, persist the path for this session:
      ```bash
      echo "SIDEKICK_MEMORY_DIR={resolved-path}" >> "$CLAUDE_ENV_FILE"
      ```
3. Otherwise (Claude Code), use `~/.claude/memory/`.

All `~/.claude/memory/` references in Sidekick skills refer to this resolved path for the rest of the session.

See `docs/environment-detection.md` for the full detection reference.

---

## Step 1 — Load the memory index

Read `~/.claude/memory/index.md` (using the resolved memory path).

If the file does not exist: tell the user "No memory found. Run `/sidekick:setup` to get started." Then stop — do not proceed further.

If the file exists: internalize its contents as session context. Do not display or quote the file to the user. Do not announce that you read it. Simply use it — you now know who this person is, what they're working on, what they prefer, and who matters to them.

---

## Step 1.5 — Check for workspace-scoped plugins

Check for `CLAUDE.md` and `./memory/` in the current working directory. If present, another plugin (e.g., Anthropic's productivity plugin) may manage workspace-specific context — people nicknames, acronyms, project codenames, and task tracking. Sidekick should not duplicate that context. Defer shorthand decoding and task management to the workspace plugin. Sidekick owns personal identity, cross-workspace relationships, decisions, and patterns.

---

## Step 2 — Progressive disclosure

Do not bulk-read all memory files at session start. The index is sufficient context for most conversations.

Read deeper files **only when the current conversation makes them relevant:**

- User mentions a person by name → read `relationships/{person-name}.md`
- User asks about a specific project → read `projects/{project-name}.md`
- User references a past decision → read `decisions/{decision-name}.md`
- User asks "what do I know about X" → run `/sidekick:recall`

When you read a deeper file, internalize its contents silently. Do not announce the read unless the user asked you to look something up.

---

## Step 3 — Proactive capture (active throughout the session)

These rules are now active. Apply them continuously from this point forward.

### What to capture automatically

- **New people:** Any person mentioned with enough context to be useful — name, role, relationship to the user, why they matter. Write to `relationships/{person-name}.md`.
- **New projects:** Any new initiative, product, or effort the user discusses substantively. Write to `projects/{project-name}.md`.
- **Decisions:** Any choice made with reasoning — what was decided, what the alternatives were, why this option won. Write to `decisions/{decision-name}.md`.
- **Tool or platform choices:** Any new tool adopted or rejected and why. Write to either `decisions/` (if a deliberate choice) or `identity/stack.md` (if it's now part of their standard stack).
- **Corrections:** If the user contradicts something in memory ("actually, Alice moved to product"), update the relevant file immediately.

### What NOT to capture

- Ephemeral task details — one-off debugging output, temporary file paths, scratch notes
- Anything already in memory — no duplicates, no re-saves of existing content
- Sensitive data — credentials, tokens, passwords, API keys. Never. Under any circumstances.
- Uncommitted brainstorming — ideas the user is thinking through aloud but hasn't decided on
- Workspace-scoped shorthand — acronyms, codenames, or nicknames that a workspace plugin already tracks (see Step 1.5)

### Capture behavior

- **Save immediately** when you recognize something capturable. Do not wait for the session to end.
- **Confirm with a one-liner:** `Saved: {brief summary} → {path}` — e.g., `Saved: Alice moved to product team → relationships/alice.md`
- **No confirmation prompt before saving.** Asking "should I save this?" interrupts the flow. Save it. If the user wants to undo, they'll say "undo that" or "forget that" — revert the last save.
- **Batch surfacing:** If you make 3 or more captures in a single session, surface them together at the next natural pause (e.g., end of a topic, before a new question) rather than announcing each one individually.
- **Err toward less.** When in doubt, don't capture. The `/sidekick:reflect` skill at session end is designed to catch what was missed. Proactive capture is for clear, high-confidence signals — not speculation.

### File format for captures

All files use YAML frontmatter. When creating a new file:

```
---
name: {descriptive-name}
type: {identity | relationship | project | decision | pattern | knowledge}
created: {today's date YYYY-MM-DD}
modified: {today's date YYYY-MM-DD}
status: active
---
```

Use the appropriate template from `templates/` as a guide for content structure.

When updating an existing file, update the `modified` date in the frontmatter.

### When to update index.md

Update `~/.claude/memory/index.md` when a capture is significant enough to affect the hot cache:
- A new active project was added
- A new key relationship was established
- An identity-level change occurred (new role, major tool switch, changed preference)

For minor updates (a note added to an existing relationship, a decision filed), skip the index update — `/sidekick:reflect` handles periodic index refresh.
