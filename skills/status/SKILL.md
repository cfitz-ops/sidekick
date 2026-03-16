---
name: status
description: |
  Show memory dashboard — file counts per space, last modified dates, staleness warnings.
  Use when asked "what's in my memory", "memory status", or /sidekick:status.
---

## Step 0 — Ensure context is loaded

If context has not already been loaded this session (i.e., orient has not run), resolve the memory path and load context now:

1. Find `.sidekick/config.yml` in the current working directory, or check `~/.claude/.sidekick/config.yml`, or use `SIDEKICK_MEMORY_DIR`. See orient Step 0 for the full detection logic.
2. Read `{MEMORY_PATH}/index.md` and internalize it silently.

If context was already loaded by orient or another skill this session, skip this step. All `~/.claude/memory/` references below use the resolved memory path.

---

## Step 1 — Count files per space

For each of the 6 memory spaces, count the number of `.md` files present:

```bash
for space in identity relationships projects decisions patterns knowledge; do
  count=$(ls ~/.claude/memory/$space/*.md 2>/dev/null | wc -l | tr -d ' ')
  echo "$space: $count"
done
```

---

## Step 2 — Get last modified date per space

For each space, find the most recently modified file and its timestamp:

```bash
for space in identity relationships projects decisions patterns knowledge; do
  latest=$(ls -t ~/.claude/memory/$space/*.md 2>/dev/null | head -1)
  if [ -n "$latest" ]; then
    date=$(stat -f "%Sm" -t "%Y-%m-%d" "$latest" 2>/dev/null || stat -c "%y" "$latest" 2>/dev/null | cut -d' ' -f1)
    echo "$space: $date ($latest)"
  fi
done
```

---

## Step 3 — Flag stale files

Today's date is known from system context. A file is stale if its `modified` date in YAML frontmatter (or filesystem mtime as fallback) is 30 or more days in the past.

For each space, identify stale files:

```bash
find ~/.claude/memory/{space}/ -name "*.md" -mtime +30 2>/dev/null
```

Collect stale filenames across all spaces. These will be flagged in the dashboard.

---

## Step 4 — Get total file count

Sum all per-space counts:

```bash
find ~/.claude/memory/ -name "*.md" -not -name "index.md" 2>/dev/null | wc -l
```

---

## Step 5 — Present the dashboard

Output a clean table with one row per space. Mark stale spaces with a warning indicator. Example format:

```
Memory Status — ~/.claude/memory/
─────────────────────────────────────────────────────
Space           Files   Last Modified   Notes
─────────────────────────────────────────────────────
identity          2     2025-03-10
relationships     5     2025-03-14
projects          3     2025-02-01      ⚠ stale (42d)
decisions         4     2025-03-12
patterns          1     2025-01-15      ⚠ stale (59d)
knowledge         6     2025-03-13
─────────────────────────────────────────────────────
Total            21 files
```

Rules:
- Show all 6 spaces even if a space has 0 files.
- Mark a space stale if its most recently modified file is 30+ days old.
- Show the number of days since last modification in the stale note.
- If a space has 0 files, show `—` for Last Modified and no stale flag.

---

## Step 6 — List stale file names (if any)

If any stale files were found, append a short list below the table:

```
Stale files (consider reviewing or archiving):
  projects/old-project.md (last modified 2025-02-01)
  patterns/morning-routine.md (last modified 2025-01-15)
```

If no stale files exist, omit this section entirely.

---

## Step 7 — Offer next actions

Close with one line of options:

```
Use /sidekick:recall {topic} to search, /sidekick:remember to add, or /sidekick:sync to back up.
```
