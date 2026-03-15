# Sidekick

Sidekick is a Claude plugin that builds and maintains personal context across conversations. It stores memory as plain markdown in `~/.claude/memory/`, organized into six named spaces, so Claude always knows who you are and what you're working on — without you having to re-explain it every session.

Works in both **Claude Code** and **Cowork**.

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

## Cross-Device Sync

Opt in during `/sidekick:setup`. Sidekick can back up and sync your memory directory via git, so your context follows you across machines. Run `/sidekick:sync` at any time to push or pull.

---

## License

MIT
