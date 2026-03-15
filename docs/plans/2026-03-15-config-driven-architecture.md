# Config-Driven Architecture Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `CLAUDE_ENV_FILE`-based persistence (which doesn't work in Cowork) with a config file approach. Sidekick stores its config, credentials, and memory in a `.sidekick/` directory inside the user's workspace folder, with credential safety guards.

**Architecture:** In Cowork, `.sidekick/` lives inside the user's mounted folder and persists via VirtioFS. In Claude Code, `.sidekick/` lives at `~/.claude/.sidekick/` (wrapping the existing `~/.claude/memory/` location). A `config.yml` stores non-secret settings (git remote, auto-pull preference). A `credentials` file stores the PAT (gitignored). A pre-commit hook and `.gitignore` prevent accidental credential commits.

**Tech Stack:** Markdown (skill files), YAML (config), Bash (hooks, pre-commit hook)

**What this replaces from v0.2.0:**
- `CLAUDE_ENV_FILE` persistence (broken — env var not available in Cowork)
- `.sidekick-memory/` directory name → `.sidekick/memory/`
- Manual PAT entry each session → stored credentials file
- Manual `/sidekick:sync` → auto-pull on session start (configurable)

---

## File Structure

After this implementation, Sidekick's workspace directory looks like:

```
.sidekick/
├── config.yml          # Non-secret settings (git remote, preferences)
├── credentials         # PAT for git auth (gitignored, never committed)
├── .gitignore          # Ignores credentials file
├── hooks/
│   └── pre-commit      # Scans for PAT patterns, blocks if found
└── memory/
    ├── index.md
    ├── identity/
    ├── relationships/
    ├── projects/
    ├── decisions/
    ├── patterns/
    └── knowledge/
```

Files being modified or created in this plan:

| File | Action | Purpose |
|------|--------|---------|
| `docs/environment-detection.md` | Rewrite | Update detection reference for config-driven approach |
| `skills/setup/SKILL.md` | Rewrite | Config file creation, credential storage, `.gitignore` and pre-commit hook |
| `skills/orient/SKILL.md` | Modify | Read config.yml instead of CLAUDE_ENV_FILE, auto-pull |
| `skills/sync/SKILL.md` | Modify | Use stored credentials for auth |
| `skills/reflect/SKILL.md` | Modify | Offer push at session end |
| `hooks/scripts/session-orient.sh` | Modify | Read config.yml for memory path |
| `hooks/scripts/session-reflect.sh` | No change | Already works (relies on SIDEKICK_MEMORY_DIR) |
| `templates/config.yml` | Create | Default config template |
| `templates/gitignore` | Create | .gitignore template for .sidekick/ |
| `templates/pre-commit` | Create | Pre-commit hook that blocks credential leaks |

---

## Chunk 1: Config File Infrastructure and Credential Safety

### Task 1: Create config and safety templates

**Files:**
- Create: `templates/config.yml`
- Create: `templates/gitignore`
- Create: `templates/pre-commit`

- [ ] **Step 1: Write the config template**

```yaml
# .sidekick/config.yml
# Non-secret Sidekick configuration. Safe to commit to git.
version: 1
environment: auto  # auto | cowork | claude-code

memory_path: memory/  # Relative to .sidekick/

git_sync:
  enabled: false
  remote: ""
  branch: main
  auto_pull: true    # Pull on session start
  auto_push: false   # Require explicit /sidekick:sync or offer at reflect

credentials_file: credentials  # Relative to .sidekick/, must be gitignored
```

Write to `templates/config.yml`.

- [ ] **Step 2: Write the .gitignore template**

```
# Sidekick credentials — never commit
credentials
```

Write to `templates/gitignore`.

- [ ] **Step 3: Write the pre-commit hook template**

```bash
#!/bin/bash
# Pre-commit hook: block commits containing GitHub PAT patterns
# Install: cp to .sidekick/hooks/pre-commit && chmod +x

STAGED=$(git diff --cached --name-only)

if [ -z "$STAGED" ]; then
  exit 0
fi

# Check staged file contents for PAT patterns
if git diff --cached -S'ghp_' --name-only | grep -q .; then
  echo "ERROR: Staged files contain a GitHub personal access token (ghp_)."
  echo "Remove the token before committing."
  exit 1
fi

if git diff --cached -S'github_pat_' --name-only | grep -q .; then
  echo "ERROR: Staged files contain a GitHub personal access token (github_pat_)."
  echo "Remove the token before committing."
  exit 1
fi

# Also check if the credentials file itself is staged
if echo "$STAGED" | grep -q "credentials"; then
  echo "ERROR: The credentials file is staged for commit."
  echo "This file should be in .gitignore. Run: git reset HEAD credentials"
  exit 1
fi

exit 0
```

Write to `templates/pre-commit`.

- [ ] **Step 4: Commit**

```bash
git add templates/config.yml templates/gitignore templates/pre-commit
git commit -m "feat: add config, gitignore, and pre-commit hook templates"
```

---

### Task 2: Update environment detection reference

Replace the `CLAUDE_ENV_FILE` approach with config-driven detection.

**Files:**
- Rewrite: `docs/environment-detection.md`

- [ ] **Step 1: Rewrite the detection reference**

```markdown
# Environment Detection

Sidekick runs in two environments with different persistence models.

## Detection Logic

Check in this order:

1. **Explicit override:** If `SIDEKICK_MEMORY_DIR` is set, use it. No further detection needed.
2. **Config file:** If `.sidekick/config.yml` exists in the current working directory (or a parent), read it and use `memory_path` relative to the `.sidekick/` directory.
3. **Cowork detection:** If `CLAUDE_CODE_IS_COWORK=1`, this is a Cowork session. Find the user's mounted folder and look for `.sidekick/` there. If not found, run setup.
4. **Default (Claude Code):** Check `~/.claude/.sidekick/config.yml`. If not found, fall back to `~/.claude/memory/` for backward compatibility.

## Memory Path by Environment

| Environment | .sidekick/ location | Memory path | Persistence |
|-------------|---------------------|-------------|-------------|
| Claude Code (new) | `~/.claude/.sidekick/` | `~/.claude/.sidekick/memory/` | Native |
| Claude Code (legacy) | n/a | `~/.claude/memory/` | Native (migrated on next setup) |
| Cowork (folder mounted) | `{mounted-folder}/.sidekick/` | `{mounted-folder}/.sidekick/memory/` | VirtioFS |
| Cowork (no folder) | ephemeral | `~/.claude/.sidekick/memory/` | Lost between sessions |
| Custom (`SIDEKICK_MEMORY_DIR`) | n/a | Whatever the user set | User-managed |

## Config File

`.sidekick/config.yml` stores non-secret settings that persist between sessions:

- Git remote URL and sync preferences
- Environment hint (auto-detected or explicit)
- Memory path (relative to `.sidekick/`)

The config file is safe to commit to git. Credentials are stored separately in `.sidekick/credentials` which is gitignored.

## Credential Safety

Multiple layers prevent accidental PAT exposure:

1. **`.sidekick/.gitignore`** — excludes the `credentials` file from git tracking
2. **Setup writes `.gitignore` before `credentials`** — if setup fails between the two, no credentials file exists
3. **Pre-commit hook** — installed at `.sidekick/hooks/pre-commit`, scans staged files for PAT patterns (`ghp_`, `github_pat_`) and blocks the commit
4. **GitHub push protection** — GitHub scans pushes for leaked tokens on public repos

## Cowork Folder Resolution

In Cowork, the user's selected folder is mounted via VirtioFS at `/sessions/<session-name>/mnt/<folder-name>/`. The folder name varies per session.

**To find `.sidekick/` in a skill:**

1. Check the current working directory for `.sidekick/config.yml`.
2. If not found, look for writable directories under the session mount path (excluding system dirs: `outputs`, `uploads`, `.claude`, `.local-plugins`, `.skills`) and check each for `.sidekick/config.yml`.
3. If not found, use `request_cowork_directory` (if available) to prompt folder selection, then run `/sidekick:setup`.
4. If no folder available, warn about ephemeral mode.

**In a bash hook:**

Hooks cannot search for `.sidekick/` dynamically. They check `SIDEKICK_MEMORY_DIR` first, then look for `.sidekick/config.yml` relative to common locations. If neither works, prompt the user to run `/sidekick:orient`.

## Skills That Need Detection

Only entry-point skills need full detection:
- **setup** — creates `.sidekick/` directory structure
- **orient** — reads config, runs auto-pull, loads memory

All other skills inherit the resolved path from orient's session context.
```

- [ ] **Step 2: Commit**

```bash
git add docs/environment-detection.md
git commit -m "docs: rewrite environment detection for config-driven architecture"
```

---

## Chunk 2: Setup Skill Rewrite

### Task 3: Rewrite setup skill for config-driven architecture

The setup skill creates the `.sidekick/` directory structure, writes the config file, handles credentials, and installs the pre-commit hook.

**Files:**
- Rewrite: `skills/setup/SKILL.md`

- [ ] **Step 1: Write the complete rewritten setup skill**

Write the following to `skills/setup/SKILL.md`:

```markdown
---
name: setup
description: |
  First-run onboarding for Sidekick. Detects the runtime environment, creates the
  .sidekick/ directory structure with config and credential safety, and either clones
  an existing memory repo, migrates legacy files, or runs conversational onboarding.
  Use when: user says "setup sidekick", "get started", first install, or no config found.
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

**Before cloning, ask for a GitHub PAT:**

> "To clone a private repo in this environment, I need a GitHub Personal Access Token."
> "Create one at https://github.com/settings/tokens with `repo` scope."
> "Paste the token (it starts with `ghp_` or `github_pat_`):"

**Important: Create the safety files BEFORE storing the PAT.**

1. Create `{SIDEKICK_ROOT}/` directory
2. Write `{SIDEKICK_ROOT}/.gitignore` from `templates/gitignore`
3. Store the PAT in `{SIDEKICK_ROOT}/credentials`:
   ```
   github_pat={the-token}
   ```
4. Construct the authenticated URL: `https://{PAT}@github.com/{user}/{repo}.git`
5. Clone into the memory subdirectory:
   ```bash
   git clone {authenticated-url} {SIDEKICK_ROOT}/memory
   ```

**If the clone succeeds:** Confirm what was pulled, then continue to Step 4.

**If the clone fails:** Report the error clearly. Offer to retry with a different URL or token, or continue with new-user onboarding (Step 3).

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
2. Ask for a GitHub PAT (if not already stored in Step 2b)
3. Write safety files first (`.gitignore`, then `credentials`)
4. Initialize the git repo in `{SIDEKICK_ROOT}/memory/`:
   ```bash
   cd {SIDEKICK_ROOT}/memory
   git init
   git add -A
   git commit -m "sidekick: initial memory setup"
   ```
5. Add the remote and push:
   ```bash
   git remote add origin {authenticated-url}
   git push -u origin main
   ```
6. Install the pre-commit hook:
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
```

- [ ] **Step 2: Read through the skill end-to-end and verify all paths**

Verify flow for each entry path:
1. Legacy Claude Code files → migrate → create structure → index → offer sync
2. Legacy v0.2.0 Cowork files → migrate → create structure → index → offer sync
3. Existing repo → ask PAT → safety files first → clone → create structure → index → skip sync
4. New user → onboarding → create structure → index → offer sync
5. Already set up → detect config.yml → redirect to orient

- [ ] **Step 3: Commit**

```bash
git add skills/setup/SKILL.md
git commit -m "feat: rewrite setup skill for config-driven architecture with credential safety"
```

---

## Chunk 3: Orient, Sync, and Reflect Updates

### Task 4: Update orient skill for config-driven detection and auto-pull

**Files:**
- Modify: `skills/orient/SKILL.md` (Step 0)

- [ ] **Step 1: Rewrite Step 0 for config-driven detection**

Replace the current Step 0 with:

```markdown
## Step 0 — Resolve memory path

Determine the memory directory for this session. Check in order:

1. If `SIDEKICK_MEMORY_DIR` is set, use it. Skip to Step 0b.
2. If `.sidekick/config.yml` exists in the current working directory (or a parent), read it. The memory path is `{.sidekick-dir}/memory/`.
3. If `CLAUDE_CODE_IS_COWORK=1` (Cowork session):
   a. Search mounted user folders for `.sidekick/config.yml` (exclude system dirs: `outputs`, `uploads`, `.claude`, `.local-plugins`, `.skills`).
   b. If found, read it. If not found, tell the user: "No Sidekick config found. Run `/sidekick:setup` to get started."
4. Otherwise (Claude Code): check `~/.claude/.sidekick/config.yml`. If found, read it. If not found, check `~/.claude/memory/index.md` for legacy layout. If neither exists, tell the user to run `/sidekick:setup`.

All `~/.claude/memory/` references in Sidekick skills refer to the resolved memory path for the rest of the session.

## Step 0b — Auto-pull (if configured)

Read `config.yml`. If `git_sync.enabled` is `true` and `git_sync.auto_pull` is `true`:

1. Read the PAT from the credentials file (path from `config.yml`'s `credentials_file`).
2. Construct the authenticated remote URL: `https://{PAT}@{remote-host}/{remote-path}.git`
3. Pull:
   ```bash
   git -C {MEMORY_PATH} pull --rebase origin {branch}
   ```
4. If pull succeeds: continue silently.
5. If pull fails (auth error): warn "Auto-pull failed — credentials may be expired. Run `/sidekick:setup` to update your PAT." Continue with local files.
6. If pull fails (network): warn "Auto-pull failed — no network connection. Using local files." Continue.
```

- [ ] **Step 2: Remove the CLAUDE_ENV_FILE references from the rest of the skill**

The line referencing `CLAUDE_ENV_FILE` in the current Step 0 should be removed entirely. It no longer applies.

- [ ] **Step 3: Commit**

```bash
git add skills/orient/SKILL.md
git commit -m "feat: update orient skill for config-driven detection and auto-pull"
```

---

### Task 5: Update sync skill to use stored credentials

**Files:**
- Modify: `skills/sync/SKILL.md`

- [ ] **Step 1: Add credential loading to sync**

Add a new step after Step 1 (check if git repo) and before Step 2 (check for remote):

```markdown
## Step 1b — Load credentials (if available)

Check for `.sidekick/config.yml` in the parent directory of the memory path. If found and `git_sync.enabled` is `true`:

1. Read the PAT from the credentials file.
2. If credentials exist, configure git to use the PAT for this operation:
   ```bash
   git -C {MEMORY_PATH} remote set-url origin https://{PAT}@{remote-host}/{remote-path}.git
   ```
   (This is a temporary URL rewrite — the config file stores the clean URL without the PAT.)

If no credentials file exists, proceed without — git will use whatever auth is available (SSH keys, credential helpers, etc.).
```

- [ ] **Step 2: Update the Cowork auth note**

Replace the existing Cowork note after Step 1 with:

```markdown
**Cowork note:** If git operations fail with an authentication error, check that your PAT is stored in `.sidekick/credentials`. Run `/sidekick:setup` to configure or update credentials.
```

- [ ] **Step 3: Commit**

```bash
git add skills/sync/SKILL.md
git commit -m "feat: update sync skill to use stored credentials from config"
```

---

### Task 6: Update reflect skill to offer push at session end

**Files:**
- Modify: `skills/reflect/SKILL.md`

- [ ] **Step 1: Add push offer after Step 3 (write approved saves)**

Add between the current Step 3 and Step 4:

```markdown
## Step 3b — Offer to push changes (if git sync enabled)

If `.sidekick/config.yml` exists and `git_sync.enabled` is `true`:

1. Check for uncommitted changes in the memory directory:
   ```bash
   git -C {MEMORY_PATH} status --porcelain
   ```
2. If there are changes, offer to push:
   > "You have memory changes. Push to remote? (yes / skip)"
3. If yes: run `/sidekick:sync`.
4. If skip: changes remain local. They'll be pushed on the next `/sidekick:sync` or auto-pulled from another device won't include them.

If `git_sync.enabled` is `false` or no config exists: skip this step silently.
```

- [ ] **Step 2: Commit**

```bash
git add skills/reflect/SKILL.md
git commit -m "feat: add push offer to reflect skill when git sync is enabled"
```

---

## Chunk 4: Hook Scripts and Documentation

### Task 7: Update session-orient hook for config-driven path resolution

**Files:**
- Modify: `hooks/scripts/session-orient.sh`

- [ ] **Step 1: Rewrite the hook script**

```bash
#!/bin/bash

# Resolve memory directory: explicit override > config file > Cowork detection > default
if [ -n "$SIDEKICK_MEMORY_DIR" ]; then
  MEMORY_DIR="$SIDEKICK_MEMORY_DIR"
elif [ -f ".sidekick/config.yml" ]; then
  # Config in current working directory — use its memory path
  MEMORY_DIR="$(pwd)/.sidekick/memory"
elif [ "$CLAUDE_CODE_IS_COWORK" = "1" ]; then
  # In Cowork without config in cwd — prompt user
  echo "## Sidekick"
  echo "Cowork detected. Run /sidekick:setup to configure memory storage, or /sidekick:orient to load existing memory."
  exit 0
elif [ -f "$HOME/.claude/.sidekick/config.yml" ]; then
  # Claude Code with new config layout
  MEMORY_DIR="$HOME/.claude/.sidekick/memory"
elif [ -d "$HOME/.claude/memory" ]; then
  # Claude Code legacy layout
  MEMORY_DIR="$HOME/.claude/memory"
else
  echo "## Sidekick"
  echo "No memory found. Run /sidekick:setup to get started."
  exit 0
fi

INDEX="$MEMORY_DIR/index.md"

if [ -f "$INDEX" ]; then
  echo "## Sidekick Context (auto-loaded)"
  echo ""
  cat "$INDEX"
  echo ""
  echo "---"
  echo "Proactive capture is active. Save noteworthy context automatically. Use /sidekick:remember for explicit saves, /sidekick:reflect at session end."
else
  echo "## Sidekick"
  echo "No memory found. Run /sidekick:setup to get started."
fi
```

- [ ] **Step 2: Test the hook script**

```bash
# Test: default with legacy layout
bash hooks/scripts/session-orient.sh

# Test: Cowork without config
CLAUDE_CODE_IS_COWORK=1 bash hooks/scripts/session-orient.sh
# Expected: "Cowork detected..."

# Test: explicit override
SIDEKICK_MEMORY_DIR=/tmp/test bash hooks/scripts/session-orient.sh
# Expected: "No memory found..."
```

- [ ] **Step 3: Commit**

```bash
git add hooks/scripts/session-orient.sh
git commit -m "feat: update session-orient hook for config-driven path resolution"
```

---

### Task 8: Update README and cleanup

**Files:**
- Modify: `README.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update README Memory Structure section**

Replace the current Memory Structure section to reflect the new `.sidekick/` layout:

```markdown
## Memory Structure

Sidekick stores everything in a `.sidekick/` directory:

- **Claude Code:** `~/.claude/.sidekick/`
- **Cowork:** `{your-selected-folder}/.sidekick/`

```
.sidekick/
├── config.yml          # Settings (git remote, sync preferences)
├── credentials         # GitHub PAT (gitignored)
├── .gitignore          # Credential safety
├── hooks/pre-commit    # Blocks accidental PAT commits
└── memory/
    ├── index.md        # Hot cache summary
    ├── identity/       # Who you are, roles, preferences
    ├── relationships/  # People, teams, collaborators
    ├── projects/       # Active and past projects
    ├── decisions/      # Key choices and rationale
    ├── patterns/       # Habits, workflows
    └── knowledge/      # Facts, references, domain notes
```

An `index.md` hot cache gives Claude a fast summary without loading every file.
```

- [ ] **Step 2: Update README Cowork section**

Update the Cowork section under Platform Notes to reflect config-driven approach:

```markdown
### Cowork

**Setup:**
1. Install the plugin in Cowork
2. Run `/sidekick:setup` — you'll be prompted to select a folder
3. If you have an existing memory repo, provide the URL and a GitHub PAT during setup

**What works:**
- All skills
- Memory persistence via your selected folder
- Git sync with stored credentials (no re-entering PAT each session)
- Auto-pull on session start (configurable in `.sidekick/config.yml`)

**Differences from Claude Code:**
- **Folder selection required** — memory lives in your selected folder at `.sidekick/`
- **PAT-based auth** — SSH and interactive credentials are not available in the Cowork VM
- **No auto-reflect** — Run `/sidekick:reflect` before ending a session

**Credential safety:** Your GitHub PAT is stored locally in `.sidekick/credentials`, which is gitignored. A pre-commit hook blocks accidental commits containing tokens.
```

- [ ] **Step 3: Update CLAUDE.md project structure**

Update the project structure section in CLAUDE.md to include the new templates:

```markdown
## Project structure

```
.claude-plugin/     # Plugin metadata (plugin.json, marketplace.json)
hooks/              # SessionStart/Stop hooks and bash scripts
skills/             # Skill definitions (SKILL.md files)
templates/          # Templates for memory files, config, gitignore, pre-commit hook
docs/               # Environment detection reference, plans, test logs
```
```

- [ ] **Step 4: Update the memory path note in remaining skills**

Update the memory path note in `skills/remember/SKILL.md`, `skills/recall/SKILL.md`, `skills/status/SKILL.md` to reference the new config approach:

```markdown
> **Memory path:** All `~/.claude/memory/` references below use the memory directory resolved at session start (see orient Step 0). Resolved from `.sidekick/config.yml` or `SIDEKICK_MEMORY_DIR`.
```

- [ ] **Step 5: Commit**

```bash
git add README.md CLAUDE.md skills/remember/SKILL.md skills/recall/SKILL.md skills/status/SKILL.md
git commit -m "docs: update README, CLAUDE.md, and skill notes for config-driven architecture"
```

---

## Execution Notes

- All work should happen on a feature branch (e.g., `feature/config-driven-architecture`) and be merged via PR.
- **Backward compatibility:** The orient hook and skill check for legacy `~/.claude/memory/` layout. Existing Claude Code users don't break — they see migration offered on next `/sidekick:setup`.
- **Credential safety ordering is critical:** `.gitignore` must be written before `credentials` in every code path. The plan enforces this in Steps 2b and 4 of setup.
- **The pre-commit hook is a defense-in-depth layer.** Even if `.gitignore` is misconfigured, the hook catches PAT patterns in staged content.
- After implementation, test in Cowork: (1) fresh setup with PAT, (2) session restart to verify config persistence, (3) auto-pull on orient. Also test Claude Code regression with existing `~/.claude/memory/`.
