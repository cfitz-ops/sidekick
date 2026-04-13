# Using Sidekick

Now that Sidekick is installed, here's how it works and what you can do with it.

---

## How Sidekick works

Sidekick stores what it learns about you as plain markdown files, organized into six spaces:

| Space | What goes here | Example |
|-------|---------------|---------|
| **Identity** | Who you are, your role, preferences | "I'm a marketing manager who prefers concise responses" |
| **Relationships** | People you work with, teams, collaborators | "Jordan is my tech lead, started in January" |
| **Projects** | What you're working on, active and past | "Website redesign — launching Q2, using Contentful" |
| **Decisions** | Key choices and the reasoning behind them | "Went with Postgres over MySQL because of JSON support" |
| **Patterns** | Your habits, workflows, recurring processes | "Weekly team sync every Monday at 10am" |
| **Knowledge** | Facts, references, domain-specific notes | "Our API rate limit is 1000 requests/minute" |

You don't need to organize anything yourself — Sidekick decides which space fits based on the context.

---

## Day-to-day usage

Most of the time, you don't need to do anything special. Sidekick works in the background:

- **When you start a session**, Sidekick loads what it knows about you so Claude has context from the beginning.
- **During a session**, Sidekick listens for things worth remembering — your role, your preferences, people you mention, projects you're working on. When it saves something, it tells you.
- **When you end a session**, Sidekick reviews the conversation for any context it might have missed and offers to save it.

Over time, your memory fills in naturally. The more you use Claude, the more useful Sidekick becomes.

---

## What you can ask Sidekick to do

### Save something to memory

Say "remember that..." or use `/sidekick:remember` to explicitly save a piece of context.

> "Remember that our fiscal year starts in February"
>
> "Remember that Sarah prefers Slack over email"

Sidekick will confirm what it saved and where.

### Search your memory

Say "what do I know about..." or use `/sidekick:recall` to search across everything Sidekick has stored.

> "What do I know about the website redesign?"
>
> "Who is Jordan?"

### Check what's in your memory

Use `/sidekick:status` to see a dashboard of your memory — how many files are in each space, when they were last updated, and whether anything looks stale.

### Review a session before closing

Use `/sidekick:reflect` to review the current conversation for anything worth saving. This happens automatically at the end of a session in Claude Code, but in Cowork you'll want to run it manually before closing.

### Sync across devices

Use `/sidekick:sync` to push or pull your memory to a private GitHub repo. This is only relevant if you've set up sync — see the install guides for details.

### Re-run setup

Use `/sidekick:setup` if you need to reconfigure Sidekick, connect to an existing memory repo, or start fresh.

---

## Tips

- **You can ask Sidekick to forget things too.** Just say "forget that..." or "delete the memory about..." and Sidekick will remove it.
- **Memory builds over time.** Your first few sessions will have sparse memory. After a week or two of regular use, Claude will have a much richer picture of who you are and what you're working on.
- **Your memory files are just markdown.** You can browse them, edit them, or delete them directly. In Claude Code, they live at `~/.claude/.sidekick/memory/`. In Cowork, they're in your project folder at `.sidekick/memory/`.
- **Sidekick is not a chatbot.** It doesn't change how Claude talks to you — it just gives Claude more context about you. Think of it as Claude's notebook about you.
