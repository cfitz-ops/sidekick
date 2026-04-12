---
name: recall
description: |
  Search and retrieve from memory. Use when asked "what do I know about...",
  "who is...", "what did we decide about...", or /sidekick:recall.
---

## Step 0 — Ensure context is loaded

If context has not already been loaded this session (i.e., orient has not run), resolve the memory path and load context now:

1. Find `.sidekick/config.yml` in the current working directory, or check `~/.claude/.sidekick/config.yml`, or use `SIDEKICK_MEMORY_DIR`. See orient Step 0 for the full detection logic.
2. Read `{MEMORY_PATH}/index.md` and internalize it silently.

If context was already loaded by orient or another skill this session, skip this step. All `~/.claude/memory/` references below use the resolved memory path.

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

## Step 3b — Frontmatter-aware queries

When the user asks a question that maps to a frontmatter field, scan frontmatter directly instead of relying on content grep:

- "Who reports to me?" → grep `relationships/` for `relationship: reports-to-me`
- "Who's leaving?" / "Who's departing?" → grep for `status: departing`
- "Who's incoming?" → grep for `status: incoming`
- "Show me my peers" → grep for `relationship: peer`

```bash
grep -rl "relationship: {value}" ~/.claude/memory/relationships/ 2>/dev/null
```

**Default lifecycle filtering:** Relationship queries that don't specify a status exclude `status: former` and `status: archived` results. "Who reports to me?" returns `active`, `departing`, and `incoming` only. To include former or archived, the user must explicitly ask ("who used to report to me?", "show former team members"). Explicit status queries ("who's departing?") work as-is since the user specified the filter.

---

## Step 4 — Check YAML frontmatter

For any files not already caught by steps 2–3b, scan frontmatter fields directly — `name`, `type` — for matches against the query. Skip `relationship` and `status` fields for relationship files — Step 3b already handles those with lifecycle filtering semantics.

Pay particular attention to `status: active` when the user is asking about something ongoing in non-relationship files.

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

When displaying relationship results, include `relationship` and `status` from frontmatter if present:

```
relationships/kyla-kurstin.md — relationship (departing)
  Design and Web Lead, Marketing. Last day March 20, 2026.
```

**Sensitive content guardrail:** When selecting the 2-4 line excerpt for results, exclude content under `## Sensitive`. This section exists specifically for context that should not be surfaced unprompted. Only include sensitive content when the user explicitly asks about it — e.g., "what's sensitive about Kyla?", "what should I be careful about with X?", "anything I should know before meeting with Y?"

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
