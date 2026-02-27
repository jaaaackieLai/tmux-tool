# tmux-session: Interactive tmux session manager

PTT 風格的 tmux session 管理工具，專為同時跑多個 Claude Code session 設計。

## 專案結構

```
tmux-tool/
  tmux-session       # 主程式 (bash script, ~350 行)
  install.sh         # 安裝腳本
  CLAUDE.md          # 本檔案
```

## 技術架構

- **語言**: 純 bash，零外部依賴（tmux 必要，curl/jq 為 AI 功能選用）
- **TUI**: ANSI escape codes 手刻互動選單，raw terminal mode (stty)
- **AI 摘要**: Anthropic API (Haiku)，背景 subshell 非同步執行，結果寫到 `/tmp/tmux-session-ai-*`
- **API**: 需要 `ANTHROPIC_API_KEY` 環境變數（沒設就跳過 AI 功能）

## 功能

| 按鍵 | 功能 |
|------|------|
| Up/Down | 上下選擇 session |
| Enter | attach 進入 session |
| r | rename（預填 AI 建議名稱） |
| k | kill（需確認） |
| n | 建立新 session |
| f | 重新整理 + 重跑 AI 摘要 |
| q | 離開 |

## TUI 佈局

```
 tmux-session manager  v1.0.0
 ─────────────────────────────
 > session-0  [AI: 正在開發登入功能...]
   session-1  [AI: ...]
   session-2  [AI: 跑測試中]
 ─────────────────────────────
 Preview (session-0):
   最後 N 行終端輸出...
 ─────────────────────────────
 [Enter] attach  [r] rename  [k] kill  [n] new  [f] refresh  [q] quit
```

## 安裝

```bash
./install.sh              # 安裝到 /usr/local/bin
INSTALL_DIR=~/.local/bin ./install.sh  # 自訂安裝路徑
```

## 自動啟動（加到 .bashrc / .zshrc）

```bash
if [[ -z "${TMUX:-}" ]] && command -v tmux-session >/dev/null 2>&1; then
    tmux-session
fi
```

## 開發備註

- AI model: `claude-haiku-4-5-20251001`
- Preview 抓最後 15 行顯示，AI 摘要抓最後 150 行（取 tail 80 行送 API）
- Temp files 用 PID 隔離: `/tmp/tmux-session-ai-$$`
- attach 前會還原 terminal state，detach 後重新設定 raw mode