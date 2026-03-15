# Environment Detection

Sidekick runs in two environments with different persistence models.

## Detection Logic

Check in this order:

1. **Explicit override:** If `SIDEKICK_MEMORY_DIR` is set, use it. No further detection needed.
2. **Cowork detection:** If `CLAUDE_CODE_IS_COWORK=1`, this is a Cowork session. Resolve the memory path within the user's mounted folder (see Cowork Folder Resolution below).
3. **Default (Claude Code):** Use `~/.claude/memory/`.

## Memory Path by Environment

| Environment | Memory Path | Persistence |
|-------------|-------------|-------------|
| Claude Code | `~/.claude/memory/` | Native — survives between sessions |
| Cowork (folder mounted) | `{mounted-folder}/.sidekick-memory/` | Persists via VirtioFS to host machine |
| Cowork (no folder) | `~/.claude/memory/` (ephemeral) | Lost between sessions — warn user |
| Custom (`SIDEKICK_MEMORY_DIR`) | Whatever the user set | User-managed |

## Cowork Folder Resolution

In Cowork, the user's selected folder is mounted into the VM via VirtioFS at a session-scoped path under `/sessions/<session-name>/mnt/<folder-name>/`. The folder name varies based on what the user selected (e.g., `Downloads`, `my-project`).

**To find the mounted folder in a skill (Claude interpreting instructions):**

1. Check if the current working directory is under a mounted user folder (it usually is if the user selected a folder).
2. Look for writable directories under the session's `/mnt/` path that are not system directories (`outputs`, `uploads`, `.claude`, `.local-plugins`, `.skills`).
3. If no mounted folder is found, use `request_cowork_directory` (if available) to prompt the user to select one.
4. If `request_cowork_directory` is unavailable or the user declines, fall back to `~/.claude/memory/` and warn about ephemeral mode.

**To find the mounted folder in a bash hook:**

Hooks cannot reliably detect the mounted folder name since it varies per session. In bash hooks, rely on `SIDEKICK_MEMORY_DIR` being set. If it is not set and `CLAUDE_CODE_IS_COWORK=1`, the hook should output a message telling the user to run `/sidekick:orient` or `/sidekick:setup` to configure the memory path.

The orient or setup skill can then set `SIDEKICK_MEMORY_DIR` via `CLAUDE_ENV_FILE` to persist it for the rest of the session.

## Setting SIDEKICK_MEMORY_DIR via CLAUDE_ENV_FILE

In Cowork, once the memory path is resolved by a skill, persist it for the session:

```bash
echo "SIDEKICK_MEMORY_DIR={resolved-path}" >> "$CLAUDE_ENV_FILE"
```

This makes the path available to subsequent hook invocations within the same session.

## Skills That Need Detection

Only entry-point skills need full detection logic:
- **setup** — runs once, creates directory structure
- **orient** — runs every session start

All other skills (remember, recall, reflect, status, sync) inherit the resolved path from orient's session context or fall back to `SIDEKICK_MEMORY_DIR` / `~/.claude/memory/`.
