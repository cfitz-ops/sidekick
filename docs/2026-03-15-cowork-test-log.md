# Sidekick Setup — Git Sync Issue Log

**Date:** 2026-03-15
**Environment:** Cowork (desktop app), Sidekick v0.1.0
**User:** corey@tigerdata.com

---

## Summary

During first-run `/sidekick:setup`, the user had existing memory files hosted in a private GitHub repo and wanted to clone them into `~/.claude/memory/` rather than go through the new-user onboarding questionnaire. The setup skill does not have a code path for this scenario, and the clone attempt failed due to missing authentication. Further investigation revealed a deeper architectural mismatch: Sidekick's memory storage assumes a persistent local filesystem, but the Cowork VM resets between sessions.

---

## Steps Taken

1. `/sidekick:setup` was invoked.
2. Skill checked `~/.claude/memory/` — directory did not exist (no existing files to migrate).
3. Skill began Step 3 (new user onboarding) and asked Q1.
4. User interrupted to ask about syncing existing memory from a private git repo.
5. Checked `~/.claude/memory` — confirmed directory does not exist.
6. Attempted to clone via HTTPS:
   ```
   git clone https://github.com/cfitz-ops/claude-memory-git ~/.claude/memory
   ```
7. **Clone failed:**
   ```
   fatal: could not read Username for 'https://github.com': No such device or address
   ```
   HTTPS authentication is not available in the Cowork Linux VM — there is no interactive terminal for credential entry.
8. Checked for SSH keys (`~/.ssh/*.pub`) — none found.
9. Offered three workarounds: PAT via URL, SSH key setup, or temporarily making repo public.
10. Session ended without resolution.
11. **On next session start:** The issue log file written to `/mnt/outputs/` in the previous session was gone — confirming that without a user-selected folder, even the outputs directory does not persist between Cowork sessions.

---

## Root Cause

The Cowork VM has no mechanism for interactive HTTPS credential entry, and no SSH keys are pre-configured. The `/sidekick:setup` skill's Step 6 (git sync) assumes the user is setting up a *new* repo and only covers `git init` + `git remote add`. It does not handle the case where the user already has an existing memory repo they want to pull down at setup time.

---

## Gaps / Issues to Fix

### Issue 1 — No "existing repo" onboarding path
The setup skill should detect (or ask) whether the user has an existing memory repo and offer to clone it *before* running the new-user questionnaire. If they do, cloning should replace Q1–Q4 entirely.

### Issue 2 — No authentication guidance for Cowork
The skill assumes git auth is already configured. In Cowork, HTTPS auth and SSH keys are not pre-configured. The skill should warn about this and provide clear steps for either:
- Providing a PAT-embedded URL (`https://<token>@github.com/...`)
- Setting up an SSH key in `~/.ssh/` before cloning

### Issue 3 — Silent failure with no recovery
When the clone fails, the skill offers no fallback. It should catch the failure and present auth options automatically rather than requiring the user to ask.

### Issue 4 — Step ordering
The git sync step (Step 6) comes *after* onboarding. If the user already has a repo, cloning should happen *first*, since the repo may already contain identity files that make Q1–Q4 redundant.

### Issue 5 — Memory storage location is wrong for Cowork
Sidekick writes memory to `~/.claude/memory/`, which lives inside the Cowork Linux VM's ephemeral filesystem. **This directory resets between every session.** The git sync feature is meant to solve this, but it only works if the repo is cloned at the start of *every* session — not just during setup. The current design has no session-start clone step.

Two potential fixes:
- **Option A:** Write memory to the mounted outputs folder (`/mnt/outputs/memory/`) instead of `~/.claude/memory/`, so it persists on the user's actual computer between sessions. This would require the user to have a folder selected in Cowork.
- **Option B:** Add a `SessionStart` hook that automatically clones/pulls from the git repo at the top of every session. This requires solved auth (Issue 2) and would add latency to session startup.

Sidekick was likely designed for Claude Code, where `~/.claude/` persists on the developer's local machine. In Cowork's sandboxed VM, that assumption breaks entirely.

---

## Considered and Rejected: MCP-Based Sync

An MCP server was considered as a solution — it could handle authentication, provide a persistent memory API, and sync automatically across sessions and devices.

**Why it was rejected:**

The core problem is simpler than what an MCP solves. Memory files just need to live somewhere that persists between sessions. In Cowork, that's the mounted outputs folder (the user's selected local folder). In Claude Code, `~/.claude/` already persists natively. Adding an MCP server introduces unnecessary complexity — a separate server process, authentication management, API calls — to solve what is fundamentally a file path problem.

Git sync remains a good optional layer for cross-device portability, but it shouldn't be *required* for basic session-to-session continuity.

Where an MCP *might* make sense in the future: if multiple tools (Sidekick, productivity plugin, other plugins) all need shared persistent state and a centralized memory service. But for solving "my memory disappears between Cowork sessions," it's overkill.

### Issue 6 — Folder selection dependency for Cowork persistence

Option A from Issue 5 (writing to `/mnt/outputs/memory/`) requires the user to have a folder selected in Cowork. This is not the default state — users can open Cowork without selecting any folder. If memory persistence depends on a selected folder, Sidekick silently fails for the most common Cowork usage pattern.

This needs to be handled explicitly:

- **At setup time:** If running in Cowork with no folder selected, Sidekick should use `request_cowork_directory` to prompt the user to select a folder. Memory persistence depends on it, so this should be a required step — not optional.
- **Graceful degradation:** If the user declines to select a folder, Sidekick should still work within the current session but clearly warn that nothing will persist. At session end, it could offer to export memory as a downloadable file or prompt for a folder selection before closing.
- **Session start detection:** If a returning user opens Cowork without a folder (or with a different folder than where memory was stored), Sidekick should detect this and prompt them to re-select the correct folder rather than silently starting fresh.

The key principle: Sidekick should never silently lose memory. Either persistence is guaranteed, or the user is explicitly warned that they're in ephemeral mode.

---

## Suggested Fix (Pseudocode for Step 1)

```
Step 0 — Environment detection (Cowork only)
  if running in Cowork:
    if no folder selected:
      request_cowork_directory with message:
        "Sidekick needs a folder to persist memory between sessions.
         Please select a folder."
      if user selects folder → continue
      if user declines:
        warn: "Running in ephemeral mode — memory will not persist
               after this session."
        set EPHEMERAL_MODE = true
    set MEMORY_PATH = /mnt/outputs/.sidekick-memory/
  else (Claude Code):
    set MEMORY_PATH = ~/.claude/memory/

Step 1 — Check for existing memory
  if MEMORY_PATH/*.md exists → migrate (existing flow)
  else:
    Ask: "Do you have an existing Sidekick memory repo? (yes / no)"
    if yes:
      Ask for repo URL
      Provide auth instructions (PAT or SSH)
      Attempt clone into MEMORY_PATH
      If clone succeeds → skip to Step 4
      If clone fails → surface auth setup steps, retry
    if no → proceed to Step 3 (new user onboarding)

  if EPHEMERAL_MODE:
    At session end, offer to export memory or prompt for folder selection
```
