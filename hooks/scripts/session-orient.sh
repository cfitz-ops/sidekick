#!/bin/bash

# Resolve memory directory: explicit override > config file > Cowork detection > default
if [ -n "$SIDEKICK_MEMORY_DIR" ]; then
  MEMORY_DIR="$SIDEKICK_MEMORY_DIR"
elif [ -f ".sidekick/config.yml" ]; then
  # Config in current working directory — use its memory path
  MEMORY_DIR="$(pwd)/.sidekick/memory"
elif [ "$CLAUDE_CODE_IS_COWORK" = "1" ]; then
  # In Cowork without config in cwd — prompt user
  echo "## Sidekick"
  echo "Cowork detected. Run /sidekick:setup to configure memory storage, or /sidekick:orient to load existing memory."
  exit 0
elif [ -f "$HOME/.claude/.sidekick/config.yml" ]; then
  # Claude Code with new config layout
  MEMORY_DIR="$HOME/.claude/.sidekick/memory"
elif [ -d "$HOME/.claude/memory" ]; then
  # Claude Code legacy layout
  MEMORY_DIR="$HOME/.claude/memory"
else
  echo "## Sidekick"
  echo "No memory found. Run /sidekick:setup to get started."
  exit 0
fi

INDEX="$MEMORY_DIR/index.md"

if [ -f "$INDEX" ]; then
  echo "## Sidekick Context (auto-loaded)"
  echo ""
  cat "$INDEX"
  echo ""
  echo "---"
  echo "Proactive capture is active. Save noteworthy context automatically. Use /sidekick:remember for explicit saves, /sidekick:reflect at session end."
else
  echo "## Sidekick"
  echo "No memory found. Run /sidekick:setup to get started."
fi
