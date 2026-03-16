# Sidekick Setup Log — 2026-03-15 Session 2

**Plugin version:** 0.3.0
**Environment:** Cowork (desktop app, Linux VM sandbox)
**User:** Corey — Head of Marketing Operations, Tiger Data
**Preceded by:** `sidekick-setup-log-2026-03-15.md` (Session 1 — incomplete)
**Outcome:** ✅ Setup complete with filesystem workaround

---

## Context

Session 1 ended with setup incomplete — the GitHub clone failed due to missing auth. This session picked up from there, with the folder already mounted and the PAT provided.

---

## What Happened

### 1. State detection

- Cowork env detected, mounted folder confirmed (`claude-cowork-projects`)
- Prior setup log present in folder — skill did not detect it, treated session as fresh start
- No `config.yml` found → proceeded as new setup *(acceptable outcome, minor UX issue — see bugs)*

### 2. Existing repo flow

- Skill asked whether user had an existing memory repo to clone → yes
- Skill requested a GitHub PAT

### 3. PAT collection — extended back-and-forth

User was unfamiliar with GitHub PATs. Required ~5 exchanges to get to the token:

| Exchange | Topic |
|---|---|
| 1 | Where to find PATs in GitHub settings (navigation steps) |
| 2 | Classic tokens vs. fine-grained tokens — which to use |
| 3 | Which scope to select from the list (user shared a screenshot) |
| 4 | "Full control of private repositories" — user hesitated at the label |
| 5 | What expiration to set — user asked for a recommendation |

Final guidance given: fine-grained token (single repo, Contents: read/write) or classic `repo` scope; no expiration for a personal memory repo.

### 4. Clone attempt 1 — partial failure

`git clone` was run targeting the mounted folder:
```
/mnt/claude-cowork-projects/.sidekick/memory
```

Result:
```
error: could not lock config file .git/config: File exists
fatal: could not set 'remote.origin.fetch' to '+refs/heads/*:refs/remotes/origin/*'
```

This left a partial `.git/` directory in the target path. All subsequent attempts to delete the lock file failed:
```
rm: cannot remove '.git/config.lock': Operation not permitted
```

**Root cause:** The Cowork mounted filesystem (FUSE/virtiofs) does not support `unlink()` on files that git creates as lock/temp objects. Git relies on creating and immediately deleting `.lock` files throughout clone and fetch operations. This is a hard incompatibility.

### 5. Clone attempt 2 — VM temp path workaround

Cloned to VM-local temp path (not the mounted folder):
```
/sessions/pensive-keen-hypatia/tmp-memory-clone
```

Clone succeeded. Then `cp -r` was used to copy all `.md` content files to the mounted memory folder. The `.git/` directory was left in the VM temp space and was NOT copied.

The orphaned `.git/` directory from attempt 1 remains in the mounted folder — it cannot be deleted, but it does not interfere with reading or writing `.md` files alongside it.

### 6. Memory restored

All 8 files from `cfitz-ops/claude-memory-git` successfully copied to `.sidekick/memory/`:

- `identity/profile.md`
- `identity/preferences.md`
- `identity/stack.md`
- `decisions/sidekick-web-app-consideration.md`
- `decisions/sidekick-workspace-deference.md`
- `projects/sidekick.md`
- `knowledge/tiger-den.md`
- `index.md`

### 7. Config and structure created

- `.sidekick/config.yml` written with `git_sync.enabled: true`
- Note added to config that git ops must run from VM temp path (not mounted folder)
- Full directory structure created: `identity/`, `decisions/`, `projects/`, `knowledge/`, `patterns/`, `relationships/`, `hooks/`
- `.gitignore` written (excludes `credentials` file)
- `credentials` file written with PAT
- Pre-commit hook installed

---

## Final Status

| Step | Status |
|---|---|
| Folder mounted | ✅ |
| Safety files (`.gitignore`, `credentials`) | ✅ |
| Repo cloned (via VM temp path) | ✅ |
| Memory files restored | ✅ 8 files |
| Directory structure created | ✅ |
| `config.yml` written | ✅ |
| Pre-commit hook installed | ✅ |
| `index.md` current | ✅ |

---

## Bugs & Issues Found

### 🔴 Critical — Git operations fail on Cowork mounted filesystem

Git cannot clone, fetch, or push directly into the Cowork mounted folder. Lock file creation succeeds but deletion fails (`Operation not permitted`), leaving orphaned `.git/` directories that can't be cleaned up.

**Impact:** `/sidekick:sync` will hit the same issue for all Cowork users. The current `config.yml` includes a note about this, but the sync skill itself has not been updated to handle it.

**Suggested fix:** Never place a `.git/` directory in the mounted folder. Always run git operations in a VM-local temp path and use `cp -r` to move content files to/from the mounted folder.

---

### 🟡 Medium — No graceful recovery from a partial clone

When the first clone partially failed, the skill had no fallback path. Multiple manual attempts were required before the workaround was found. A non-technical user would be stuck.

**Suggested fix:** If clone into mounted folder fails, automatically retry into a VM temp path and copy content files only. Never attempt to delete lock files — route around them.

---

### 🟡 Medium — PAT onboarding assumes GitHub familiarity

The skill's PAT prompt is minimal and assumes the user knows what a PAT is, where to find it, and how to configure it. Non-developer users need significantly more hand-holding.

**Suggested fix:** Embed an inline PAT creation guide directly in the skill flow:
- Direct link to `https://github.com/settings/tokens/new` (fine-grained)
- Recommended settings: single repo, Contents read/write, no expiration
- Explain what the token is used for and where it's stored

---

### 🟡 Medium — Classic `repo` scope causes user hesitation

The label "Full control of private repositories" alarmed a non-technical user who read it as blanket access to everything on their GitHub account.

**Suggested fix:** Default the recommendation to fine-grained tokens with single-repo scope. The extra setup steps are worth it — both for reduced anxiety and actual security hygiene.

---

### 🟡 Medium — Prior failed setup state not detected

The skill checks for `config.yml` to determine if setup was already completed, but doesn't detect a prior failed attempt (orphaned `.git/` dir, prior log file, partial directory structure).

**Suggested fix:** Check for an orphaned `.git/` in the target memory path. If found, surface: "It looks like a previous setup attempt left some files behind — routing around them."

---

### 🟢 Minor — `AskUserQuestion` can't collect free-text PAT

The tool requires a minimum of 2 options — it doesn't support pure free-text input. The PAT had to be requested via plain chat instead, which works but wasn't the intended flow.

**Suggested fix:** Always request the PAT via plain chat message, not `AskUserQuestion`. Document this in the skill.

---

### 🟢 Minor — `$CLAUDE_ENV_FILE` not available in Cowork (carried over from Session 1)

Session 1 attempted to persist `SIDEKICK_MEMORY_DIR` to `$CLAUDE_ENV_FILE`, which is not set in the Cowork environment.

**Suggested fix:** The `.sidekick/config.yml` approach is the correct persistence mechanism for Cowork. Skip or gracefully handle the `$CLAUDE_ENV_FILE` path when it's not set.

---

## What Worked Well

- Environment detection (Cowork vs. Claude Code) was seamless
- Storing credentials in a gitignored local file is the right security approach
- The memory directory structure (`identity/`, `decisions/`, `projects/`, etc.) is intuitive and clean
- Once the filesystem workaround was found, memory restoration was straightforward
- The overall setup flow is logical — the issues are in edge cases and onboarding UX, not the core design

---

## Top Recommendations for v0.4.0

1. **Never put `.git/` in the mounted folder** — always use VM temp path for all git operations
2. **Update `/sidekick:sync` for Cowork** — it will break on the mounted filesystem the same way
3. **Add inline PAT creation guide** — with direct link and recommended settings for non-developers
4. **Default to fine-grained tokens** — reduces scope anxiety, better security hygiene
5. **Detect and surface partial clone remnants** — route around gracefully instead of failing
6. **Drop `$CLAUDE_ENV_FILE` fallback in Cowork** — `config.yml` is the right mechanism there
