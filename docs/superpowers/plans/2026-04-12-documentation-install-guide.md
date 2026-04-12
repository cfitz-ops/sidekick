# Sidekick Documentation & Install Guide — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create four user-facing documentation files (README rewrite, two install guides, usage guide) so newcomers can install and use Sidekick without prior Claude plugin knowledge.

**Architecture:** All deliverables are markdown files. No code changes. The README links to the install guides, the install guides link to the usage guide. Each install guide is self-contained for its platform.

**Tech Stack:** Markdown, git

---

### Task 1: Write the Claude Code install guide

**Files:**
- Create: `docs/install-claude-code.md`

- [ ] **Step 1: Create `docs/install-claude-code.md`**

Write the full Claude Code install guide. The guide must be self-contained, conversational, and assume no plugin knowledge. Use this exact structure and content:

```markdown
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
```

- [ ] **Step 2: Review the file**

Read `docs/install-claude-code.md` back and verify:
- All links are relative and correct (`usage-guide.md` is in the same `docs/` directory)
- The install command references the correct GitHub org/repo (`cfitz-ops/sidekick`)
- Tone is conversational and beginner-friendly
- No jargon left unexplained

- [ ] **Step 3: Commit**

```bash
git add docs/install-claude-code.md
git commit -m "docs: add Claude Code install guide"
```

---

### Task 2: Write the Cowork install guide

**Files:**
- Create: `docs/install-cowork.md`

- [ ] **Step 1: Create `docs/install-cowork.md`**

Write the full Cowork install guide. Same tone as the Claude Code guide — self-contained, conversational, no assumed plugin knowledge. Use this exact structure and content:

```markdown
# Installing Sidekick — Cowork (Claude Desktop)

A step-by-step guide to getting Sidekick running in Cowork.

---

## What you'll need

- A Claude account with access to **Cowork** (Claude's desktop app)

That's it. The install takes a couple of minutes, and then Sidekick will walk you through a short setup.

---

## Step 1: Install the plugin

Open Cowork and follow these steps:

1. Click **Customize** (gear icon in the bottom left)
2. Go to **Personal Plugins**
3. Click **Browse Plugins**
4. Switch to the **Personal** tab
5. Click **Add Marketplace**
6. Paste this URL: `https://github.com/cfitz-ops/sidekick`
7. Click **Add**

**Alternative:** If you prefer, you can download the plugin as a `.zip` file from [GitHub](https://github.com/cfitz-ops/sidekick), then use **Customize → Personal Plugins → Upload Plugin** to install it.

---

## Step 2: Set up your project folder

Sidekick stores your memory inside the project folder you use with Cowork. To make sure your memory sticks around between sessions, you should create a dedicated folder for it.

1. Create a new folder somewhere easy to find — for example, a folder called `sidekick-memory` on your Desktop
2. In Cowork, open this folder as your project
3. **Use this same folder every time** you want Sidekick to remember your context

> **Why?** Without sync (which is optional — see below), Cowork can only access memory that's inside your current project folder. Using the same folder each time means Sidekick always finds your memory.

---

## Step 3: Start a new session

Start a new Cowork session with your project folder selected. Sidekick will automatically begin its setup process.

**What you'll see:** Sidekick will ask you a few questions to get to know you — things like your role, the tools you use, and how you prefer to work with Claude. Just answer naturally. There are no wrong answers — this is how Sidekick starts building your memory.

---

## Step 4: Verify it's working

After setup finishes, type:

```
/sidekick:status
```

You should see a memory dashboard showing your identity files (created during setup) and empty spaces that will fill in over time as you use Claude.

---

## A note about Claude's built-in memory

If you use Claude's own memory feature, Sidekick works alongside it — not instead of it. They're separate systems.

The key difference: when Sidekick saves something, it tells you exactly where — a specific file and memory space (like `identity/preferences.md`). Your Sidekick memory is just plain markdown files. You can read them, edit them, or delete them anytime.

---

## Optional: Set up sync

> You can skip this entirely and come back to it later. Sidekick works fine without sync.

By default, your Sidekick memory lives only in your project folder. If you want your memory to carry across devices — or if you'd rather not have to use the same project folder every time — you can set up sync.

Sync uses a private GitHub repository to store your memory. Here's what you'll need:

1. **A GitHub account** (free is fine)
2. **A private repository** to store your memory (you'll create this)
3. **A Personal Access Token (PAT)** so Sidekick can read and write to the repo

When you're ready, run `/sidekick:sync` in a Cowork session and Sidekick will walk you through the setup. You can also set this up during initial setup if you already have a memory repo from another device.

---

## What's next

Head over to the [Usage Guide](usage-guide.md) to learn how Sidekick works day-to-day, what you can ask it to do, and tips for getting the most out of it.
```

- [ ] **Step 2: Review the file**

Read `docs/install-cowork.md` back and verify:
- All links are relative and correct
- The GitHub URL references the correct org/repo
- The Cowork install steps match the actual UI flow (Customize → Personal Plugins → Browse Plugins → Personal Tab → Add Marketplace)
- Tone matches the Claude Code guide
- Project folder guidance is clear and upfront

- [ ] **Step 3: Commit**

```bash
git add docs/install-cowork.md
git commit -m "docs: add Cowork install guide"
```

---

### Task 3: Write the usage guide

**Files:**
- Create: `docs/usage-guide.md`

- [ ] **Step 1: Create `docs/usage-guide.md`**

Write the shared usage guide covering day-to-day usage across both platforms. Use this exact structure and content:

```markdown
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
```

- [ ] **Step 2: Review the file**

Read `docs/usage-guide.md` back and verify:
- All seven skills are covered (setup, orient, remember, recall, reflect, status, sync)
- Orient is described as automatic, not as something the user invokes
- Cowork-specific note about manual reflect is included
- Memory file paths match actual locations (`~/.claude/.sidekick/memory/` for Claude Code, `.sidekick/memory/` for Cowork)
- Tone is consistent with install guides

- [ ] **Step 3: Commit**

```bash
git add docs/usage-guide.md
git commit -m "docs: add usage guide for day-to-day Sidekick usage"
```

---

### Task 4: Rewrite the README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Rewrite `README.md`**

Replace the full contents of `README.md` with the new landing-page version. Use this exact content:

```markdown
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
```

- [ ] **Step 2: Review the file**

Read `README.md` back and verify:
- Links to install guides and usage guide are correct relative paths
- No install commands appear in the README itself
- Skills table is reframed around user actions, not skill/trigger terminology
- Directory tree is present with plain-language descriptions
- Platform-specific details are absent (they're in install guides now)
- Tone is welcoming and jargon-free

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README as beginner-friendly landing page"
```

---

### Task 5: Final review

**Files:**
- Review: `README.md`, `docs/install-claude-code.md`, `docs/install-cowork.md`, `docs/usage-guide.md`

- [ ] **Step 1: Verify all cross-links**

Check every link in all four files:
- `README.md` links to `docs/install-claude-code.md`, `docs/install-cowork.md`, `docs/usage-guide.md`
- `docs/install-claude-code.md` links to `docs/usage-guide.md` (relative: `usage-guide.md`)
- `docs/install-cowork.md` links to `docs/usage-guide.md` (relative: `usage-guide.md`)
- No broken or dangling links

Run:
```bash
grep -rn '\[.*\](.*\.md)' README.md docs/install-claude-code.md docs/install-cowork.md docs/usage-guide.md
```

Verify each target file exists at the referenced path.

- [ ] **Step 2: Verify consistency**

Check that:
- The GitHub repo URL is `https://github.com/cfitz-ops/sidekick` in both install guides
- Memory paths are consistent: `~/.claude/.sidekick/memory/` for Claude Code, `.sidekick/memory/` in project folder for Cowork
- The "Sidekick vs Claude's memory" callout says the same thing in both install guides
- All seven skills are mentioned in the usage guide
- The skills table in the README matches the capabilities described in the usage guide

- [ ] **Step 3: Read through as a newcomer**

Read all four docs end-to-end in user order:
1. README → click Cowork install guide
2. Cowork install guide → click usage guide
3. Back to README → click Claude Code install guide
4. Claude Code install guide → click usage guide

Flag any moment where a newcomer would be confused, stuck, or missing context.

- [ ] **Step 4: Fix any issues found**

If any issues were found in steps 1-3, fix them and commit:

```bash
git add -A
git commit -m "docs: fix issues from final review"
```

If no issues, skip this step.
