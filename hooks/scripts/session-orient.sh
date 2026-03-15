#!/bin/bash
MEMORY_DIR="${SIDEKICK_MEMORY_DIR:-$HOME/.claude/memory}"
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
