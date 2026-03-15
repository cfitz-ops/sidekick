---
name: recall
description: |
  Search and retrieve from memory. Use when asked "what do I know about...",
  "who is...", "what did we decide about...", or /sidekick:recall.
---

## Step 1 — Identify the query

Extract the search target from the user's message: a person name, project name, topic, keyword, or phrase.

If the query is ambiguous, ask one clarifying question before searching.

---

## Step 2 — Search by filename (fast match)

List all files across every memory space:

```bash
ls ~/.claude/memory/identity/ ~/.claude/memory/relationships/ ~/.claude/memory/projects/ ~/.claude/memory/decisions/ ~/.claude/memory/patterns/ ~/.claude/memory/knowledge/ 2>/dev/null
```

Compare filenames against the query. A filename match (e.g., `alice.md` for query "Alice") is a strong signal — include that file in results.

---

## Step 3 — Search file content (deep match)

Run a case-insensitive grep across all memory files:

```bash
grep -ril "{query}" ~/.claude/memory/ 2>/dev/null
```

Collect all matching file paths. For each match, extract the surrounding context:

```bash
grep -i -C 3 "{query}" {file_path}
```

---

## Step 4 — Check YAML frontmatter

For any files not already caught by steps 2–3, scan frontmatter fields directly — `name`, `type`, `status` — for matches against the query.

Pay particular attention to `status: active` when the user is asking about something ongoing.

---

## Step 5 — Return results

For each matching file, output:
- The file path (relative to `~/.claude/memory/`)
- The `name` and `type` from frontmatter
- 2–4 lines of the most relevant excerpt from the file body

Format as a compact list, not a table. Example:

```
relationships/alice.md — relationship
  Alice joined the product team as PM in March 2025.
  Key context: she owns the roadmap for my-web-app.

decisions/chose-netlify.md — decision
  Chose Netlify over Heroku for my-web-app (cost + DX).
  Decision date: 2025-02-10.
```

If multiple files match, show the most relevant ones first. Limit to 5 results unless the user asks for more.

---

## Step 6 — Offer to read full files

After showing results, add one line:

```
Say "read {filename}" to see the full file.
```

If only one result was found, offer to read it immediately without prompting.

---

## Step 7 — If nothing found

If no matches are found across filenames, content, and frontmatter, say clearly:

```
Nothing found in memory for "{query}".
```

Do not guess, infer, or fabricate context. Do not suggest what might be saved. If the user wants to save something related, they can use `/sidekick:remember`.
