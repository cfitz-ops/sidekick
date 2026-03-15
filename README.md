# Sidekick

Sidekick is a Claude plugin that builds and maintains personal context across conversations. It stores memory as plain markdown in `~/.claude/memory/`, organized into six named spaces, so Claude always knows who you are and what you're working on — without you having to re-explain it every session.

Built for **Claude Code**. Cowork compatibility is untested — see [Platform Notes](#platform-notes) below.

---

## Quick Start

1. Install the plugin
2. Run `/sidekick:setup` to onboard and migrate any existing memory

That's it. Sidekick will auto-load your context at the start of each session.

---

## Skills

| Skill | Trigger | What it does |
|-------|---------|--------------|
| `/sidekick:setup` | First install, "get started" | Onboarding and migration |
| `/sidekick:orient` | Auto on session start | Loads your context |
| `/sidekick:remember` | "Remember that...", explicit | Saves context to memory |
| `/sidekick:reflect` | Session end, "let's wrap up" | Reviews session, proposes saves |
| `/sidekick:recall` | "What do I know about..." | Searches memory |
| `/sidekick:status` | "Memory status" | Shows memory dashboard |
| `/sidekick:sync` | Explicit | Cross-device git sync |

---

## Memory Structure

Memory lives in `~/.claude/memory/` and is organized into six spaces:

| Space | What goes here |
|-------|---------------|
| `identity/` | Who you are, roles, preferences |
| `relationships/` | People, teams, collaborators |
| `projects/` | Active and past projects |
| `decisions/` | Key choices and their rationale |
| `patterns/` | Habits, workflows, recurring context |
| `knowledge/` | Facts, references, domain notes |

An `index.md` hot cache gives Claude a fast summary without loading every file.

---

## Platform Notes

### Claude Code

Fully supported. SessionStart/Stop hooks auto-load context and prompt session reflection.

### Cowork

Sidekick works in Cowork with some differences from Claude Code:

**Setup:**
1. Install the plugin in Cowork
2. Select a folder in Cowork's file picker — Sidekick stores memory in `.sidekick-memory/` inside this folder
3. Run `/sidekick:setup` to onboard

**What works:**
- All skills (`/sidekick:orient`, `/sidekick:remember`, `/sidekick:recall`, `/sidekick:reflect`, `/sidekick:status`)
- Memory persistence (requires a selected folder — files persist on your machine via VirtioFS)
- Git sync (`/sidekick:sync`) with PAT-based HTTPS authentication

**Differences from Claude Code:**
- **First session:** Hooks can't auto-detect the mounted folder path. Run `/sidekick:setup` or `/sidekick:orient` to configure — this persists for the rest of the session.
- **No auto-reflect** — SessionStop hooks may not fire. Run `/sidekick:reflect` before ending a session.
- **Authentication** — SSH keys and interactive git credentials are not available in the Cowork VM. Use HTTPS URLs with a personal access token for git sync.
- **Memory location** — Memory is stored in your selected folder at `.sidekick-memory/` instead of `~/.claude/memory/`.

**Without a folder selected:** Sidekick works within a single session but memory does not persist. You'll be warned at setup time and can select a folder at any point.

---

## Cross-Device Sync

Opt in during `/sidekick:setup`. Sidekick can back up and sync your memory directory via git, so your context follows you across machines. Run `/sidekick:sync` at any time to push or pull.

---

## License

MIT
