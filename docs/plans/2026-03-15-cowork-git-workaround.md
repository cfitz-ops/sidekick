# Cowork Git Workaround Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix git operations in Cowork by never placing `.git/` in the mounted folder — all git ops run in a VM temp path, with content files copied to/from the mounted folder.

**Architecture:** In Cowork, the VirtioFS mounted filesystem does not support `unlink()` on git lock files, making clone/fetch/push fail when targeting the mounted folder directly. The fix: always run git operations in a VM-local temp directory (`/tmp/sidekick-git-work/`), then `cp -r` content files (excluding `.git/`) to/from the mounted `.sidekick/memory/` folder. In Claude Code, git works normally — no temp path needed.

**Tech Stack:** Markdown (skill files), Bash (inline in skills)

**Issues addressed from test log:**
1. 🔴 Git operations fail on Cowork mounted filesystem
2. 🟡 No graceful recovery from partial clone
3. 🟡 PAT onboarding assumes GitHub familiarity
4. 🟡 Classic `repo` scope causes user hesitation
5. 🟡 Prior failed setup state not detected
6. 🟢 Drop `$CLAUDE_ENV_FILE` fallback

---

## File Structure

| File | Action | What changes |
|------|--------|-------------|
| `skills/setup/SKILL.md` | Modify | Step 1 detects orphaned `.git/`, Step 2b clones to temp path and copies content, PAT guide expanded |
| `skills/sync/SKILL.md` | Rewrite | All git ops in temp path for Cowork, copy content to/from mounted folder |
| `skills/orient/SKILL.md` | Modify | Step 0b auto-pull uses temp path in Cowork |
| `docs/environment-detection.md` | Modify | Add Cowork git limitation documentation |

---

## Chunk 1: Setup Skill Fixes

### Task 1: Add orphaned `.git/` detection and PAT guide to setup

**Files:**
- Modify: `skills/setup/SKILL.md`

- [ ] **Step 1: Add orphaned `.git/` detection to Step 1**

After the line `**If `{SIDEKICK_ROOT}` does not exist or has no config:**`, add:

```markdown
**Check for prior failed setup:** If `{SIDEKICK_ROOT}/memory/.git` exists but `{SIDEKICK_ROOT}/config.yml` does not, a previous setup attempt left an incomplete state. Surface:

> "It looks like a previous setup attempt left some files behind. Routing around them — this won't affect your setup."

Do not attempt to delete the orphaned `.git/` directory (it may be on a filesystem that doesn't support deletion of lock files). Proceed with setup normally — the orphaned directory does not interfere with reading or writing `.md` files.
```

- [ ] **Step 2: Rewrite Step 2b with Cowork temp-path clone and expanded PAT guide**

Replace the entire Step 2b with:

```markdown
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
```

- [ ] **Step 3: Update Step 6 git init for Cowork**

In Step 6 (offer git sync), the `git init` flow also needs the Cowork workaround. Replace the git init block with:

```markdown
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

Note in `config.yml`: `git_sync.enabled: true`, `git_sync.remote:` the clean URL.

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

7. Update `config.yml`: set `git_sync.enabled: true` and `git_sync.remote:` to the URL (without the PAT).

Confirm: `Sync ready. Run /sidekick:sync to push future changes.`
```

- [ ] **Step 4: Remove `$CLAUDE_ENV_FILE` reference if any remain**

Search the setup skill for any remaining references to `CLAUDE_ENV_FILE` and remove them. The config.yml approach replaces this entirely.

- [ ] **Step 5: Read through the complete setup skill end-to-end**

Verify the flow for:
1. Cowork + existing repo → PAT guide → temp clone → copy content → config
2. Cowork + new user → onboarding → temp git init → push → config
3. Cowork + orphaned `.git/` → warning → route around → continue
4. Claude Code + existing repo → direct clone (unchanged)
5. Claude Code + new user → direct git init (unchanged)

- [ ] **Step 6: Commit**

```bash
git add skills/setup/SKILL.md
git commit -m "feat: Cowork git workaround, expanded PAT guide, orphaned .git detection"
```

---

## Chunk 2: Sync Skill Rewrite

### Task 2: Rewrite sync skill for Cowork temp-path strategy

The sync skill needs a complete rewrite of its git operations section to handle Cowork's filesystem limitation. In Cowork, all git ops happen in `/tmp/sidekick-git-work/`, with content copied to/from the mounted folder.

**Files:**
- Rewrite: `skills/sync/SKILL.md`

- [ ] **Step 1: Write the complete rewritten sync skill**

```markdown
---
name: sync
description: |
  Sync memory across devices via private git repo. Commits, pulls, and pushes.
  Requires git repo setup during /sidekick:setup (opt-in). Use with /sidekick:sync.
---

> **Memory path:** All `~/.claude/memory/` references below use the memory directory resolved at session start (see orient Step 0). Resolved from `.sidekick/config.yml` or `SIDEKICK_MEMORY_DIR`.

## Step 1 — Check sync is configured

Read `.sidekick/config.yml`. If `git_sync.enabled` is not `true`, stop and tell the user:

```
Git sync is not configured. Run /sidekick:setup to set it up.
```

Read the remote URL from `config.yml`'s `git_sync.remote` and the branch from `git_sync.branch`.

---

## Step 2 — Load credentials

Read the PAT from the credentials file (path from `config.yml`'s `credentials_file`, relative to `.sidekick/`).

If no credentials file exists or PAT is empty:

```
No credentials found. Run /sidekick:setup to configure your GitHub PAT.
```

Construct the authenticated URL: `https://{PAT}@{remote-host}/{remote-path}.git`

---

## Step 3 — Determine git strategy

**If `CLAUDE_CODE_IS_COWORK=1` (Cowork):**

The mounted filesystem does not support git lock files. All git operations must run in a VM-local temp directory. Go to Step 4a (Cowork sync).

**Otherwise (Claude Code):**

Git works directly in the memory directory. Go to Step 4b (direct sync).

---

## Step 4a — Cowork sync (temp-path strategy)

### Pull remote changes

```bash
TEMP_DIR="/tmp/sidekick-git-work"
rm -rf "$TEMP_DIR"
git clone {authenticated-url} "$TEMP_DIR"
```

If clone fails (auth): warn "Sync failed — credentials may be expired. Run `/sidekick:setup` to update your PAT." Stop.

If clone fails (network): warn "Sync failed — no network connection." Stop.

### Merge local changes into the clone

For each `.md` file in `{MEMORY_PATH}` (the mounted folder), compare it against the cloned copy in `$TEMP_DIR`:

- **File exists in both, local is newer** (by `modified` date in frontmatter): copy local version to `$TEMP_DIR`, overwriting the remote version.
- **File exists in both, remote is newer**: copy remote version to `{MEMORY_PATH}`, overwriting the local version.
- **File only exists locally**: copy to `$TEMP_DIR` (new local file).
- **File only exists in remote**: copy to `{MEMORY_PATH}` (new remote file).

### Commit and push

```bash
cd "$TEMP_DIR"
git add -A
```

If there are staged changes:

```bash
git commit -m "sidekick: sync $(date +%Y-%m-%d)"
git push origin {branch}
```

### Copy final state back to mounted folder

```bash
# Copy all content files (not .git/) from temp to mounted folder
rsync -a --exclude='.git' "$TEMP_DIR"/ {MEMORY_PATH}/
```

### Report

```
Sync complete.
  Pulled:  {N} files updated from remote
  Pushed:  {N} files pushed to remote
  (or "Memory is already in sync. No changes.")
```

Clean up:

```bash
rm -rf "$TEMP_DIR"
```

---

## Step 4b — Direct sync (Claude Code)

### Check if memory is a git repo

```bash
git -C {MEMORY_PATH} rev-parse --is-inside-work-tree 2>/dev/null
```

If not a git repo, stop: "Sync requires a git repo. Run `/sidekick:setup` to configure sync."

### Stage all changes

```bash
git -C {MEMORY_PATH} add -A
```

Check if there is anything staged:

```bash
git -C {MEMORY_PATH} diff --cached --name-only
```

If no staged changes, skip to pull.

### Commit

```bash
git -C {MEMORY_PATH} commit -m "sidekick: sync $(date +%Y-%m-%d)"
```

### Pull

```bash
git -C {MEMORY_PATH} pull --rebase origin {branch}
```

If rebase conflict: stop and report conflicting files. Offer "keep mine" / "keep theirs" options. Do not push.

### Push

```bash
git -C {MEMORY_PATH} push origin {branch}
```

If push fails, report error verbatim. Do not force push.

### Report

```
Sync complete.
  Committed: {N} files  (or "Nothing to commit")
  Pulled:    {N} commits from remote  (or "Already up to date")
  Pushed:    {N} commits to remote  (or "Nothing to push")
```
```

- [ ] **Step 2: Commit**

```bash
git add skills/sync/SKILL.md
git commit -m "feat: rewrite sync skill with Cowork temp-path strategy"
```

---

## Chunk 3: Orient Auto-Pull Fix and Documentation

### Task 3: Update orient auto-pull for Cowork

**Files:**
- Modify: `skills/orient/SKILL.md` (Step 0b)

- [ ] **Step 1: Rewrite Step 0b with Cowork awareness**

Replace Step 0b with:

```markdown
## Step 0b — Auto-pull (if configured)

Read `config.yml`. If `git_sync.enabled` is `true` and `git_sync.auto_pull` is `true`:

1. Read the PAT from the credentials file (path from `config.yml`'s `credentials_file`).
2. Construct the authenticated remote URL: `https://{PAT}@{remote-host}/{remote-path}.git`

**If `CLAUDE_CODE_IS_COWORK=1` (Cowork):**

Clone to a temp directory and copy updated content to the mounted folder:

```bash
TEMP_DIR="/tmp/sidekick-git-work"
rm -rf "$TEMP_DIR"
git clone {authenticated-url} "$TEMP_DIR"
```

If clone succeeds: copy content files (not `.git/`) from temp to `{MEMORY_PATH}`:

```bash
rsync -a --exclude='.git' "$TEMP_DIR"/ {MEMORY_PATH}/
rm -rf "$TEMP_DIR"
```

**Otherwise (Claude Code):**

Pull directly:

```bash
git -C {MEMORY_PATH} pull --rebase origin {branch}
```

**Error handling (both environments):**

- If pull/clone fails (auth error): warn "Auto-pull failed — credentials may be expired. Run `/sidekick:setup` to update your PAT." Continue with local files.
- If pull/clone fails (network): warn "Auto-pull failed — no network connection. Using local files." Continue.
```

- [ ] **Step 2: Remove any remaining `$CLAUDE_ENV_FILE` references from orient**

Search the orient skill for `CLAUDE_ENV_FILE` and remove any references.

- [ ] **Step 3: Commit**

```bash
git add skills/orient/SKILL.md
git commit -m "feat: update orient auto-pull with Cowork temp-path strategy"
```

---

### Task 4: Update environment detection docs

**Files:**
- Modify: `docs/environment-detection.md`

- [ ] **Step 1: Add Cowork git limitation section**

Add after the "Cowork Folder Resolution" section:

```markdown
## Cowork Git Limitation

The Cowork mounted filesystem (VirtioFS) does not support `unlink()` on git lock files. This means `git clone`, `git fetch`, `git pull`, and `git push` all fail when targeting the mounted folder directly.

**Workaround:** All git operations must run in a VM-local temp directory (`/tmp/sidekick-git-work/`). Content files (`.md` only, not `.git/`) are then copied to/from the mounted `.sidekick/memory/` folder.

This affects:
- `/sidekick:setup` Step 2b (clone) and Step 6 (git init)
- `/sidekick:sync` (all git operations)
- `/sidekick:orient` Step 0b (auto-pull)

In Claude Code, git works directly in the memory directory — no workaround needed.
```

- [ ] **Step 2: Remove `$CLAUDE_ENV_FILE` section from environment detection**

The "Setting SIDEKICK_MEMORY_DIR via CLAUDE_ENV_FILE" section is no longer accurate. Remove it entirely.

- [ ] **Step 3: Commit**

```bash
git add docs/environment-detection.md
git commit -m "docs: add Cowork git limitation and remove CLAUDE_ENV_FILE reference"
```

---

### Task 5: Move test log to docs and clean up

**Files:**
- Move: `sidekick-setup-log-2026-03-15-session2 copy.md` → `docs/2026-03-15-cowork-setup-log-v3.md`

- [ ] **Step 1: Move the file**

```bash
mv "sidekick-setup-log-2026-03-15-session2 copy.md" docs/2026-03-15-cowork-setup-log-v3.md
```

- [ ] **Step 2: Commit**

```bash
git add "docs/2026-03-15-cowork-setup-log-v3.md"
git commit -m "chore: move session 2 test log to docs/"
```

---

## Execution Notes

- All work on feature branch `feature/cowork-git-workaround`, merged via PR.
- The temp-path strategy (`/tmp/sidekick-git-work/`) is VM-local and ephemeral — it's cleaned up after each operation. No persistent state lives there.
- In Claude Code, nothing changes — all git operations remain direct. The Cowork branch only activates when `CLAUDE_CODE_IS_COWORK=1`.
- The sync skill's Cowork merge strategy uses frontmatter `modified` dates to resolve conflicts. This is simpler than full git merge but sufficient for single-user memory files.
- After implementation, test in Cowork: (1) fresh setup with clone, (2) sync push, (3) sync pull, (4) auto-pull on orient. Also test Claude Code regression.
