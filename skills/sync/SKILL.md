---
name: sync
description: |
  Sync memory across devices via private git repo. Commits, pulls, and pushes.
  Requires git repo setup during /sidekick:setup (opt-in). Use with /sidekick:sync.
---

## Step 0 — Ensure context is loaded

If context has not already been loaded this session (i.e., orient has not run), resolve the memory path now:

1. Find `.sidekick/config.yml` in the current working directory, or check `~/.claude/.sidekick/config.yml`, or use `SIDEKICK_MEMORY_DIR`. See orient Step 0 for the full detection logic.

Sync does not need to load the memory index — it only needs the resolved path and config. All `~/.claude/memory/` references below use the resolved memory path.

---

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
