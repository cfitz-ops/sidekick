# CLAUDE.md

## What is this project?

Sidekick is a Claude plugin that provides persistent personal memory across conversations. It stores context as markdown files in a `.sidekick/` directory, organized into six spaces (identity, relationships, projects, decisions, patterns, knowledge). Works in both Claude Code and Cowork.

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
templates/          # Templates for memory files, config, gitignore, pre-commit hook
docs/               # Environment detection reference, plans, test logs
```

## Key conventions

- Memory path resolved from `.sidekick/config.yml`, `SIDEKICK_MEMORY_DIR` env var, or defaults to `~/.claude/.sidekick/memory/`.
- Skills are markdown instruction files, not executable code.
- Sidekick owns personal identity and cross-workspace context. It defers workspace-scoped shorthand (acronyms, codenames, task tracking) to workspace plugins if present.
- Keep skills concise — Claude reads them at invocation time.
