# Environment Detection

Sidekick runs in two environments with different persistence models.

## Detection Logic

Check in this order:

1. **Explicit override:** If `SIDEKICK_MEMORY_DIR` is set, use it. No further detection needed.
2. **Config file:** If `.sidekick/config.yml` exists in the current working directory (or a parent), read it and use `memory_path` relative to the `.sidekick/` directory.
3. **Cowork detection:** If `CLAUDE_CODE_IS_COWORK=1`, this is a Cowork session. Find the user's mounted folder and look for `.sidekick/` there. If not found, run setup.
4. **Default (Claude Code):** Check `~/.claude/.sidekick/config.yml`. If not found, fall back to `~/.claude/memory/` for backward compatibility.

## Memory Path by Environment

| Environment | .sidekick/ location | Memory path | Persistence |
|-------------|---------------------|-------------|-------------|
| Claude Code (new) | `~/.claude/.sidekick/` | `~/.claude/.sidekick/memory/` | Native |
| Claude Code (legacy) | n/a | `~/.claude/memory/` | Native (migrated on next setup) |
| Cowork (folder mounted) | `{mounted-folder}/.sidekick/` | `{mounted-folder}/.sidekick/memory/` | VirtioFS |
| Cowork (no folder) | ephemeral | `~/.claude/.sidekick/memory/` | Lost between sessions |
| Custom (`SIDEKICK_MEMORY_DIR`) | n/a | Whatever the user set | User-managed |

## Config File

`.sidekick/config.yml` stores non-secret settings that persist between sessions:

- Git remote URL and sync preferences
- Environment hint (auto-detected or explicit)
- Memory path (relative to `.sidekick/`)

The config file is safe to commit to git. Credentials are stored separately in `.sidekick/credentials` which is gitignored.

## Credential Safety

Multiple layers prevent accidental PAT exposure:

1. **`.sidekick/.gitignore`** — excludes the `credentials` file from git tracking
2. **Setup writes `.gitignore` before `credentials`** — if setup fails between the two, no credentials file exists
3. **Pre-commit hook** — installed at `.sidekick/hooks/pre-commit`, scans staged files for PAT patterns (`ghp_`, `github_pat_`) and blocks the commit
4. **GitHub push protection** — GitHub scans pushes for leaked tokens on public repos

## Cowork Folder Resolution

In Cowork, the user's selected folder is mounted via VirtioFS at `/sessions/<session-name>/mnt/<folder-name>/`. The folder name varies per session.

**To find `.sidekick/` in a skill:**

1. Check the current working directory for `.sidekick/config.yml`.
2. If not found, look for writable directories under the session mount path (excluding system dirs: `outputs`, `uploads`, `.claude`, `.local-plugins`, `.skills`) and check each for `.sidekick/config.yml`.
3. If not found, use `request_cowork_directory` (if available) to prompt folder selection, then run `/sidekick:setup`.
4. If no folder available, warn about ephemeral mode.

**In a bash hook:**

Hooks cannot search for `.sidekick/` dynamically. They check `SIDEKICK_MEMORY_DIR` first, then look for `.sidekick/config.yml` relative to common locations. If neither works, prompt the user to run `/sidekick:orient`.

## Skills That Need Detection

Only entry-point skills need full detection:
- **setup** — creates `.sidekick/` directory structure
- **orient** — reads config, runs auto-pull, loads memory

All other skills inherit the resolved path from orient's session context.
