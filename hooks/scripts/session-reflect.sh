#!/bin/bash

# Resolve memory directory: explicit override > default
# In Cowork without SIDEKICK_MEMORY_DIR, skip reflection (no persistent memory to check)
if [ -n "$SIDEKICK_MEMORY_DIR" ]; then
  MEMORY_DIR="$SIDEKICK_MEMORY_DIR"
elif [ "$CLAUDE_CODE_IS_COWORK" = "1" ]; then
  # No memory dir configured in Cowork — nothing to reflect on
  cat <<'EOF'
{"decision": "approve"}
EOF
  exit 0
else
  MEMORY_DIR="$HOME/.claude/memory"
fi

LOCK_FILE="/tmp/sidekick-reflect-$$"

# Prevent infinite loop: only fire once per session
# Check for any existing lock file from this parent process
PARENT_PID=$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')
LOCK_FILE="/tmp/sidekick-reflect-${PARENT_PID}"

if [ -f "$LOCK_FILE" ]; then
  # Already reflected this session — approve exit
  cat <<'EOF'
{"decision": "approve"}
EOF
  exit 0
fi

if [ -d "$MEMORY_DIR" ] && [ -f "$MEMORY_DIR/index.md" ]; then
  # Set lock before blocking so re-trigger sees it
  touch "$LOCK_FILE"
  cat <<'EOF'
{"decision": "block", "reason": "Session reflection: review this conversation for context worth saving to memory. Propose any new memories as a batch for the user to approve. If nothing noteworthy, proceed to exit."}
EOF
else
  cat <<'EOF'
{"decision": "approve"}
EOF
fi
