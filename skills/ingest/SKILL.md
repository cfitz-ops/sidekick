---
name: ingest
description: |
  Process pasted call transcripts, meeting notes, or summaries into durable Sidekick
  memory candidates. Trigger when the user says /sidekick:ingest, "process this call",
  "process this transcript", "process these meeting notes", or asks to extract memory
  from external conversation content. Proposes durable memory saves only — not meeting
  minutes, action items, or full notes.
---

## Step 0 — Ensure context is loaded

If context has not already been loaded this session (i.e., orient has not run), resolve the memory path and load context now:

1. Find `.sidekick/config.yml` in the current working directory, or check `~/.claude/.sidekick/config.yml`, or use `SIDEKICK_MEMORY_DIR`. See orient Step 0 for the full detection logic.
2. Read `{MEMORY_PATH}/index.md` and internalize it silently.

If context was already loaded by orient or another skill this session, skip this step. All `~/.claude/memory/` references below use the resolved memory path.

---

## Step 1 — Accept input

The user pastes a transcript, summary, or meeting notes. If attendee attribution is unclear from the pasted content, ask: "Who was on this call? (optional — helps with attribution)." If attendees were provided inline or are clear from the content, skip the question.
