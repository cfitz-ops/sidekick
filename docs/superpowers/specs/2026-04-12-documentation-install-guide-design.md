# Sidekick Documentation & Install Guide — Design Spec

**Date:** 2026-04-12
**Branch:** `docs/install-guide`
**Status:** Approved

## Goal

Create user-facing documentation that enables someone new to Claude plugins (but familiar with Claude itself) to install and use Sidekick on either Claude Code or Cowork (Claude Desktop). This is preparation for sharing Sidekick beyond the original author.

## Audience

- People who use Claude but may be new to plugins, Claude Code, or Cowork
- Includes non-technical users (first target user: the author's father)
- Tone: conversational, beginner-friendly, no assumed plugin knowledge

## Deliverables

### 1. README.md (rewrite)

Rewrite the existing README as a welcoming landing page. It should:

- Open with a plain-language explanation of what Sidekick does ("gives Claude a memory that persists across conversations")
- Include a brief "who it's for" line
- Replace the current Quick Start with two clear paths: "Using Claude Code?" and "Using Cowork?" — each linking to the respective install guide. No install commands in the README itself.
- Keep the skills table but reframe around user actions ("save something to memory," "search what Claude remembers") rather than skill/trigger terminology
- Keep the memory structure directory tree (it's helpful) with a brief plain-language explanation of each space
- Remove platform-specific technical details (those live in install guides)
- Add an "Advanced" section linking to sync setup, contributing, etc.
- Keep MIT license mention

### 2. docs/install-claude-code.md

Self-contained install guide for Claude Code users. Structure:

1. **Prerequisites** — Claude Code installed and working. Link to Anthropic's install docs.
2. **Install the plugin** — The `claude plugin install` command pointing to the GitHub repo.
3. **First launch** — What happens when you start a new session after install: SessionStart hook fires, `/sidekick:setup` runs onboarding, walks through identity creation. Describe what the user will see.
4. **Verify it's working** — Use a Sidekick-specific action (e.g., `/sidekick:status`) so there's no ambiguity with Claude's built-in memory. The user should see their memory dashboard with the files created during setup.
5. **Sidekick vs Claude's memory** — Short callout explaining: Sidekick works alongside Claude's built-in memory, not instead of it. Key difference: Sidekick confirms saves with a file path and memory space. Sidekick memory is yours — plain markdown files you can read, edit, or delete.
6. **What's next** — Link to the usage guide.

Each step tells the user what to do AND what they should see happen.

### 3. docs/install-cowork.md

Self-contained install guide for Cowork (Claude Desktop) users. Structure:

1. **Prerequisites** — A Claude account with Cowork/Claude Desktop access.
2. **Install the plugin** — Two options:
   - **Option A (recommended):** Customize → Personal Plugins → Browse Plugins → Personal Tab → Add Marketplace → paste the GitHub repo URL.
   - **Option B:** Download the `.zip` from GitHub → Customize → Personal Plugins → Upload Plugin.
3. **Set up your project folder** — Explain that without sync, Cowork ties memory to the project folder. Recommend creating a dedicated folder (e.g., `sidekick-memory` on Desktop). Instruct: create the folder, open Cowork with it, always use this folder for Sidekick.
4. **First launch** — Same flow as Claude Code: setup runs, walks through identity creation. Describe what the user will see.
5. **Verify it's working** — Same Sidekick-specific verification as the Claude Code guide.
6. **Sidekick vs Claude's memory** — Same short callout as the Claude Code guide.
7. **Optional: Set up sync** — Framed as "you can do this later." For users who want memory to persist across devices or not be tied to one project folder. Covers: create a private GitHub repo, generate a PAT, configure sync via `/sidekick:sync`. Clear about why (portability) and the trade-off (more setup steps).
8. **What's next** — Link to the usage guide.

### 4. docs/usage-guide.md

Shared guide for all platforms covering day-to-day usage. Structure:

1. **How Sidekick works** — Plain-language explanation of the six memory spaces (identity, relationships, projects, decisions, patterns, knowledge). Brief description of each with an example of what goes there.
2. **Day-to-day usage** — Most usage is passive. Sidekick listens for context worth saving and captures it automatically. At session start it loads what it knows. At session end it reviews the conversation for anything new.
3. **Skills reference** — Each skill explained from the user's perspective:
   - **Setup** — First-run onboarding (they've already done this during install)
   - **Orient** — Happens automatically at session start, loads context
   - **Remember** — "Remember that..." or `/sidekick:remember` for explicit saves
   - **Recall** — "What do I know about..." or `/sidekick:recall` to search memory
   - **Reflect** — End-of-session review, happens automatically or via `/sidekick:reflect`
   - **Status** — `/sidekick:status` to see what's in memory
   - **Sync** — `/sidekick:sync` to push/pull across devices (references optional sync from install guides)
4. **Tips** — Practical tips:
   - You can ask Sidekick to forget something too
   - Memory builds over time — more useful the more you use it
   - You can browse/edit your memory files directly (they're just markdown)

## Scope

### In scope
- The four deliverables above
- All content is documentation only (markdown files)

### Out of scope
- Existing internal docs (`docs/plans/`, test logs, architecture proposals) — untouched
- CLAUDE.md — stays as-is (contributor/Claude instructions, not user-facing)
- COWORK-COMPATIBILITY.md — stays as-is
- Skill SKILL.md files — no changes (Claude's instructions, not user docs)
- Templates, hooks, plugin config — no changes
- No code or plugin changes
- No changelog (not part of this effort)

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Separate install guides per platform | Claude Code and Cowork have meaningfully different install flows. Separate guides avoid "skip to step X" branching and let you hand someone exactly the right link. |
| README as landing page, not comprehensive doc | Keeps the first impression clean. Users find what they need in 30 seconds and click through to details. |
| Sidekick vs Claude memory callout in install guides | Users may have Claude's built-in memory enabled. Addressing this early prevents confusion during verification. |
| Git sync as optional/advanced in Cowork guide | Most new users don't need cross-device sync on day one. Presenting it as required would add friction to an already-new experience. |
| Project folder guidance for Cowork (no-sync path) | Without sync, memory is tied to the project folder. Users need to know this upfront to avoid losing context. |
| Conversational tone throughout | Primary audience includes non-technical users. Plugin jargon and CLI assumptions would be barriers. |
