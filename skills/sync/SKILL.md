---
name: sync
description: |
  Sync memory across devices via private git repo. Commits, pulls, and pushes.
  Requires git repo setup during /sidekick:setup (opt-in). Use with /sidekick:sync.
---

## Step 1 — Check if memory is a git repo

Run:

```bash
git -C ~/.claude/memory/ rev-parse --is-inside-work-tree 2>/dev/null
```

If this returns anything other than `true`, the memory directory is not a git repo. Stop and tell the user:

```
Sync requires a git repo at ~/.claude/memory/. This is set up during /sidekick:setup.
Run /sidekick:setup to configure sync, then try again.
```

Do not proceed further.

---

## Step 2 — Check for a remote

Run:

```bash
git -C ~/.claude/memory/ remote -v
```

If no remote is configured, stop and tell the user:

```
No remote configured for ~/.claude/memory/. Sync requires a remote (e.g., a private GitHub repo).
Run /sidekick:setup to add a remote, then try again.
```

---

## Step 3 — Stage all changes

Run:

```bash
git -C ~/.claude/memory/ add -A
```

Check if there is anything staged:

```bash
git -C ~/.claude/memory/ diff --cached --name-only
```

Note the list of staged files. If there are no staged changes, skip Step 4 and note that nothing was committed.

---

## Step 4 — Commit local changes

If there are staged changes, commit with a date-stamped message:

```bash
git -C ~/.claude/memory/ commit -m "sidekick: sync $(date +%Y-%m-%d)"
```

Note the commit hash and number of files committed.

---

## Step 5 — Pull remote changes

Pull with rebase to incorporate any remote changes cleanly:

```bash
git -C ~/.claude/memory/ pull --rebase origin $(git -C ~/.claude/memory/ branch --show-current)
```

If the pull succeeds, continue to Step 6.

If the pull results in a rebase conflict, stop and report:

```
Conflict during pull. Resolve before pushing.
Conflicting files:
  {list conflicting files}

Options:
  - Edit the conflicted files, then run /sidekick:sync again.
  - Or tell me which version to keep ("keep mine" / "keep theirs") for each file.
```

Do not push. Wait for user instructions.

---

## Step 6 — Push local changes

Run:

```bash
git -C ~/.claude/memory/ push origin $(git -C ~/.claude/memory/ branch --show-current)
```

If the push fails (e.g., rejected), report the error verbatim and stop. Do not force push.

---

## Step 7 — Report status

Output a short summary:

```
Sync complete.
  Committed: {N} files  (or "Nothing to commit")
  Pulled:    {N} commits from remote  (or "Already up to date")
  Pushed:    {N} commits to remote  (or "Nothing to push")
```

If the entire sync was a no-op (nothing committed, already up to date, nothing pushed), say:

```
Memory is already in sync. No changes.
```
