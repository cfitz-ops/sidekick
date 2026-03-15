#!/bin/bash
MEMORY_DIR="$HOME/.claude/memory"

if [ -d "$MEMORY_DIR" ] && [ -f "$MEMORY_DIR/index.md" ]; then
  cat <<'EOF'
{"decision": "block", "reason": "Session reflection: review this conversation for context worth saving to memory. Propose any new memories as a batch for the user to approve. If nothing noteworthy, proceed to exit."}
EOF
else
  cat <<'EOF'
{"decision": "approve"}
EOF
fi
