# Sidekick

**Sidekick gives Claude a memory that persists across conversations.**

Every time you start a new session, Claude starts from scratch — it doesn't remember who you are, what you're working on, or how you like to work. Sidekick fixes that. It saves context as plain markdown files so Claude always has your history, preferences, and ongoing work at hand.

Built for anyone who uses Claude regularly and wants it to know them over time.

---

## Get started

Choose your platform:

- **Using Claude Code?** → [Install guide for Claude Code](docs/install-claude-code.md)
- **Using Cowork (Claude Desktop)?** → [Install guide for Cowork](docs/install-cowork.md)

---

## What Sidekick can do

| Action | How | What happens |
|--------|-----|-------------|
| Save something to memory | "Remember that..." | Sidekick saves it to the right memory space and confirms |
| Search your memory | "What do I know about...?" | Sidekick searches across everything it's stored |
| Check your memory | `/sidekick:status` | See a dashboard of what's in each memory space |
| Review a session | `/sidekick:reflect` | Review the conversation for anything worth saving |
| Sync across devices | `/sidekick:sync` | Push/pull memory to a private GitHub repo |

Most of the time you don't need to do anything — Sidekick captures context automatically from your conversations. See the [Usage Guide](docs/usage-guide.md) for the full details.

---

## How memory is organized

Sidekick stores everything as markdown files in six spaces:

```
.sidekick/memory/
├── index.md        # Quick summary of everything
├── identity/       # Who you are, your role, preferences
├── relationships/  # People you work with
├── projects/       # What you're working on
├── decisions/      # Key choices and rationale
├── patterns/       # Your habits and workflows
└── knowledge/      # Facts, references, domain notes
```

These are your files — you can read, edit, or delete them anytime. Nothing is hidden or locked away.

---

## Advanced

- **Cross-device sync** — Back up and sync your memory across machines via a private GitHub repo. See the sync section in your platform's install guide.
- **Contributing** — Sidekick is open source under the MIT license. Issues and PRs welcome.

---

## License

MIT
