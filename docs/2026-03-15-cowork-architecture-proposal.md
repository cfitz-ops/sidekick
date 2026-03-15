# Sidekick for Cowork — Recommended Architecture

**Date:** 2026-03-15
**Context:** Sidekick v0.1.0 was designed for Claude Code, where `~/.claude/memory/` persists on the user's local machine. In Cowork's sandboxed Linux VM, the filesystem resets between sessions. This document proposes an architecture that makes Sidekick work reliably in Cowork while remaining compatible with Claude Code.

---

## Problem Statement

Sidekick's memory layer has no persistence in Cowork. The VM's internal filesystem (`~/.claude/`) is ephemeral. The existing git sync feature requires authentication that isn't available in the Cowork VM (no interactive HTTPS credential entry, no pre-configured SSH keys). Users with existing memory repos from Claude Code have no way to bring that context into Cowork sessions.

Beyond persistence, there's a usability gap: Sidekick should support "ambient context" workflows — things like "look at my day and current projects" — that depend on memory being available automatically at session start, every time, without manual setup.

---

## Recommended Architecture: Dedicated Workspace Folder + Config-Driven Git Sync

### Core Concept

The user maintains a dedicated workspace folder on their local machine (e.g., `~/claude-workspace/`). This folder is always selected when opening Cowork. It serves as the persistent home for:

- `.sidekick/memory/` — Sidekick's memory files (identity, projects, relationships, etc.)
- `.sidekick/config.yml` — Sidekick configuration including git remote URL
- `.sidekick/credentials` — Git auth credentials (PAT), excluded from git via `.gitignore`
- `TASKS.md` — Productivity plugin task tracking
- `CLAUDE.md` — Productivity plugin working memory
- Any working files, drafts, or outputs from Cowork sessions

### Why a Dedicated Folder

Using a single consistent folder solves multiple problems at once. Memory persists between sessions because it lives on the user's actual filesystem. No git clone is required for basic persistence — files are just there. The productivity plugin's `TASKS.md` and `CLAUDE.md` also persist, so task tracking carries over between sessions. And ambient context workflows ("look at my day") work automatically because Sidekick can read memory at session start without any sync step.

The alternative — pointing Cowork at different project folders per session — means memory lives in a different location each time, or doesn't persist at all. A dedicated folder avoids this entirely.

### Config File

`.sidekick/config.yml` stores non-secret configuration that persists in the workspace folder:

```yaml
version: 1
environment: cowork
memory_path: .sidekick/memory/

git_sync:
  enabled: true
  remote: https://github.com/cfitz-ops/claude-memory-git
  branch: main
  auto_pull: true    # pull on session start
  auto_push: false   # require explicit /sidekick:sync to push

credentials_file: .sidekick/credentials
```

The config file itself can be committed to the git repo (it contains no secrets). The credentials file is `.gitignore`d.

### Credentials File

`.sidekick/credentials` stores the GitHub PAT for authenticated git operations:

```
github_pat=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

This file is:
- Created during `/sidekick:setup` when the user provides their PAT
- Added to `.sidekick/.gitignore` so it never gets committed
- Read by Sidekick at session start to authenticate git pull/push
- Stored on the user's local machine (in the selected folder), not in the VM

### Git Sync as an Optional Layer

Git sync is not required for basic persistence — the workspace folder handles that. Git sync adds cross-device portability: if the user works from multiple machines, changes push to the remote repo and pull down on the next session from any device.

The pull happens automatically at session start (if `auto_pull: true` in config). The push is explicit via `/sidekick:sync` or offered during `/sidekick:reflect` at session end. This prevents accidental overwrites and gives the user control over what gets pushed.

---

## Session Lifecycle

### Session Start (SessionStart hook)

```
1. Detect environment (Cowork vs Claude Code)
2. If Cowork:
   a. Check if folder is selected
      - No folder → request_cowork_directory, suggest ~/claude-workspace/
      - Wrong folder / no .sidekick/ found → warn, offer to switch or run ephemeral
   b. Read .sidekick/config.yml
   c. If git_sync.auto_pull is true:
      - Read credentials from .sidekick/credentials
      - Construct authenticated URL: https://{PAT}@github.com/...
      - git pull in .sidekick/memory/
      - If pull fails (auth, network) → warn but continue with local files
   d. Run /sidekick:orient using local memory files
3. If Claude Code:
   a. Use ~/.claude/memory/ as usual (existing behavior)
```

### During Session

No changes to current behavior. Sidekick reads/writes memory files at the resolved path. All skills (`/sidekick:remember`, `/sidekick:recall`, etc.) work as they do today, just pointed at the workspace folder instead of `~/.claude/memory/`.

### Session End (/sidekick:reflect)

```
1. Run existing reflect logic (scan conversation, propose saves)
2. Write any new/updated memory files to .sidekick/memory/
3. If git_sync.enabled:
   a. Show summary of changes
   b. Offer to push: "Push memory changes to remote? (yes / skip)"
   c. If yes → git add, commit, push using stored credentials
4. Files persist in the workspace folder regardless of whether push happens
```

---

## First-Time Setup Flow

```
/sidekick:setup

Step 0 — Environment Detection
  if Cowork:
    if no folder selected:
      request_cowork_directory:
        "Sidekick needs a workspace folder to persist memory between
         sessions. Select or create a folder (e.g., ~/claude-workspace/)."
      if declined → warn about ephemeral mode, continue
    create .sidekick/ directory structure in selected folder
  if Claude Code:
    use ~/.claude/memory/ (existing behavior, no changes needed)

Step 1 — Check for Existing Memory
  if .sidekick/memory/*.md exists in workspace folder:
    → already set up, skip to orient
  if user has existing memory repo:
    → ask for repo URL
    → ask for GitHub PAT
    → write PAT to .sidekick/credentials
    → write config to .sidekick/config.yml
    → clone repo into .sidekick/memory/
    → if clone fails, surface auth troubleshooting
    → skip onboarding questionnaire (repo has identity files)
  if new user:
    → run onboarding questionnaire (Q1–Q4)
    → write identity files to .sidekick/memory/identity/
    → optionally set up git sync

Step 2 — Create Directory Structure
  .sidekick/
  ├── config.yml
  ├── credentials          (gitignored)
  ├── .gitignore
  └── memory/
      ├── index.md
      ├── identity/
      ├── relationships/
      ├── projects/
      ├── decisions/
      ├── patterns/
      └── knowledge/

Step 3 — Generate index.md and Confirm
  → build index from memory files
  → print summary
  → suggest: "Open Cowork with this folder selected to keep
     memory available in every session."
```

---

## Compatibility

### Claude Code
No changes required. Claude Code already persists `~/.claude/memory/` on the user's local machine. Git sync works as-is because the user has full control over their shell environment (SSH keys, credential helpers, etc.).

### Cowork
All changes are Cowork-specific. The setup skill detects the environment and branches accordingly. The config/credentials approach only applies when running in Cowork.

### Cross-Environment Users
Users who work in both Claude Code and Cowork (like the original reporter) can point both at the same git remote. Claude Code pushes/pulls from `~/.claude/memory/`, Cowork pushes/pulls from `.sidekick/memory/` in the workspace folder, and the git repo keeps them in sync.

---

## Open Questions

1. **Should the workspace folder path be stored somewhere that survives folder switching?** If the user opens Cowork with a different folder, Sidekick loses context. A fallback location (like a Cowork-level config) could remember the expected workspace path and prompt the user to switch.

2. **PAT rotation/expiration:** GitHub PATs expire. The credentials file will eventually hold a stale token. Sidekick should detect auth failures gracefully and prompt for a new PAT rather than failing silently.

3. **Merge conflicts:** If the user edits memory from both Claude Code and Cowork between syncs, git conflicts could arise. The reflect/sync flow should handle merge conflicts with a clear resolution strategy (e.g., keep both versions and let the user reconcile).

4. **Productivity plugin alignment:** The productivity plugin (`TASKS.md`, `CLAUDE.md`) should also be aware of the workspace folder convention. Ideally both plugins agree on the same persistent location so they work together seamlessly.
