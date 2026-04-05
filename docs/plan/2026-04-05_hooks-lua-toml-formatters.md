# Plan: Lua/TOML フォーマッター hooks 追加

AI IDE（Claude Code / Cursor / Copilot）の PostToolUse hooks に `stylua`（Lua）と `tombi`（TOML）のフォーマッターを追加する。既存の shfmt や prettier と同じパターンで、ファイル保存時に自動フォーマットされるようにする。

## Background

- Neovim の conform.nvim では `stylua` による Lua フォーマットが既に設定済み
- しかし AI IDE（Claude Code, Cursor, Copilot）の hooks にはまだ追加されておらず、AI がファイルを編集した際にフォーマットされない
- `.lua` は 20 ファイル（nvim config + wezterm config）、`.toml` は 3 ファイル（gitleaks, pyproject, ruff）存在する
- `stylua` はインストール済み（`/usr/local/bin/stylua`）、`tombi` はインストール済み（`/usr/local/bin/tombi`）

## Current structure

```text
ai-agents/settings/
├── claude/
│   ├── settings.json          # hooks 定義（PostToolUse）
│   └── hooks/
│       ├── goimports.sh
│       ├── markdown-format.sh
│       ├── shfmt.sh
│       └── prettier.sh
├── cursor/
│   ├── hooks.json             # hooks 定義（afterFileEdit）
│   └── hooks/
│       ├── get_file_path.py   # 共通ファイルパス抽出
│       ├── goimports.sh
│       ├── markdown-format.sh
│       ├── shfmt.sh
│       └── prettier.sh
└── copilot/
    └── hooks/
        ├── hooks.json         # hooks 定義（postToolUse）
        ├── get_file_path.py
        ├── goimports.sh
        ├── markdown-format.sh
        ├── shfmt.sh
        └── prettier.sh
```

- Claude 用 hook スクリプトはインライン Python で `tool_input.file_path` を取得
- Cursor / Copilot 用は `get_file_path.py` を使って汎用的にパスを取得
- 各スクリプトは拡張子で早期 exit し、対象ファイルのみフォーマットする

## Design policy

- 既存の hook スクリプト（shfmt.sh）と同じパターンを踏襲する
- 各 IDE ごとにスクリプトを配置し、パス取得方法の差異を吸収する
- `tombi` はインストール済みなのでそのまま使う（`/usr/local/bin/tombi`）
- `stylua` は既にインストール済みなのでそのまま使う
- Claude の `settings.json` の permissions に `Bash(stylua:*)`, `Bash(tombi:*)` を追加する

## Implementation steps

1. Claude 用 `stylua.sh` を `ai-agents/settings/claude/hooks/` に作成
2. Claude 用 `tombi.sh` を `ai-agents/settings/claude/hooks/` に作成
3. Cursor 用 `stylua.sh` を `ai-agents/settings/cursor/hooks/` に作成
4. Cursor 用 `tombi.sh` を `ai-agents/settings/cursor/hooks/` に作成
5. Copilot 用 `stylua.sh` を `ai-agents/settings/copilot/hooks/` に作成
6. Copilot 用 `tombi.sh` を `ai-agents/settings/copilot/hooks/` に作成
7. `ai-agents/settings/claude/settings.json` の hooks に `stylua.sh` と `tombi.sh` を追加
8. `ai-agents/settings/claude/settings.json` の permissions に `Bash(stylua:*)`, `Bash(tombi:*)` を追加
9. `ai-agents/settings/cursor/hooks.json` に `stylua.sh` と `tombi.sh` を追加
10. `ai-agents/settings/copilot/hooks/hooks.json` に `stylua.sh` と `tombi.sh` を追加
11. `make settings-copy` でデプロイし、動作確認

## File changes

| File                                          | Change                                                                              |
| --------------------------------------------- | ----------------------------------------------------------------------------------- |
| `ai-agents/settings/claude/hooks/stylua.sh`   | 新規作成。`*.lua` を `stylua` でフォーマット                                        |
| `ai-agents/settings/claude/hooks/tombi.sh`    | 新規作成。`*.toml` を `tombi format` でフォーマット                                 |
| `ai-agents/settings/cursor/hooks/stylua.sh`   | 新規作成。`get_file_path.py` 版                                                     |
| `ai-agents/settings/cursor/hooks/tombi.sh`    | 新規作成。`get_file_path.py` 版                                                     |
| `ai-agents/settings/copilot/hooks/stylua.sh`  | 新規作成。`get_file_path.py` 版                                                     |
| `ai-agents/settings/copilot/hooks/tombi.sh`   | 新規作成。`get_file_path.py` 版                                                     |
| `ai-agents/settings/claude/settings.json`     | hooks 配列に 2 エントリ追加 + permissions に `Bash(stylua:*)`, `Bash(tombi:*)` 追加 |
| `ai-agents/settings/cursor/hooks.json`        | `afterFileEdit` 配列に 2 エントリ追加                                               |
| `ai-agents/settings/copilot/hooks/hooks.json` | `postToolUse` 配列に 2 エントリ追加                                                 |

## Risks and mitigations

| Risk                                                                  | Mitigation                                                                         |
| --------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `stylua` のデフォルト設定がプロジェクトの既存コードスタイルと合わない | 必要に応じて `.stylua.toml` を追加して調整可能。まずはデフォルトで試す             |
| `tombi format` のデフォルト設定が既存 TOML と合わない                 | 同上。必要に応じて `tombi.toml` で調整                                             |
| hooks 追加により全体の PostToolUse 時間が増加する                     | 各スクリプトは拡張子チェックで即座に exit するため、対象外ファイルへの影響は最小限 |

## Validation

- [x] `stylua` がインストール済みであることを確認（`which stylua`）
- [x] `tombi` がインストール済みであることを確認（`which tombi`）
- [x] 各 hook スクリプトに実行権限が付与されていることを確認
- [x] テスト用 `.lua` ファイルを不整形に編集し、hook でフォーマットされることを確認
- [x] テスト用 `.toml` ファイルを不整形に編集し、hook でフォーマットされることを確認
- [x] 対象外の拡張子（`.go`, `.md` など）で hook が即座に exit 0 することを確認
- [x] `make settings-copy` 後、`~/.claude/hooks/`, `~/.cursor/hooks/`, `~/.copilot/hooks/` に正しくコピーされることを確認

## Open questions

- `stylua` の設定ファイル（`.stylua.toml`）をプロジェクトルートに置くべきか？（現状はデフォルト設定で運用）
- `tombi` の設定ファイル（`tombi.toml`）は必要か？（現状は少数ファイルなのでデフォルトで十分そう）
