# Installing Sidekick — Claude Code

A step-by-step guide to getting Sidekick running in Claude Code.

---

## What you'll need

- **Claude Code** installed and working on your computer. If you haven't set it up yet, follow [Anthropic's install guide](https://docs.anthropic.com/en/docs/claude-code/overview) first.

That's it. The install takes about a minute, and then Sidekick will walk you through a short setup.

---

## Step 1: Install the plugin

Open your terminal and run:

```
claude plugin install --marketplace https://github.com/cfitz-ops/sidekick
```

You should see a confirmation that the plugin was installed.

---

## Step 2: Start a new session

Open a new Claude Code session (or restart your current one). When the session starts, Sidekick will automatically begin its setup process.

**What you'll see:** Sidekick will ask you a few questions to get to know you — things like your role, the tools you use, and how you prefer to work with Claude. Just answer naturally. There are no wrong answers — this is how Sidekick starts building your memory.

If you already have Sidekick memory from another device, it will ask if you'd like to connect to an existing memory repo instead. If this is your first time, just answer the questions.

---

## Step 3: Verify it's working

After setup finishes, type:

```
/sidekick:status
```

You should see a memory dashboard that looks something like this:

```
Memory Status — ~/.claude/.sidekick/memory/
─────────────────────────────────────────────────────
Space           Files   Last Modified   Notes
─────────────────────────────────────────────────────
identity          3     2026-04-12
relationships     0     —
projects          0     —
decisions         0     —
patterns          0     —
knowledge         0     —
─────────────────────────────────────────────────────
Total             3 files
```

The identity files were created during setup. The other spaces will fill in as you use Claude — Sidekick picks up context from your conversations over time.

---

## A note about Claude's built-in memory

If you use Claude's own memory feature, Sidekick works alongside it — not instead of it. They're separate systems.

The key difference: when Sidekick saves something, it tells you exactly where — a specific file and memory space (like `identity/preferences.md`). Your Sidekick memory is just plain markdown files on your computer. You can read them, edit them, or delete them anytime.

---

## What's next

Head over to the [Usage Guide](usage-guide.md) to learn how Sidekick works day-to-day, what you can ask it to do, and tips for getting the most out of it.
