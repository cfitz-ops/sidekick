# Cowork Compatibility Gaps

Sidekick README claims "Works in both Claude Code and Cowork" but provides no Cowork-specific guidance. Testing on 2026-03-15 surfaced three areas that need investigation and likely fixes.

## 1. Filesystem Access

**Issue:** Cowork uses folder-scoped sandboxing. Users explicitly choose which folders Claude can access. It's unclear whether `~/.claude/memory/` (a hidden directory) is accessible by default or requires explicit user grant.

**Impact:** If Cowork blocks access to `~/.claude/`, every Sidekick skill fails — reads, writes, and the index all depend on this path.

**Recommendation:**
- Test whether Cowork can access `~/.claude/memory/` out of the box
- If not, document that users must grant folder access to `~/.claude/` in Cowork's permission settings
- Consider supporting a configurable storage path (e.g., env var `SIDEKICK_MEMORY_DIR`) so users on restricted platforms can point to an allowed directory

## 2. SessionStart Hook

**Issue:** Sidekick's auto-orient feature depends on a `SessionStart` hook defined in `hooks/hooks.json` that runs `session-orient.sh`. Cowork documentation makes no mention of hook support.

**Impact:** If hooks don't fire in Cowork, memory context is not auto-loaded at session start. Users would need to manually run `/sidekick:orient` every time — a silent failure with no error message.

**Recommendation:**
- Test whether Cowork executes plugin hooks
- If not, add a fallback: detect the environment and prompt the user to run `/sidekick:orient` manually
- Document this limitation in the README under a "Cowork" section

## 3. Bash Script Execution

**Issue:** Sidekick hooks run shell scripts (`session-orient.sh`). It's undocumented whether Cowork can execute bash scripts from plugin hooks.

**Impact:** Even if hooks fire, the bash script may not execute in Cowork's sandbox, silently breaking auto-orient.

**Recommendation:**
- Test bash execution from plugin hooks in Cowork
- If unsupported, consider a non-bash fallback (e.g., skill-based orient that doesn't depend on shell execution)

## Action Items

- [ ] Test Sidekick install in Cowork end-to-end
- [ ] Verify `~/.claude/memory/` is accessible from Cowork
- [ ] Verify SessionStart hooks fire in Cowork
- [ ] Verify bash scripts execute from plugin hooks in Cowork
- [ ] Add Cowork-specific install instructions to README
- [ ] Add configurable memory path as fallback for sandboxed environments
- [ ] Add environment detection to gracefully handle missing hooks
