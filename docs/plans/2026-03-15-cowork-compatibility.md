# Cowork Compatibility Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Sidekick work reliably in Cowork by detecting the runtime environment, resolving the correct memory path, handling ephemeral filesystems, and supporting existing-repo onboarding.

**Architecture:** All skills are markdown instruction files that Claude interprets at runtime — not executable code. The only executable components are two bash hook scripts. Environment detection is handled by adding a shared "Step 0" pattern to the setup and orient skills (the two entry points), which resolves the memory path and sets context that downstream skills inherit. Other skills replace hardcoded `~/.claude/memory/` references with "the resolved memory path."

**Tech Stack:** Markdown (skill files), Bash (hook scripts), GitHub (branch protection + PRs)

**Key Research Findings (2026-03-15):**
- `CLAUDE_CODE_IS_COWORK=1` is the confirmed env var for detecting Cowork runtime
- Cowork runs Ubuntu 22.04 in a VM with session-scoped paths at `/sessions/<name>/mnt/`
- User-selected folders mount at `/sessions/<name>/mnt/<folder-name>/` — the folder name varies
- `/mnt/outputs/` is a system directory for Claude's output files, NOT the user's folder
- `/mnt/user/` does not exist as a standard path
- `request_cowork_directory` is a Cowork tool that triggers the native folder picker (has been buggy)
- Files written to the mounted user folder persist on the host via VirtioFS; all other VM paths are ephemeral
- `CLAUDE_ENV_FILE` can persist env vars within a session (not across sessions)

---

## Chunk 1: Environment Detection and Memory Path Resolution

The core problem: Sidekick assumes `~/.claude/memory/` persists between sessions. In Cowork's VM, it doesn't. We need to detect the environment and route memory to a persistent location.

### Task 1: Define the environment detection reference

A single source of truth for how Sidekick detects its runtime and resolves the memory path. This lives as a new file that skills can reference rather than duplicating detection logic.

**Files:**
- Create: `docs/environment-detection.md`

- [ ] **Step 1: Write the environment detection reference**

```markdown
# Environment Detection

Sidekick runs in two environments with different persistence models.

## Detection Logic

Check in this order:

1. **Explicit override:** If `SIDEKICK_MEMORY_DIR` is set, use it. No further detection needed.
2. **Cowork detection:** If `CLAUDE_CODE_IS_COWORK=1`, this is a Cowork session. Resolve the memory path within the user's mounted folder (see Cowork Folder Resolution below).
3. **Default (Claude Code):** Use `~/.claude/memory/`.

## Memory Path by Environment

| Environment | Memory Path | Persistence |
|-------------|-------------|-------------|
| Claude Code | `~/.claude/memory/` | Native — survives between sessions |
| Cowork (folder mounted) | `{mounted-folder}/.sidekick-memory/` | Persists via VirtioFS to host machine |
| Cowork (no folder) | `~/.claude/memory/` (ephemeral) | Lost between sessions — warn user |
| Custom (`SIDEKICK_MEMORY_DIR`) | Whatever the user set | User-managed |

## Cowork Folder Resolution

In Cowork, the user's selected folder is mounted into the VM via VirtioFS at a session-scoped path under `/sessions/<session-name>/mnt/<folder-name>/`. The folder name varies based on what the user selected (e.g., `Downloads`, `my-project`).

**To find the mounted folder in a skill (Claude interpreting instructions):**

1. Check if the current working directory is under a mounted user folder (it usually is if the user selected a folder).
2. Look for writable directories under the session's `/mnt/` path that are not system directories (`outputs`, `uploads`, `.claude`, `.local-plugins`, `.skills`).
3. If no mounted folder is found, use `request_cowork_directory` (if available) to prompt the user to select one.
4. If `request_cowork_directory` is unavailable or the user declines, fall back to `~/.claude/memory/` and warn about ephemeral mode.

**To find the mounted folder in a bash hook:**

Hooks cannot reliably detect the mounted folder name since it varies per session. In bash hooks, rely on `SIDEKICK_MEMORY_DIR` being set. If it is not set and `CLAUDE_CODE_IS_COWORK=1`, the hook should output a message telling the user to run `/sidekick:orient` or `/sidekick:setup` to configure the memory path.

The orient or setup skill can then set `SIDEKICK_MEMORY_DIR` via `CLAUDE_ENV_FILE` to persist it for the rest of the session.

## Setting SIDEKICK_MEMORY_DIR via CLAUDE_ENV_FILE

In Cowork, once the memory path is resolved by a skill, persist it for the session:

```bash
echo "SIDEKICK_MEMORY_DIR={resolved-path}" >> "$CLAUDE_ENV_FILE"
```

This makes the path available to subsequent hook invocations within the same session.

## Skills That Need Detection

Only entry-point skills need full detection logic:
- **setup** — runs once, creates directory structure
- **orient** — runs every session start

All other skills (remember, recall, reflect, status, sync) inherit the resolved path from orient's session context or fall back to `SIDEKICK_MEMORY_DIR` / `~/.claude/memory/`.
```

- [ ] **Step 2: Commit**

```bash
git add docs/environment-detection.md
git commit -m "docs: add environment detection reference for Cowork compatibility"
```

---

### Task 2: Update orient skill with Cowork detection

Orient's existing Step 0 only checks the env var. It needs to also detect Cowork, find the mounted folder, resolve the memory path, and persist it via `CLAUDE_ENV_FILE`.

**Files:**
- Modify: `skills/orient/SKILL.md` (Step 0, lines 9-11)

- [ ] **Step 1: Rewrite Step 0 with full detection logic**

Replace the current Step 0 with:

```markdown
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
```

- [ ] **Step 2: Verify the rest of the orient skill still reads correctly**

Read through Steps 1 through 3 and confirm all `~/.claude/memory/` references are qualified with "(using the resolved memory path)" or similar. Step 1 already has this qualifier. Steps 1.5, 2, and 3 reference paths like `relationships/{person-name}.md` without the prefix — these are fine since they're relative to the memory directory Claude already resolved.

- [ ] **Step 3: Commit**

```bash
git add skills/orient/SKILL.md
git commit -m "feat: add Cowork environment detection to orient skill"
```

---

### Task 3: Update hook scripts for Cowork detection

The bash hooks run before skills. In Cowork, the hook can't reliably find the mounted folder name, but it CAN check `SIDEKICK_MEMORY_DIR` (which orient/setup will have persisted via `CLAUDE_ENV_FILE` after the first session setup) and `CLAUDE_CODE_IS_COWORK`.

**Files:**
- Modify: `hooks/scripts/session-orient.sh`
- Modify: `hooks/scripts/session-reflect.sh`

- [ ] **Step 1: Update session-orient.sh**

Replace the full script with:

```bash
#!/bin/bash

# Resolve memory directory: explicit override > Cowork env file > default
if [ -n "$SIDEKICK_MEMORY_DIR" ]; then
  MEMORY_DIR="$SIDEKICK_MEMORY_DIR"
elif [ "$CLAUDE_CODE_IS_COWORK" = "1" ]; then
  # In Cowork without SIDEKICK_MEMORY_DIR set — can't resolve the
  # mounted folder from a bash hook. Prompt the user to run setup.
  echo "## Sidekick"
  echo "Cowork detected. Run /sidekick:setup to configure memory storage, or /sidekick:orient to load existing memory."
  exit 0
else
  MEMORY_DIR="$HOME/.claude/memory"
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

- [ ] **Step 2: Update session-reflect.sh**

Same detection pattern:

```bash
#!/bin/bash

# Resolve memory directory: explicit override > default
# In Cowork without SIDEKICK_MEMORY_DIR, skip reflection (no persistent memory to check)
if [ -n "$SIDEKICK_MEMORY_DIR" ]; then
  MEMORY_DIR="$SIDEKICK_MEMORY_DIR"
elif [ "$CLAUDE_CODE_IS_COWORK" = "1" ]; then
  # No memory dir configured in Cowork — nothing to reflect on
  cat <<'EOF'
{"decision": "approve"}
EOF
  exit 0
else
  MEMORY_DIR="$HOME/.claude/memory"
fi

LOCK_FILE="/tmp/sidekick-reflect-$$"

# Prevent infinite loop: only fire once per session
# Check for any existing lock file from this parent process
PARENT_PID=$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')
LOCK_FILE="/tmp/sidekick-reflect-${PARENT_PID}"

if [ -f "$LOCK_FILE" ]; then
  # Already reflected this session — approve exit
  cat <<'EOF'
{"decision": "approve"}
EOF
  exit 0
fi

if [ -d "$MEMORY_DIR" ] && [ -f "$MEMORY_DIR/index.md" ]; then
  # Set lock before blocking so re-trigger sees it
  touch "$LOCK_FILE"
  cat <<'EOF'
{"decision": "block", "reason": "Session reflection: review this conversation for context worth saving to memory. Propose any new memories as a batch for the user to approve. If nothing noteworthy, proceed to exit."}
EOF
else
  cat <<'EOF'
{"decision": "approve"}
EOF
fi
```

- [ ] **Step 3: Test hook scripts locally**

Run each script manually and verify output:

```bash
# Test orient — default (Claude Code)
bash hooks/scripts/session-orient.sh

# Test orient — custom path
SIDEKICK_MEMORY_DIR=/tmp/test-memory bash hooks/scripts/session-orient.sh

# Test orient — Cowork without SIDEKICK_MEMORY_DIR
CLAUDE_CODE_IS_COWORK=1 bash hooks/scripts/session-orient.sh
# Expected: "Cowork detected. Run /sidekick:setup..."

# Test orient — Cowork with SIDEKICK_MEMORY_DIR
CLAUDE_CODE_IS_COWORK=1 SIDEKICK_MEMORY_DIR=/tmp/test-memory bash hooks/scripts/session-orient.sh

# Test reflect — default
bash hooks/scripts/session-reflect.sh

# Test reflect — Cowork without SIDEKICK_MEMORY_DIR
CLAUDE_CODE_IS_COWORK=1 bash hooks/scripts/session-reflect.sh
# Expected: {"decision": "approve"}
```

- [ ] **Step 4: Commit**

```bash
git add hooks/scripts/session-orient.sh hooks/scripts/session-reflect.sh
git commit -m "feat: add Cowork detection to hook scripts using CLAUDE_CODE_IS_COWORK"
```

---

## Chunk 2: Setup Skill Rewrite

The setup skill needs the biggest changes: environment detection, existing-repo onboarding path, auth guidance, and reordered steps.

### Task 4: Rewrite setup skill with environment detection and existing-repo path

**Files:**
- Modify: `skills/setup/SKILL.md` (major rewrite)

- [ ] **Step 1: Write the new Step 0 — Environment detection**

Add before current Step 1:

```markdown
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

Use this resolved path for all subsequent steps. All `~/.claude/memory/` references below mean "the resolved memory path."

See `docs/environment-detection.md` for the full detection reference.
```

- [ ] **Step 2: Write the new Step 1 — Check for existing memory (replaces current Step 1)**

Replace the current Step 1 (scan for existing files) with a broader check that also asks about existing repos:

```markdown
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
```

- [ ] **Step 3: Write the new Step 2b — Clone existing repo**

Add after Step 2 (migrate):

```markdown
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
```

- [ ] **Step 4: Update Steps 3-6 to use resolved memory path**

Go through Steps 3 (onboarding), 4 (create directories), 5 (generate index), and 6 (git sync) and replace all hardcoded `~/.claude/memory/` references with `{MEMORY_PATH}` (the resolved path from Step 0). The instructions should note: "Use the memory path resolved in Step 0 for all file operations."

Specific replacements needed in current skill text:
- Step 3: `~/.claude/memory/identity/profile.md` → `{MEMORY_PATH}/identity/profile.md` (3 occurrences)
- Step 4: `~/.claude/memory/identity` etc. → `{MEMORY_PATH}/identity` (6 occurrences)
- Step 5: `~/.claude/memory/` → `{MEMORY_PATH}/` (3 occurrences)
- Step 6: `~/.claude/memory` → `{MEMORY_PATH}` (all occurrences)

- [ ] **Step 5: Update Step 6 (git sync) to skip if already a git repo**

If the user came through Step 2b (cloned an existing repo), the memory directory is already a git repo with a remote. Step 6 should detect this and skip:

```markdown
## Step 6 — Offer git sync (optional)

Check if the memory directory is already a git repo:

```bash
git -C {MEMORY_PATH} rev-parse --is-inside-work-tree 2>/dev/null
```

If already a git repo with a remote configured: skip this step. Sync is already set up.

If not a git repo: [existing Step 6 content, with {MEMORY_PATH} substituted]
```

- [ ] **Step 6: Read through the complete rewritten skill end-to-end**

Verify the flow makes sense for all entry paths:
1. Existing files in memory dir → migrate → create dirs → generate index → offer sync
2. Existing repo to clone → clone → create dirs → generate index → skip sync
3. Brand new user → onboarding questions → create dirs → generate index → offer sync

Also verify the Cowork-specific paths:
4. Cowork with folder → resolves to `{mounted-folder}/.sidekick-memory/` → any of the above
5. Cowork without folder → ephemeral warning → any of the above (but won't persist)
6. Cowork returning user (SIDEKICK_MEMORY_DIR already set via CLAUDE_ENV_FILE from prior setup in same session) → uses cached path

- [ ] **Step 7: Commit**

```bash
git add skills/setup/SKILL.md
git commit -m "feat: rewrite setup skill with env detection and existing-repo support"
```

---

## Chunk 3: Update Remaining Skills and Documentation

### Task 5: Update remaining skills to use resolved memory path

All remaining skills reference `~/.claude/memory/` in their instructions. Add a note to each that these paths use the memory directory resolved by orient at session start.

**Files:**
- Modify: `skills/remember/SKILL.md`
- Modify: `skills/recall/SKILL.md`
- Modify: `skills/reflect/SKILL.md`
- Modify: `skills/status/SKILL.md`
- Modify: `skills/sync/SKILL.md`

- [ ] **Step 1: Add path resolution note to each skill**

Add the following line immediately after the YAML frontmatter `---` in each skill file:

```markdown
> **Memory path:** All `~/.claude/memory/` references below use the memory directory resolved at session start (see orient Step 0). Default: `~/.claude/memory/`. Override: set `SIDEKICK_MEMORY_DIR` or use Cowork with a selected folder.
```

- [ ] **Step 2: Update sync skill for Cowork auth awareness**

In `skills/sync/SKILL.md`, add a note after Step 1 (check if git repo) for Cowork environments:

```markdown
**Cowork note:** If git operations fail with an authentication error, Cowork VMs do not have SSH keys or interactive git credentials configured. Use HTTPS URLs with a personal access token (PAT). See `/sidekick:setup` Step 2b for details.
```

- [ ] **Step 3: Commit**

```bash
git add skills/remember/SKILL.md skills/recall/SKILL.md skills/reflect/SKILL.md skills/status/SKILL.md skills/sync/SKILL.md
git commit -m "feat: add memory path resolution note to all skills"
```

---

### Task 6: Update README with Cowork install and usage instructions

Expand the Platform Notes section we already added with actual install and usage guidance now that we know how Cowork works.

**Files:**
- Modify: `README.md` (Platform Notes section)

- [ ] **Step 1: Expand the Cowork section**

Replace the current Cowork section under Platform Notes with:

```markdown
### Cowork

Sidekick works in Cowork with some differences from Claude Code:

**Setup:**
1. Install the plugin in Cowork
2. Select a folder in Cowork's file picker — Sidekick stores memory in `.sidekick-memory/` inside this folder
3. Run `/sidekick:setup` to onboard

**What works:**
- All skills (`/sidekick:orient`, `/sidekick:remember`, `/sidekick:recall`, `/sidekick:reflect`, `/sidekick:status`)
- Memory persistence (requires a selected folder — files persist on your machine via VirtioFS)
- Git sync (`/sidekick:sync`) with PAT-based HTTPS authentication

**Differences from Claude Code:**
- **First session:** Hooks can't auto-detect the mounted folder path. Run `/sidekick:setup` or `/sidekick:orient` to configure — this persists for the rest of the session.
- **No auto-reflect** — SessionStop hooks may not fire. Run `/sidekick:reflect` before ending a session.
- **Authentication** — SSH keys and interactive git credentials are not available in the Cowork VM. Use HTTPS URLs with a personal access token for git sync.
- **Memory location** — Memory is stored in your selected folder at `.sidekick-memory/` instead of `~/.claude/memory/`.

**Without a folder selected:** Sidekick works within a single session but memory does not persist. You'll be warned at setup time and can select a folder at any point.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: expand Cowork platform notes with install and usage guidance"
```

---

### Task 7: Clean up issue log and compatibility doc

The `sidekick-sync-issue-log.md` and `COWORK-COMPATIBILITY.md` were working documents. Now that the fixes are planned, organize them as reference material.

**Files:**
- Evaluate: `COWORK-COMPATIBILITY.md`
- Evaluate: `sidekick-sync-issue-log.md`

- [ ] **Step 1: Move issue log out of repo root**

The issue log is a test artifact, not project documentation. Move it to `docs/` for reference:

```bash
mv sidekick-sync-issue-log.md docs/2026-03-15-cowork-test-log.md
```

- [ ] **Step 2: Evaluate COWORK-COMPATIBILITY.md**

Check each action item against the plan. If all items are addressed by this implementation, add a "Resolved" note at the top linking to the relevant commits. Keep the file as a reference — it documents the investigation.

- [ ] **Step 3: Commit**

```bash
git add docs/2026-03-15-cowork-test-log.md sidekick-sync-issue-log.md COWORK-COMPATIBILITY.md
git commit -m "chore: organize test artifacts and update compatibility doc"
```

---

## Execution Notes

- All work should happen on a feature branch (e.g., `feature/cowork-compatibility`) and be merged via PR per the CLAUDE.md convention.
- Environment detection uses `CLAUDE_CODE_IS_COWORK=1` (confirmed standard env var), not filesystem path sniffing.
- The mounted folder path varies per session (`/sessions/<name>/mnt/<folder>/`), so skills must discover it dynamically — hooks cannot.
- `CLAUDE_ENV_FILE` persists env vars within a session but not across sessions. Each new Cowork session requires orient/setup to re-resolve the path.
- `request_cowork_directory` has been buggy (missing from tool inventory in some versions). Always handle the case where it's unavailable.
- After implementation, re-test end-to-end in Cowork covering: (1) fresh setup with folder, (2) fresh setup without folder, (3) returning session with folder, (4) Claude Code regression.
