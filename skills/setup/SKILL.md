---
name: setup
description: |
  First-run onboarding for Sidekick. Detects existing memory files and migrates them
  into the structured memory space, or runs a short conversational onboarding for new users.
  Use when: user says "setup sidekick", "get started", first install, or no index.md exists.
---

## Step 1 — Scan for existing memory files

Check whether `~/.claude/memory/` exists and contains any `.md` files.

```bash
ls ~/.claude/memory/*.md 2>/dev/null
ls ~/.claude/memory/**/*.md 2>/dev/null
```

Branch on the result:
- **Files found** → go to Step 2 (migrate)
- **Empty or missing** → go to Step 3 (onboarding)

---

## Step 2 — Migrate existing files

For each file found in `~/.claude/memory/`, apply these rules in order:

| If the filename matches… | Move it to… |
|--------------------------|-------------|
| `user_profile*` | `identity/profile.md` |
| `user_tools*` or `*stack*` | `identity/stack.md` |
| `*work_patterns*` or `*preferences*` or `feedback_*` | `identity/preferences.md` |
| `project_*` | `projects/{original-name}.md` |
| `knowledge_*` | `knowledge/{original-name}.md` |
| `MEMORY.md` | Rename to `MEMORY.md.bak` (do not move to a subdirectory) |

**Merge rule:** If two files map to the same destination (e.g., `*work_patterns*` and `feedback_*` both → `identity/preferences.md`), read both, merge content under logical headings, write the merged result to the destination.

**Strip the prefix** from destination filenames: `project_tiger-pace.md` → `projects/tiger-pace.md`, not `projects/project_tiger-pace.md`.

After moving each file, confirm with a one-liner: `Migrated: {source} → {destination}`

Then skip to Step 4.

---

## Step 3 — Conversational onboarding (new users only)

Ask these four questions one at a time. Wait for the answer to each before asking the next. Do not rush or batch them.

1. "What's your role, and what kind of work do you do day-to-day?"
2. "What tools and platforms do you use regularly? (Languages, frameworks, services, editors — whatever's relevant.)"
3. "How do you prefer to work with Claude? For example: concise or detailed, ask clarifying questions or dive straight in, anything else that matters to you."
4. "Anything else Claude should always know about you — context that would be useful in almost every conversation?"

After collecting all answers:

- Write `~/.claude/memory/identity/profile.md` with the answer to Q1. Use the `templates/identity.md` format.
- Write `~/.claude/memory/identity/stack.md` with the answer to Q2. Use the `templates/identity.md` format.
- Write `~/.claude/memory/identity/preferences.md` with answers to Q3 and Q4 combined. Use the `templates/identity.md` format.

Set `name`, `type: identity`, `created`, `modified`, and `status: active` in the YAML frontmatter of each file. Use today's date for `created` and `modified`.

---

## Step 4 — Create space directories

Create all 6 memory space directories if they don't already exist:

```bash
mkdir -p ~/.claude/memory/identity
mkdir -p ~/.claude/memory/relationships
mkdir -p ~/.claude/memory/projects
mkdir -p ~/.claude/memory/decisions
mkdir -p ~/.claude/memory/patterns
mkdir -p ~/.claude/memory/knowledge
```

---

## Step 5 — Generate index.md

Read all `.md` files in `~/.claude/memory/` (all spaces). Generate `~/.claude/memory/index.md` using the structure from `templates/index.md`:

- **Identity section:** Write a 2–3 sentence summary drawn from `identity/profile.md`, `identity/stack.md`, and `identity/preferences.md`.
- **Active Projects table:** One row per file in `projects/` with status `active`. Columns: project name, status, one-line goal.
- **Key People table:** One row per file in `relationships/`. Columns: name, role, context.
- **Preferences section:** Extract the top 3–5 preferences from `identity/preferences.md` as bullet points.
- **Quick Reference section:** Keep the pointer list from the template as-is.

Keep `index.md` under 100 lines. If content is long, summarize — don't paste full file contents.

Write the file to `~/.claude/memory/index.md`.

Confirm: `Generated: ~/.claude/memory/index.md`

---

## Step 6 — Offer git sync (optional)

After index.md is written, ask once:

> "Would you like to set up a private git repo for cross-device sync? This lets you keep memory in sync across machines. You'll need an empty private repo URL ready. (yes / skip)"

**If yes:**
```bash
cd ~/.claude/memory
git init
git add -A
git commit -m "sidekick: initial memory setup"
```
Then prompt: "Paste your private repo URL (e.g., git@github.com:you/memory.git):"
```bash
git remote add origin {url}
git push -u origin main
```
Confirm: `Sync ready. Run /sidekick:sync to push future changes.`

**If no or skip:** Confirm: `Skipped. You can set up sync later by re-running /sidekick:setup.`

---

## Final confirmation

Print a brief summary:
- How many files were migrated (or which identity files were created)
- That `index.md` was generated
- How to use Sidekick going forward: `/sidekick:orient` loads context, `/sidekick:remember` saves things explicitly, `/sidekick:reflect` reviews at session end
