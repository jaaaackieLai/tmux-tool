# tmux-tool

> 一個快速、鍵盤導向、可選 AI 摘要的 tmux 工作階段管理工具。

`tmux-session` 讓你在多個 tmux session 之間切換與管理時，不再丟失上下文。
工具以純 Bash 實作，啟動輕快；即使不開啟 AI 功能，也能完整使用。

[English README](../../README.md)

## 為什麼用 tmux-session

- 專注不分心：所有 session 一頁總覽，並即時預覽輸出。
- 操作更快：`attach`、`rename`、`kill`、`new` 全部在同一個 TUI 完成。
- 上下文更清楚：可選 AI 一行摘要，快速看懂每個 session 正在做什麼。
- 輕量零負擔：必需依賴只有 `tmux`，AI 相關只需額外 `curl` + `jq`。

## 介面預覽

### 清單視圖（List View）

```text
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

### 詳細視圖（Detail View）

```text
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

## 主要功能

- 雙層 TUI：清單視圖 + 詳細視圖。
- 即時預覽目前選取 session 的終端輸出。
- 每個 session 的 AI 一行摘要。
- 重新命名時可用 AI 建議名稱。
- AI 任務在背景執行，不阻塞互動介面。
- 內建自我更新：`tmux-session --update`。

## 快速開始

### 1) 安裝

從本地 clone 安裝：

```bash
git clone <repo-url> && cd tmux-tool
./install.sh
```

從 GitHub 直接安裝：

```bash
curl -fsSL https://jaaaackielai.github.io/tmux-tool/install.sh | bash
```

自訂安裝路徑（預設 `~/.local`）：

```bash
INSTALL_PREFIX=/usr/local ./install.sh
```

程式安裝到 `${INSTALL_PREFIX}/share/tmux-session/`，並在 `${INSTALL_PREFIX}/bin/tmux-session` 建立 symlink。

### 2) 驗證

```bash
hash -r
command -v tmux-session
tmux-session -h
```

### 3) 啟動

```bash
tmux-session
```

## 相依套件

| 套件 | 必要 | 用途 | macOS | Debian/Ubuntu |
|---|---|---|---|---|
| `tmux` | 是 | Session 管理 | `brew install tmux` | `sudo apt install tmux` |
| `curl` | 否 | 呼叫 AI API | 內建 | `sudo apt install curl` |
| `jq` | 否 | 解析 AI 回應 JSON | `brew install jq` | `sudo apt install jq` |

## 快捷鍵

### 清單視圖（List View）

| 按鍵 | 動作 |
|---|---|
| `Up/Down` | 移動選取 |
| `Enter` | 進入詳細視圖 |
| `n` | 建立新 session |
| `f` | 重新整理清單 + AI 摘要 |
| `q` | 離開 |

### 詳細視圖（Detail View）

| 按鍵 | 動作 |
|---|---|
| `Up/Down` | 移動選單 |
| `Enter` | 執行選取動作 |
| `a` | Attach session |
| `r` | 重新命名（含 AI 建議） |
| `k` | 結束 session |
| `ESC` / `q` | 回到清單 |

## 設定

預設設定檔路徑：

```bash
~/.config/tmux-session/config.sh
```

範例：

```bash
TMUX_SESSION_NEW_DEFAULT_DIR="$HOME/work/my-project"
TMUX_SESSION_NEW_DEFAULT_CMD="source .venv/bin/activate"
TMUX_SESSION_NEW_ASK_DIR=1
TMUX_SESSION_NEW_ASK_CMD=1
```

覆寫設定檔路徑：

```bash
TMUX_SESSION_CONFIG_FILE=/path/to/config.sh tmux-session
```

## AI 功能

先設定 API Key：

```bash
export ANTHROPIC_API_KEY='sk-ant-...'
```

啟用後，`tmux-session` 會：

- 擷取近期 pane 輸出，
- 產生每個 session 的繁中一行摘要，
- 提供可直接採用的短名稱建議。

若未設定 API Key，非 AI 功能仍可完整運作。

## Shell 啟動時自動開啟

加到 `~/.bashrc` 或 `~/.zshrc`：

```bash
if [[ -z "${TMUX:-}" ]] && command -v tmux-session >/dev/null 2>&1; then
    tmux-session
fi
```

## CLI 指令

```text
tmux-session --help
tmux-session --version
tmux-session --update
tmux-session --uninstall
```

## 授權

MIT
