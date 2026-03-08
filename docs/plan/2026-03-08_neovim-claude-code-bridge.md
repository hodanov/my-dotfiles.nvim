# Plan: Neovim (Docker) ↔ Claude Code (Host) ブリッジ

Dockerコンテナ内のNeovimで選択したコードを、ホスト側のClaude Code CLIにコンテキスト付きで渡す連携機構を実装する。
共有ボリューム上のJSONファイルとホスト側ファイル監視デーモンを組み合わせ、ターミナルの新規タブでClaude Codeを起動する。
ターミナルランチャーはプラガブル設計とし、WezTerm / tmux / その他への切り替えを容易にする。

## Background

- Neovimはdocker-composeで管理されたコンテナ内で動作し、Claude Codeはホスト側(macOS)で動作する
- コード選択 → AI問い合わせのフローをキーマップ一発で完結させたい
- `${HOME}/workspace:/${HOME}/workspace` のボリュームマウントにより、ファイルパスがコンテナ・ホスト間で一致する
- メインのターミナルエミュレータはWezTerm（`wezterm cli` によるタブ制御が可能）だが、tmux等への切り替えも想定する

## Current structure

- `environment/docker/docker-compose.yml`: コンテナ定義、ボリュームマウント
- `nvim/config/init.lua`: Neovimメイン設定（キーマップ、プラグイン読み込み）
- `nvim/config/lua/plugins.lua`: lazy.nvimプラグインスペック
- 既存ターミナル連携: `<Leader>-`(水平分割) / `<Leader>l`(垂直分割) で `term://bash` を起動

## Design policy

- **通信方式はファイルベース**: named pipeやUnixソケットに比べシンプルでデバッグしやすい。Dockerボリュームマウントとの相性も良い
- **ホスト側デーモンで監視**: `fswatch` でブリッジディレクトリを監視し、リクエスト検出時にターミナルタブを起動
- **パスの一致を活用**: 既存の `${HOME}/workspace` マウントによりコンテナ内パス = ホスト側パス。Claude Codeがそのままファイルを参照可能
- **ターミナルランチャーはプラガブル**: デーモン本体とターミナル起動ロジックを分離し、ランチャースクリプトの差し替えだけでWezTerm / tmux / iTerm2等を切り替え可能にする
- **ワーキングディレクトリはプロジェクトルート**: Claude Codeの起動時cwdはリクエストに含まれるcwd（プロジェクトルート）を使用
- **デーモンのライフサイクル**: デフォルトはlaunchdによる自動起動。手動起動への切り替えも可能

## Architecture

```text
┌─────────────────────────────┐     ┌──────────────────────────────┐
│  Docker Container           │     │  macOS Host                  │
│                             │     │                              │
│  Neovim                     │     │  ai-bridge-daemon            │
│   ├─ Visual select code     │     │   ├─ fswatch で監視          │
│   ├─ <leader>cc 押下        │     │   ├─ request.json を読む     │
│   └─ request.json 書出し ───┼──→──┼─→ └─ launcher で新規タブ起動  │
│                             │     │       └─ claude "context..." │
│  /.ai-bridge/               │ vol │  ~/.ai-bridge/               │
│    └─ request.json          │ ════│    └─ request.json           │
└─────────────────────────────┘     └──────────────────────────────┘
```

## Implementation steps

1. **ブリッジ用共有ボリュームの追加**: `docker-compose.yml` に `${HOME}/.ai-bridge:/.ai-bridge` マウントを追加
2. **Neovim Luaプラグイン作成**: `nvim/config/lua/ai_bridge.lua` を新規作成。ビジュアル選択範囲・ファイルパス・行番号・filetype をJSON化してブリッジディレクトリに書き出す
3. **init.luaへの組み込み**: `require("ai_bridge")` を追加
4. **ターミナルランチャースクリプト作成**: `scripts/launchers/` ディレクトリにランチャーを配置。共通インターフェース (`launch.sh <cwd> <prompt>`) で統一し、WezTerm用 (`wezterm.sh`) をデフォルトとする。tmux用 (`tmux.sh`) も同時に用意する
5. **ホスト側デーモンスクリプト作成**: `scripts/ai-bridge-daemon.sh` を新規作成。`fswatch` でブリッジディレクトリを監視し、リクエスト検出時に設定されたランチャーを呼び出す
6. **launchd plist作成**: `scripts/com.ai-bridge.daemon.plist` を作成。`launchctl load` で自動起動を有効化。手動運用の場合は `launchctl unload` で無効化
7. **E2Eテスト**: Neovimでコード選択 → `<leader>cc` → 新規ターミナルタブでClaude Codeが起動することを確認

## File changes

| File | Change |
| --- | --- |
| `environment/docker/docker-compose.yml` | `volumes` に `${HOME}/.ai-bridge:/.ai-bridge` を追加 |
| `nvim/config/lua/ai_bridge.lua` | 新規作成。ビジュアル選択のコンテキストをJSONに書き出すLuaモジュール |
| `nvim/config/init.lua` | `require("ai_bridge")` を追加 |
| `scripts/ai-bridge-daemon.sh` | 新規作成。ホスト側ファイル監視デーモン。ランチャーを呼び出す |
| `scripts/launchers/wezterm.sh` | 新規作成。WezTerm用ターミナルランチャー |
| `scripts/launchers/tmux.sh` | 新規作成。tmux用ターミナルランチャー |
| `scripts/com.ai-bridge.daemon.plist` | 新規作成。launchd用plist（自動起動設定） |

## Component details

### Neovim Luaプラグイン (`ai_bridge.lua`)

- `<leader>cc` (ビジュアルモード) で発火
- `vim.fn.line("'<")` / `vim.fn.line("'>")` で選択範囲を取得
- `vim.fn.expand("%:p")` でファイルパス、`vim.bo.filetype` でファイルタイプを取得
- JSON構造: `{ file_path, start_line, end_line, filetype, selected_text, cwd, timestamp }`
- 書き出し先: `/.ai-bridge/request.json`

### ホスト側デーモン (`ai-bridge-daemon.sh`)

- `fswatch -o ~/.ai-bridge/request.json` でファイル変更を監視
- `jq` でJSONパース
- リクエスト消費後にリネーム (`request.json` → `request.json.consumed`) で重複防止
- 環境変数 `AI_BRIDGE_LAUNCHER` で使用するランチャーを指定（デフォルト: `wezterm`）
- ランチャースクリプトを `$launcher <cwd> <prompt>` の形式で呼び出す
- プロンプトにはファイルパス・行番号・コードブロックを含める

### ターミナルランチャー (`scripts/launchers/`)

共通インターフェース: `<launcher>.sh <cwd> <prompt>`

| Launcher | Command | 備考 |
| --- | --- | --- |
| `wezterm.sh` | `wezterm cli spawn --cwd "$1" -- claude "$2"` | デフォルト |
| `tmux.sh` | `tmux new-window -c "$1" "claude '$2'"` | tmuxセッション内で実行 |

新しいランチャーを追加する場合は同じインターフェースのシェルスクリプトを `scripts/launchers/` に置くだけで対応可能。

### デーモンのライフサイクル管理

| 方式 | コマンド |
| --- | --- |
| 自動起動を有効化（デフォルト） | `launchctl load ~/Library/LaunchAgents/com.ai-bridge.daemon.plist` |
| 自動起動を無効化 | `launchctl unload ~/Library/LaunchAgents/com.ai-bridge.daemon.plist` |
| 手動起動 | `./scripts/ai-bridge-daemon.sh` |
| 手動停止 | `Ctrl+C` またはデーモンのPIDをkill |

launchd plistは `scripts/com.ai-bridge.daemon.plist` に配置し、セットアップ時に `~/Library/LaunchAgents/` へシンボリックリンクを張る。

### ホスト側の依存ツール

| Tool | Purpose | Install |
| --- | --- | --- |
| `fswatch` | ファイル変更監視 | `brew install fswatch` |
| `jq` | JSONパース | `brew install jq` |
| `claude` | Claude Code CLI | インストール済み |
| `wezterm` CLI | ターミナルタブ制御（WezTerm使用時） | WezTermに同梱 |
| `tmux` | ターミナルタブ制御（tmux使用時） | `brew install tmux` |

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| `fswatch` のイベント重複でClaude Codeが複数起動する | リクエストファイルを消費後にリネームし、存在チェックで重複防止 |
| ブリッジディレクトリが存在しない場合の起動失敗 | Lua側・デーモン側の両方で `mkdir -p` を実行 |
| 大量のコード選択時にCLI引数の長さ上限に抵触 | 一定サイズ以上の場合はファイル参照に切り替える（v2で対応） |
| デーモンが起動していない状態での `<leader>cc` | Neovim側で `notify` を出すのみ。デーモン未起動の検知は v2 で対応 |

## Validation

- [ ] コンテナ内で `/.ai-bridge/request.json` が正しいJSON形式で書き出される
- [ ] ホスト側 `~/.ai-bridge/request.json` に同一内容が反映される
- [ ] デーモンがファイル変更を検知し、ランチャー経由で新規ターミナルタブが開く
- [ ] Claude Codeが選択コード・ファイルパス・行番号を含むプロンプトで起動する
- [ ] リクエスト消費後に重複起動しない
- [ ] 複数回連続で `<leader>cc` を実行しても正常動作する

- [ ] `AI_BRIDGE_LAUNCHER` 環境変数でランチャー切り替えが動作する（wezterm / tmux）
- [ ] launchdによる自動起動・停止が正常に動作する
- [ ] 手動起動モードでも正常に動作する

## Open questions

- ランチャーに渡すプロンプトが長すぎる場合の扱い（CLIの引数長上限）。一時ファイル経由に切り替えるか
