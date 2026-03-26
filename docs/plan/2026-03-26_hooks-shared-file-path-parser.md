# Plan: Cursor hookのファイルパス抽出を共通化する

Cursor hooksの `stdin` から `file_path` を抽出する処理がスクリプトごとに重複していたため、`get_file_path.py` へ共通化する。これにより入力JSONの揺れへの対応を一元化し、今後の修正コストと不整合リスクを下げる。既存の各フックの拡張子判定とフォーマット実行ロジックは維持しつつ、抽出部分だけを置換する。

## Background

- `markdown-format.sh` と `prettier.sh` で、同種のPythonワンライナーによるパース処理が存在していた
- `goimports.sh` と `shfmt.sh` はさらに単純な `tool_input.file_path` 前提で、入力イベント差異に弱い構成だった
- 入力ペイロードの形式差（`tool_input` / `params` / `event`）に対して、抽出仕様を統一する必要があった

## Current structure

- 対象ディレクトリは `ai-agents/settings/cursor/hooks/`
- 各フックが `INPUT=$(cat)` 後に個別の `python3 -c` を持つ構成
- 対象フックは `markdown-format.sh`, `prettier.sh`, `goimports.sh`, `shfmt.sh`

## Design policy

- ファイルパス抽出ロジックは `get_file_path.py` に集約し、フック側は呼び出しだけを担当する
- 抽出候補は既存運用を壊さないよう広めに取り、`tool_input` / `params` / `event` 系の主要パスを順次探索する
- JSONでない入力に対しては、絶対パス文字列のフォールバックのみ許可して安全側に倒す
- 各フックの拡張子ガードと整形コマンド実行順は変更しない

## Implementation steps

1. `ai-agents/settings/cursor/hooks/get_file_path.py` を新規作成し、`stdin` からの抽出関数を実装する
2. 4つのフックで `SCRIPT_DIR` を解決し、`python3 "$SCRIPT_DIR/get_file_path.py"` 呼び出しに置換する
3. 既存のファイル種別判定（`*.md`, `*.go`, `*.sh`, prettier対象拡張子）と実行コマンドを維持する
4. サンプル入力で抽出結果と対象・非対象ファイルへの挙動を確認する

## File changes

| File                                                 | Change                                                                             |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `ai-agents/settings/cursor/hooks/get_file_path.py`   | 新規追加。JSONペイロードと生パス文字列からファイルパスを抽出する共通ロジックを実装 |
| `ai-agents/settings/cursor/hooks/markdown-format.sh` | インラインPythonパーサを削除し、共通スクリプト呼び出しへ置換                       |
| `ai-agents/settings/cursor/hooks/prettier.sh`        | インラインPythonパーサを削除し、共通スクリプト呼び出しへ置換                       |
| `ai-agents/settings/cursor/hooks/goimports.sh`       | 単純な `tool_input.file_path` 抽出を共通スクリプト呼び出しへ置換                   |
| `ai-agents/settings/cursor/hooks/shfmt.sh`           | 単純な `tool_input.file_path` 抽出を共通スクリプト呼び出しへ置換                   |

## Risks and mitigations

| Risk                                             | Mitigation                                                              |
| ------------------------------------------------ | ----------------------------------------------------------------------- |
| 共通スクリプトの不具合で全フックに影響が波及する | 候補キー探索順を明示し、単体入力テストを複数パターンで実施する          |
| 相対パス依存で呼び出しに失敗する                 | 各フックで `SCRIPT_DIR` を `BASH_SOURCE` から解決して絶対パスで実行する |
| 非対象拡張子にも整形が走る                       | 既存の拡張子判定ロジックは変更せず、そのまま維持する                    |
| 環境依存コマンドにより検証が欠ける               | コマンド未導入時は抽出ロジック単体確認を実施し、未検証箇所を記録する    |

## Validation

- [x] `get_file_path.py` に対して `tool_input.file_path`, `params.path`, `event.tool_input.path`, 生の絶対パス文字列の4パターンで抽出確認
- [x] `prettier.sh` で JSON/YAML 対象ファイルが処理されることを確認
- [x] `prettier.sh` で `.txt` 非対象ファイルが無変更であることを mtime で確認
- [x] `shfmt.sh` の共通抽出経由実行を確認
- [ ] `goimports.sh` の実行確認（ローカル環境で `goimports` が見つからず未完）

## Open questions

- `goimports.sh` の最終実行確認をどの環境（ローカル/コンテナ）で行うか
- 将来的に相対パス入力も許可するか（現状は絶対パスのみフォールバック対象）
