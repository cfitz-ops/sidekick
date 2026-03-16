---
name: setup
description: |
  First-run onboarding for Sidekick. Detects the runtime environment, creates the
  .sidekick/ directory structure with config and credential safety, and either clones
  an existing memory repo, migrates legacy files, or runs conversational onboarding.
  Use when: user says "setup sidekick", "setup memory", "sidekick get started", or no .sidekick/config.yml found.
---

## Step 0 — Detect environment and resolve .sidekick/ location

Determine where `.sidekick/` should live. Check in order:

1. If `SIDEKICK_MEMORY_DIR` is set, use its parent as the `.sidekick/` root (memory lives at `{SIDEKICK_MEMORY_DIR}` directly — skip config setup, this is a custom override).
2. If `CLAUDE_CODE_IS_COWORK=1` (Cowork session):
   - Look for `.sidekick/config.yml` in the current working directory. If found, use it — setup is already complete. Run `/sidekick:orient` instead.
   - If not found, check for a user-mounted folder (writable directories under the session mount path, excluding system dirs: `outputs`, `uploads`, `.claude`, `.local-plugins`, `.skills`).
   - If no mounted folder, use `request_cowork_directory` to prompt folder selection:
     > "Sidekick needs a folder to persist memory between Cowork sessions. Select a folder (or create one like `~/claude-workspace/`)."
   - If no folder available (user declined or tool unavailable):
     > "Continuing in ephemeral mode — memory will work this session but won't persist."
     Use `~/.claude/.sidekick/` as the root.
3. Otherwise (Claude Code), use `~/.claude/.sidekick/`.

The resolved root is referred to as `{SIDEKICK_ROOT}` below. Memory will live at `{SIDEKICK_ROOT}/memory/`.

---

## Step 1 — Check for existing state

Check what exists at the resolved root:

**If `{SIDEKICK_ROOT}/config.yml` exists:** Setup was already completed. Tell the user and offer to re-run onboarding or reconfigure git sync. Do not overwrite existing files without confirmation.

**Check for prior failed setup:** If `{SIDEKICK_ROOT}/memory/.git` exists but `{SIDEKICK_ROOT}/config.yml` does not, a previous setup attempt left an incomplete state. Surface:

> "It looks like a previous setup attempt left some files behind. Routing around them — this won't affect your setup."

Do not attempt to delete the orphaned `.git/` directory (it may be on a filesystem that doesn't support deletion of lock files). Proceed with setup normally — the orphaned directory does not interfere with reading or writing `.md` files.

**If `{SIDEKICK_ROOT}` does not exist or has no config:**

Check for legacy memory files that need migration:
- `~/.claude/memory/*.md` or `~/.claude/memory/**/*.md` (Claude Code legacy)
- `{mounted-folder}/.sidekick-memory/**/*.md` (v0.2.0 Cowork layout)

Branch:
- **Legacy files found** → go to Step 2 (migrate)
- **No files found** → ask: "Do you have an existing Sidekick memory repo you'd like to clone? (yes / no)"
  - **Yes** → go to Step 2b (clone existing repo)
  - **No** → go to Step 3 (new user onboarding)

---

## Step 2 — Migrate legacy files

Create the new directory structure first (Step 4), then move files:

- From `~/.claude/memory/{space}/` → `{SIDEKICK_ROOT}/memory/{space}/`
- From `~/.claude/memory/index.md` → `{SIDEKICK_ROOT}/memory/index.md`
- From `.sidekick-memory/` → `{SIDEKICK_ROOT}/memory/` (v0.2.0 layout)

Apply the same migration rules as before for unstructured files (user_profile* → identity/profile.md, etc.).

After migration, confirm with a one-liner per file: `Migrated: {source} → {destination}`

Then skip to Step 4 (which creates any missing directories and the config).

---

## Step 2b — Clone existing memory repo

Ask for the repo URL: "Paste your memory repo URL (e.g., `https://github.com/you/memory.git`):"

**Ask for a GitHub PAT with inline guidance:**

> "To clone a private repo, I need a GitHub Personal Access Token (PAT). Here's how to create one:
>
> 1. Go to https://github.com/settings/tokens?type=beta (fine-grained tokens)
> 2. Click **Generate new token**
> 3. Name it something like `sidekick-memory`
> 4. Under **Repository access**, select **Only select repositories** and pick your memory repo
> 5. Under **Permissions → Repository permissions**, set **Contents** to **Read and write**
> 6. Click **Generate token** and paste it here
>
> The token starts with `github_pat_`. It will be stored locally in a gitignored file — never committed."

**Important: Create the safety files BEFORE storing the PAT.**

1. Create `{SIDEKICK_ROOT}/` directory
2. Write `{SIDEKICK_ROOT}/.gitignore` from `templates/gitignore`
3. Store the PAT in `{SIDEKICK_ROOT}/credentials`:
   ```
   github_pat={the-token}
   ```
4. Construct the authenticated URL: `https://{PAT}@github.com/{user}/{repo}.git`

**Clone — environment-aware:**

**If `CLAUDE_CODE_IS_COWORK=1` (Cowork):**

Clone to a VM-local temp directory, then copy content files to the mounted folder:

```bash
TEMP_DIR="/tmp/sidekick-git-work"
rm -rf "$TEMP_DIR"
git clone {authenticated-url} "$TEMP_DIR"
```

If clone succeeds, copy only content files (not `.git/`) to the mounted memory path:

```bash
mkdir -p {SIDEKICK_ROOT}/memory
cp -r "$TEMP_DIR"/* "$TEMP_DIR"/.* {SIDEKICK_ROOT}/memory/ 2>/dev/null
rm -rf {SIDEKICK_ROOT}/memory/.git
```

If clone fails, report the error and offer to retry with a different URL or token, or continue with new-user onboarding (Step 3).

**Otherwise (Claude Code):**

Clone directly into the memory directory:

```bash
git clone {authenticated-url} {SIDEKICK_ROOT}/memory
```

If clone fails, report the error and offer to retry or continue with Step 3.

**After successful clone:** Confirm what was pulled (`ls {SIDEKICK_ROOT}/memory/`), then continue to Step 4.

---

## Step 3 — Conversational onboarding (new users only)

Ask these four questions one at a time. Wait for the answer to each before asking the next.

1. "What's your role, and what kind of work do you do day-to-day?"
2. "What tools and platforms do you use regularly?"
3. "How do you prefer to work with Claude?"
4. "Anything else Claude should always know about you?"

After collecting all answers:

- Write `{SIDEKICK_ROOT}/memory/identity/profile.md` with Q1
- Write `{SIDEKICK_ROOT}/memory/identity/stack.md` with Q2
- Write `{SIDEKICK_ROOT}/memory/identity/preferences.md` with Q3 + Q4

Use the `templates/identity.md` format with YAML frontmatter.

---

## Step 4 — Create directory structure and config

Create the full `.sidekick/` structure:

```bash
mkdir -p {SIDEKICK_ROOT}/memory/identity
mkdir -p {SIDEKICK_ROOT}/memory/relationships
mkdir -p {SIDEKICK_ROOT}/memory/projects
mkdir -p {SIDEKICK_ROOT}/memory/decisions
mkdir -p {SIDEKICK_ROOT}/memory/patterns
mkdir -p {SIDEKICK_ROOT}/memory/knowledge
mkdir -p {SIDEKICK_ROOT}/hooks
```

**Write `.gitignore` (if not already created in Step 2b):**

Copy from `templates/gitignore` to `{SIDEKICK_ROOT}/.gitignore`.

**Write `config.yml`:**

Copy from `templates/config.yml` to `{SIDEKICK_ROOT}/config.yml`. If git sync was set up (Step 2b clone or user opted in), populate the `git_sync` section with the remote URL and set `enabled: true`.

**Install pre-commit hook:**

Copy `templates/pre-commit` to `{SIDEKICK_ROOT}/hooks/pre-commit` and make it executable:

```bash
cp templates/pre-commit {SIDEKICK_ROOT}/hooks/pre-commit
chmod +x {SIDEKICK_ROOT}/hooks/pre-commit
```

If the memory directory is a git repo, also install as the actual git hook:

```bash
if [ -d "{SIDEKICK_ROOT}/memory/.git" ]; then
  cp {SIDEKICK_ROOT}/hooks/pre-commit {SIDEKICK_ROOT}/memory/.git/hooks/pre-commit
fi
```

---

## Step 5 — Generate index.md

Read all `.md` files in `{SIDEKICK_ROOT}/memory/` (all spaces). Generate `{SIDEKICK_ROOT}/memory/index.md` using the structure from `templates/index.md`.

Keep `index.md` under 100 lines.

Confirm: `Generated: {SIDEKICK_ROOT}/memory/index.md`

---

## Step 6 — Offer git sync (if not already configured)

If memory is already a git repo with a remote (from Step 2b): skip this step.

Otherwise, ask once:

> "Would you like to set up git sync for cross-device memory? (yes / skip)"

**If yes:**

1. Ask for the remote URL
2. Ask for a GitHub PAT (if not already stored in Step 2b) — use the same inline guide from Step 2b
3. Write safety files first (`.gitignore`, then `credentials`)

**If `CLAUDE_CODE_IS_COWORK=1` (Cowork):**

Git cannot run in the mounted folder. Initialize in a temp directory, push, then leave the content files in the mounted folder (no `.git/` dir):

```bash
TEMP_DIR="/tmp/sidekick-git-work"
rm -rf "$TEMP_DIR"
cp -r {SIDEKICK_ROOT}/memory "$TEMP_DIR"
cd "$TEMP_DIR"
git init
git add -A
git commit -m "sidekick: initial memory setup"
git remote add origin {authenticated-url}
git push -u origin main
```

**Otherwise (Claude Code):**

Initialize directly:

```bash
cd {SIDEKICK_ROOT}/memory
git init
git add -A
git commit -m "sidekick: initial memory setup"
git remote add origin {authenticated-url}
git push -u origin main
```

Install the pre-commit hook:

```bash
cp {SIDEKICK_ROOT}/hooks/pre-commit {SIDEKICK_ROOT}/memory/.git/hooks/pre-commit
```

7. Update `config.yml`: set `git_sync.enabled: true` and `git_sync.remote:` to the URL (without the PAT — just `https://github.com/user/repo`).

Confirm: `Sync ready. Run /sidekick:sync to push future changes.`

**If skip:** Confirm: `Skipped. Re-run /sidekick:setup to add sync later.`

---

## Final confirmation

Print a brief summary:
- Environment detected (Cowork or Claude Code)
- Where `.sidekick/` was created
- How many files were migrated/created/cloned
- Whether git sync is configured
- Credential safety: `.gitignore` and pre-commit hook installed
- Next steps: `/sidekick:orient` loads context, `/sidekick:remember` saves, `/sidekick:reflect` reviews at session end
- If Cowork: remind to always open Cowork with this folder selected
