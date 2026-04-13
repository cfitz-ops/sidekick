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

---

## Step 2 — Extract and reconcile candidates

Scan the pasted content for durable memory candidates. Apply these rules more strictly than `reflect` — transcripts and meeting notes contain more noise than live conversation. The test: would this still be useful in a future conversation?

### What to extract

- **People context:** role, team, relationship to the user, and factual status changes such as joining, leaving, or moving teams. Factual status changes are normal candidates — they update the `status` frontmatter field in relationship files. Interpersonal context around those changes (frustration, private concerns, dynamics the person would not want surfaced) belongs in the sensitive tier instead.
- **Project updates:** durable status shifts, meaningful blockers, timeline changes, scope decisions, or ownership changes. Skip routine standup noise.
- **Decisions:** choices made with rationale, especially when alternatives were discussed.
- **Preferences and patterns:** working style or communication preferences revealed clearly in conversation.
- **Knowledge:** institutional or tribal knowledge shared verbally that is not already in Sidekick memory.

### What to skip

- Action items, follow-ups, and to-dos
- Scheduling logistics
- Small talk, filler, and off-topic tangents
- Speculative statements unless the user later confirmed intent or a decision
- Anything already in memory
- Raw quotes from the transcript; paraphrase instead
- Credentials, tokens, passwords, API keys, or similarly sensitive secrets

### Classify each candidate

- **Normal:** Explicit statements of fact, confirmed decisions, clear role/status changes, or direct preference statements.
- **Lower confidence:** Implied context, uncertain attribution, indirect signals, or things said in passing. Put these in a separate "Also Noticed" section the user can approve or ignore.
- **Sensitive:** Context that relates to a specific person and would materially help future interactions, but should not be surfaced unprompted. Must map to a relationship file — `## Sensitive` sections exist only in relationship files. If a sensitive fact does not map to a relationship (e.g., a confidential project detail), skip it or propose it as a normal item in the appropriate space — do not surface it in the Sensitive tier.

Valid sensitive examples: interpersonal dynamics the user should be careful with, known frustrations or preferences shared privately, organizational context that should not be surfaced unprompted.

**Do not propose as sensitive:**
- Credentials, tokens, passwords, API keys, or secrets
- Gossip, rumor, or unverified claims
- Content whose attribution is unclear
- Raw quotes from the transcript
- Facts that do not map to a specific person's relationship file

**Attribution guardrail:** If speaker attribution is uncertain, do not place the item in the normal tier. Put it in the lower-confidence section or skip it.

### Reconcile against existing memory

For each candidate, check existing memory files in the target space to determine whether this is a new entry or an update to an existing file. Read likely matching files when relevant — not just the index. Label each candidate as "new" or "update" and assign a target path.
