# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository

ClaudeMods holds personal modifications of Claude Code's own interface. There is no build system, linter or test suite.

- `statusline/statusline.sh`: bash status line (`[TAG] repo · branch* · Model`). Installed by copying it to `~/.claude/statusline.sh` and registering `statusLine` in `~/.claude/settings.json` (see `statusline/README.md`).

## Status line notes

- Claude Code passes session JSON on stdin (fields used: `workspace.current_dir`, `cwd`, `model.display_name`/`model.id`). All fields may be absent; the script must always exit 0.
- It runs after every assistant message, so keep it fast: pure bash builtins plus a single `git status`. No `jq` (not installed); JSON is parsed with bash regexes.
- On Windows the command runs through Git Bash; JSON paths arrive with escaped backslashes and are normalized to `/`.
- Test by piping mock JSON: `echo '{"cwd":"D:/path"}' | bash statusline/statusline.sh`.
- `.claude-tag` is a personal per-folder file; do not add it to a repo's `.gitignore` without asking.
