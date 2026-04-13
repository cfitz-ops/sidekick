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
- **Identity context:** role changes, background, or standing preferences that define who the user is across projects and conversations. Routes to `identity/`.
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

---

## Step 3 — Present proposal

Display the categorized proposal grouped by memory space. Show only populated sections — omit empty categories. If no candidates qualify, say: "Nothing worth saving from this call." and stop.

All sections that may appear: Relationships, Projects, Decisions, Identity, Patterns, Knowledge, Also Noticed, Sensitive. The `---` dividers appear before Also Noticed and before Sensitive to visually separate the tiers. The attendees line is included only if attendees were provided or inferred.

Use this format:

```
Extracted from pasted call content with {attendees}:

## Relationships
1. Alex Chen — new → relationships/alex-chen.md
   Senior engineer on the platform team, working with you on the data pipeline migration.
2. Kyla Kurstin — update → relationships/kyla-kurstin.md
   Wrapping up the design system handoff before her last day.

## Projects
3. Data pipeline migration — new → projects/data-pipeline-migration.md
   Moving from batch ETL to streaming; Alex owns the backend, you own stakeholder communication.

## Decisions
4. Chose Kafka over RabbitMQ — new → decisions/chose-kafka.md
   Selected for throughput at scale; RabbitMQ was simpler but could not handle projected volume.

---

## Also Noticed
5. Alex Chen — possible update → relationships/alex-chen.md
   May be moving to the infrastructure team; mentioned in passing and not confirmed.

---

## Sensitive
6. Kyla Kurstin — sensitive update → relationships/kyla-kurstin.md
   Frustrated with the transition timeline and prefers not to discuss it publicly.
   Would be stored in `## Sensitive` and not surfaced by recall unless explicitly asked.

---

Save all, pick by number, approve by section, approve sensitive separately, or skip.
Examples: `all`, `1 3`, `1-3`, `relationships + decisions`, `sensitive 6`, `all + sensitive`, `skip`
```

Wait for the user's response before writing anything.

---

## Step 4 — Process approval

Parse the user's response:

- `all` — saves normal and lower-confidence items only, not sensitive
- `all + sensitive` — saves everything including sensitive items
- Section names (e.g., `relationships + decisions`) — saves all items in those sections. Requires explicit `sensitive` to include the sensitive section.
- Numbered picks (`1 3`, `1-3`) — saves specific items regardless of tier
- `sensitive {N}` — approves a specific sensitive item
- `{N} save normally` — moves a sensitive item to the normal tier
- `{N} save as sensitive` — moves a normal or lower-confidence item to the sensitive tier. Only valid for items that map to a relationship file. If the item does not map to a relationship file, reject the request and explain why.
- `for #{N}, {correction}` — apply the correction to the candidate before writing
- `skip` — saves nothing

For edits, apply the correction to the candidate before writing. For reclassifications, update the candidate's tier and target section accordingly. If the response does not match a recognized pattern, ask the user to clarify before writing.

---

## Step 5 — Write approved items

Follow `remember` Step 2–6 semantics for each approved item:

- **Routing:** Use the proposed path unless the item was edited, reclassified, or clearly conflicts with `remember`'s routing rules. In those cases, `remember`'s routing rules are authoritative.
- **Deduplication:** Check for an existing file in the target space. If found, update it and preserve the existing file structure — append or revise the relevant section rather than rewriting the whole file. If not found, create a new file using the appropriate template from `templates/`.
- **Writing:** Use the matching template and apply template overrides such as relationship frontmatter and goals structure.
- **Sensitive writes:** If the user approved an item as sensitive, write it only to the `## Sensitive` section of the target relationship file. Do not create sensitive sections in other memory types. Sensitive items require explicit approval — never via plain `all`.
- **Confirmation:** Output one line per write: `Saved: {summary} → {path}`
- **Index updates:** Update `index.md` only when the save is significant under `remember` Step 6 rules (new project, new key relationship, identity-level change).

After all writes, output: `Ingested: {N} items saved from call with {attendees}.` Omit the attendees clause if attendees are unknown.

`ingest` does not:
- Store the raw transcript
- Create new memory spaces or new template types
- Change `remember`'s routing or write rules

---

## Step 6 — Done

Do not store the raw transcript. If the user wants to process another call, they invoke the skill again.
