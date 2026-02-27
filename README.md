# tmux-tool

Interactive tmux session manager with AI-powered summaries. PTT-style TUI built in pure bash.

Designed for developers running multiple Claude Code sessions (or any tmux workflow) who want a quick overview of what's happening in each session.

## Screenshot

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
 [Enter] attach  [r] rename  [k] kill  [n] new  [f] refresh  [q] quit
```

## Features

- Browse and preview all tmux sessions in a single TUI
- AI summaries -- each session gets a one-line description of what's happening (via Anthropic Haiku)
- AI-suggested rename -- press `r` and get a meaningful name pre-filled
- Live preview of the selected session's terminal output
- Zero external dependencies beyond tmux (curl/jq optional for AI)

## Keybindings

| Key | Action |
|-----|--------|
| Up/Down | Navigate sessions |
| Enter | Attach to selected session |
| r | Rename session (AI suggestion pre-filled) |
| k | Kill session (with confirmation) |
| n | Create new session |
| f | Refresh list and re-run AI summaries |
| q | Quit |

## Install

```bash
git clone <repo-url> && cd tmux-tool
./install.sh
```

This copies `tmux-session` to `/usr/local/bin`. To install elsewhere:

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
