# Sidekick

Sidekick is a Claude plugin that builds and maintains personal context across conversations. It stores memory as plain markdown in a `.sidekick/` directory, organized into six named spaces, so Claude always knows who you are and what you're working on — without you having to re-explain it every session.

Works in both **Claude Code** and **Cowork** — see [Platform Notes](#platform-notes) below.

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

Sidekick stores everything in a `.sidekick/` directory:

- **Claude Code:** `~/.claude/.sidekick/`
- **Cowork:** `{your-selected-folder}/.sidekick/`

```
.sidekick/
├── config.yml          # Settings (git remote, sync preferences)
├── credentials         # GitHub PAT (gitignored)
├── .gitignore          # Credential safety
├── hooks/pre-commit    # Blocks accidental PAT commits
└── memory/
    ├── index.md        # Hot cache summary
    ├── identity/       # Who you are, roles, preferences
    ├── relationships/  # People, teams, collaborators
    ├── projects/       # Active and past projects
    ├── decisions/      # Key choices and rationale
    ├── patterns/       # Habits, workflows
    └── knowledge/      # Facts, references, domain notes
```

An `index.md` hot cache gives Claude a fast summary without loading every file.

---

## Platform Notes

### Claude Code

Fully supported. SessionStart/Stop hooks auto-load context and prompt session reflection.

### Cowork

**Setup:**
1. Install the plugin in Cowork
2. Run `/sidekick:setup` — you'll be prompted to select a folder
3. If you have an existing memory repo, provide the URL and a GitHub PAT during setup

**What works:**
- All skills
- Memory persistence via your selected folder
- Git sync with stored credentials (no re-entering PAT each session)
- Auto-pull on session start (configurable in `.sidekick/config.yml`)

**Differences from Claude Code:**
- **Folder selection required** — memory lives in your selected folder at `.sidekick/`
- **PAT-based auth** — SSH and interactive credentials are not available in the Cowork VM
- **No auto-reflect** — Run `/sidekick:reflect` before ending a session

**Credential safety:** Your GitHub PAT is stored locally in `.sidekick/credentials`, which is gitignored. A pre-commit hook blocks accidental commits containing tokens.

---

## Cross-Device Sync

Opt in during `/sidekick:setup`. Sidekick can back up and sync your memory directory via git, so your context follows you across machines. Run `/sidekick:sync` at any time to push or pull.

---

## License

MIT
