# CLAUDE.md

## What is this project?

Sidekick is a Claude plugin that provides persistent personal memory across conversations. It stores context as markdown files in `~/.claude/memory/`, organized into six spaces (identity, relationships, projects, decisions, patterns, knowledge).

## Branching and commits

- **Never push directly to main.** All changes go through feature branches and pull requests.
- Branch naming: `feature/short-description`, `fix/short-description`, `docs/short-description`
- Keep PRs focused — one feature or fix per branch.
- Write concise commit messages that explain why, not what.

## Project structure

```
.claude-plugin/     # Plugin metadata (plugin.json, marketplace.json)
hooks/              # SessionStart/Stop hooks and bash scripts
skills/             # Skill definitions (SKILL.md files)
templates/          # Markdown templates for memory files
```

## Key conventions

- Memory path is configurable via `SIDEKICK_MEMORY_DIR` env var, defaulting to `~/.claude/memory/`.
- Skills are markdown instruction files, not executable code.
- Sidekick owns personal identity and cross-workspace context. It defers workspace-scoped shorthand (acronyms, codenames, task tracking) to workspace plugins if present.
- Keep skills concise — Claude reads them at invocation time.
