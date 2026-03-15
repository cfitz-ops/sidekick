---
name: setup
description: |
  First-run onboarding for Sidekick. Detects the runtime environment, resolves the memory
  path, and either migrates existing files, clones an existing repo, or runs conversational
  onboarding for new users.
  Use when: user says "setup sidekick", "get started", first install, or no index.md exists.
---

## Step 0 — Detect environment and resolve memory path

Determine where memory should live. Check in order:

1. If `SIDEKICK_MEMORY_DIR` is set, use it as the memory directory.
2. If `CLAUDE_CODE_IS_COWORK=1` (Cowork session):
   - Find the user's mounted folder — look for writable directories under the session mount path that are not system directories (`outputs`, `uploads`, `.claude`, `.local-plugins`, `.skills`).
   - If a mounted folder is found, use `{mounted-folder}/.sidekick-memory/`.
   - If no mounted folder is found, attempt `request_cowork_directory` to prompt the user to select one:
     > "Sidekick needs a folder to persist memory between Cowork sessions. Please select a folder."
   - If no folder is available (user declined or tool unavailable):
     > "Continuing in ephemeral mode — memory will work this session but won't persist between sessions."
     Use `~/.claude/memory/` and note that persistence is not available.
   - Once resolved, persist the path for this session:
     ```bash
     echo "SIDEKICK_MEMORY_DIR={resolved-path}" >> "$CLAUDE_ENV_FILE"
     ```
3. Otherwise (Claude Code), use `~/.claude/memory/`.

Use this resolved path for all subsequent steps. All path references below mean "the resolved memory path" (referred to as `{MEMORY_PATH}`).

See `docs/environment-detection.md` for the full detection reference.

---

## Step 1 — Check for existing memory

Check whether the resolved memory directory exists and contains any `.md` files.

```bash
ls {MEMORY_PATH}/*.md 2>/dev/null
ls {MEMORY_PATH}/**/*.md 2>/dev/null
```

Branch on the result:

- **Files found** → go to Step 2 (migrate existing files)
- **Empty or missing** → ask: "Do you have an existing Sidekick memory repo you'd like to clone? (yes / no)"
  - **Yes** → go to Step 2b (clone existing repo)
  - **No** → go to Step 3 (new user onboarding)

---

## Step 2 — Migrate existing files

For each file found in `{MEMORY_PATH}`, apply these rules in order:

| If the filename matches… | Move it to… |
|--------------------------|-------------|
| `user_profile*` | `identity/profile.md` |
| `user_tools*` or `*stack*` | `identity/stack.md` |
| `*work_patterns*` or `*preferences*` or `feedback_*` | `identity/preferences.md` |
| `project_*` | `projects/{original-name}.md` |
| `knowledge_*` | `knowledge/{original-name}.md` |
| `MEMORY.md` | Rename to `MEMORY.md.bak` (do not move to a subdirectory) |

**Merge rule:** If two files map to the same destination (e.g., `*work_patterns*` and `feedback_*` both → `identity/preferences.md`), read both, merge content under logical headings, write the merged result to the destination.

**Strip the prefix** from destination filenames: `project_my-app.md` → `projects/my-app.md`, not `projects/project_my-app.md`.

After moving each file, confirm with a one-liner: `Migrated: {source} → {destination}`

Then skip to Step 4.

---

## Step 2b — Clone existing memory repo

Ask for the repo URL: "Paste your memory repo URL (e.g., `git@github.com:you/memory.git` or `https://github.com/you/memory.git`):"

Attempt the clone:

```bash
git clone {url} {MEMORY_PATH}
```

**If the clone succeeds:** Confirm what was pulled (`ls {MEMORY_PATH}/`), then skip to Step 4 (create any missing space directories).

**If the clone fails with an authentication error:**

Report the failure clearly, then offer auth options based on the URL type:

For HTTPS URLs:
> Clone failed — authentication required.
>
> **Option 1: Personal access token (PAT)**
> Create a token at https://github.com/settings/tokens with `repo` scope, then provide the URL as:
> `https://{token}@github.com/{user}/{repo}.git`
>
> **Option 2: Switch to SSH**
> Provide an SSH URL instead: `git@github.com:{user}/{repo}.git`
> (Requires SSH keys configured on this machine.)

For SSH URLs:
> Clone failed — SSH key not found or not authorized.
>
> This environment may not have SSH keys configured. Try an HTTPS URL with a personal access token instead:
> `https://{token}@github.com/{user}/{repo}.git`
> Create a token at https://github.com/settings/tokens with `repo` scope.

Wait for the user to provide a corrected URL, then retry the clone. If the second attempt also fails, suggest continuing with new-user onboarding (Step 3) and setting up sync later.

---

## Step 3 — Conversational onboarding (new users only)

Ask these four questions one at a time. Wait for the answer to each before asking the next. Do not rush or batch them.

1. "What's your role, and what kind of work do you do day-to-day?"
2. "What tools and platforms do you use regularly? (Languages, frameworks, services, editors — whatever's relevant.)"
3. "How do you prefer to work with Claude? For example: concise or detailed, ask clarifying questions or dive straight in, anything else that matters to you."
4. "Anything else Claude should always know about you — context that would be useful in almost every conversation?"

After collecting all answers:

- Write `{MEMORY_PATH}/identity/profile.md` with the answer to Q1. Use the `templates/identity.md` format.
- Write `{MEMORY_PATH}/identity/stack.md` with the answer to Q2. Use the `templates/identity.md` format.
- Write `{MEMORY_PATH}/identity/preferences.md` with answers to Q3 and Q4 combined. Use the `templates/identity.md` format.

Set `name`, `type: identity`, `created`, `modified`, and `status: active` in the YAML frontmatter of each file. Use today's date for `created` and `modified`.

---

## Step 4 — Create space directories

Create all 6 memory space directories if they don't already exist:

```bash
mkdir -p {MEMORY_PATH}/identity
mkdir -p {MEMORY_PATH}/relationships
mkdir -p {MEMORY_PATH}/projects
mkdir -p {MEMORY_PATH}/decisions
mkdir -p {MEMORY_PATH}/patterns
mkdir -p {MEMORY_PATH}/knowledge
```

---

## Step 5 — Generate index.md

Read all `.md` files in `{MEMORY_PATH}` (all spaces). Generate `{MEMORY_PATH}/index.md` using the structure from `templates/index.md`:

- **Identity section:** Write a 2–3 sentence summary drawn from `identity/profile.md`, `identity/stack.md`, and `identity/preferences.md`.
- **Active Projects table:** One row per file in `projects/` with status `active`. Columns: project name, status, one-line goal.
- **Key People table:** One row per file in `relationships/`. Columns: name, role, context.
- **Preferences section:** Extract the top 3–5 preferences from `identity/preferences.md` as bullet points.
- **Quick Reference section:** Keep the pointer list from the template as-is.

Keep `index.md` under 100 lines. If content is long, summarize — don't paste full file contents.

Write the file to `{MEMORY_PATH}/index.md`.

Confirm: `Generated: {MEMORY_PATH}/index.md`

---

## Step 6 — Offer git sync (optional)

Check if the memory directory is already a git repo:

```bash
git -C {MEMORY_PATH} rev-parse --is-inside-work-tree 2>/dev/null
```

If already a git repo with a remote configured: skip this step. Sync is already set up (likely from Step 2b clone).

If not a git repo, ask once:

> "Would you like to set up a private git repo for cross-device sync? This lets you keep memory in sync across machines. You'll need an empty private repo URL ready. (yes / skip)"

**If yes:**
```bash
cd {MEMORY_PATH}
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
- How many files were migrated (or which identity files were created, or what was cloned)
- That `index.md` was generated
- How to use Sidekick going forward: `/sidekick:orient` loads context, `/sidekick:remember` saves things explicitly, `/sidekick:reflect` reviews at session end
