# Installing Sidekick — Cowork (Claude Desktop)

A step-by-step guide to getting Sidekick running in Cowork.

---

## What you'll need

- A Claude account with access to **Cowork** (Claude's desktop app)

That's it. The install takes a couple of minutes, and then Sidekick will walk you through a short setup.

---

## Step 1: Install the plugin

Open Cowork and follow these steps:

1. Click **Customize** in the left sidebar
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
