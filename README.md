# tmux-tool

Interactive tmux session manager with AI-powered summaries. PTT-style TUI built in pure bash.

Designed for developers running multiple Claude Code sessions (or any tmux workflow) who want a quick overview of what's happening in each session.

## Screenshots

### List View

```
 tmux-session manager  v1.0.0
 ───────────────────────────────────────
 > my-project   [AI: 正在重構登入模組...]
   api-server   [AI: 跑測試中，3 個失敗]
   deploy       [AI: SSH 連線到 prod]
 ───────────────────────────────────────
 Preview (my-project):
   $ npm run test
   PASS src/auth.test.ts
   Tests: 12 passed, 12 total
 ───────────────────────────────────────
 [Enter] open  [n] new  [f] refresh  [q] quit
```

### Detail View

```
 my-project                    v1.0.0
 ───────────────────────────────────────
 Info: 2 windows (created Thu Jan 1 00:00:00 2025)
 AI:   正在重構登入模組...
 ───────────────────────────────────────
 > attach
   rename
   kill
   back
 ───────────────────────────────────────
 [Up/Down] select  [Enter] confirm  [a]ttach [r]ename [k]ill  [ESC] back
```

## Features

- Two-tier TUI -- browse sessions in list view, manage them in detail view
- AI summaries -- each session gets a one-line description of what's happening (via Anthropic Haiku)
- AI-suggested rename -- get a meaningful name pre-filled when renaming
- Live preview of the selected session's terminal output
- Zero external dependencies beyond tmux (curl/jq optional for AI)

## Keybindings

### List View

| Key | Action |
|-----|--------|
| Up/Down | Navigate sessions |
| Enter | Open session detail view |
| n | Create new session |
| f | Refresh list and re-run AI summaries |
| q | Quit |

### Detail View

| Key | Action |
|-----|--------|
| Up/Down | Navigate menu (attach/rename/kill/back) |
| Enter | Execute selected action |
| a | Attach to session |
| r | Rename session (with AI suggestion) |
| k | Kill session |
| ESC/q | Back to list view |

## New Session Defaults

You can configure what happens when pressing `n` (new session):

- Default working directory (`tmux new-session -c ...`)
- Default init command (sent to the new pane automatically)
- Whether to prompt for directory/command every time

Config file path (default):

```bash
~/.config/tmux-session/config.sh
```

Example:

```bash
# ~/.config/tmux-session/config.sh
TMUX_SESSION_NEW_DEFAULT_DIR="$HOME/work/my-project"
TMUX_SESSION_NEW_DEFAULT_CMD="source .venv/bin/activate"
TMUX_SESSION_NEW_ASK_DIR=1
TMUX_SESSION_NEW_ASK_CMD=1
```

You can also override the config path:

```bash
TMUX_SESSION_CONFIG_FILE=/path/to/config.sh tmux-session
```

## Install

```bash
git clone <repo-url> && cd tmux-tool
./install.sh
```

This copies `tmux-session` and `lib/` to `/usr/local/bin`. To install elsewhere:

```bash
INSTALL_DIR=~/.local/bin ./install.sh
```

### Dependencies

| Dependency | Required | Purpose |
|------------|----------|---------|
| tmux | Yes | Session management |
| curl | No | AI summary API calls |
| jq | No | JSON parsing for API responses |

## AI Summaries

Set `ANTHROPIC_API_KEY` to enable AI-powered features:

```bash
export ANTHROPIC_API_KEY='sk-ant-...'
```

When enabled, tmux-session captures the last 150 lines from each session's active pane, sends the tail 80 lines to Claude Haiku, and displays:

- A one-line Traditional Chinese summary next to each session name
- A suggested short name available when renaming (`r`)

Summaries run in background subshells and won't block the UI. Temp files are stored in `/tmp/tmux-session-ai-$$` (PID-isolated) and cleaned up on exit.

Without the API key, everything works the same -- just no AI annotations.

## Auto-launch

Add to `~/.bashrc` or `~/.zshrc` to launch automatically on terminal open (skipped if already inside tmux):

```bash
if [[ -z "${TMUX:-}" ]] && command -v tmux-session >/dev/null 2>&1; then
    tmux-session
fi
```

## CLI Options

```
tmux-session --help     Show help
tmux-session --version  Show version
```

## License

MIT
