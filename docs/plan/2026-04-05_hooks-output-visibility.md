# Plan: Hooks の実行結果を可視化する

Claude Code の PostToolUse hooks（shfmt, goimports, markdown-format, prettier）が成功・失敗したとき、ユーザーに結果が伝わらない。各 hook に統一的なログ出力を追加し、実行結果を一目で判断できるようにする。

## Background

- 現在 4 つの hook が `PostToolUse`（Write/Edit/MultiEdit）で実行される
- hook が成功してもサイレント、失敗しても何が起きたか分かりにくい
- Claude Code の hook 仕様:
  - `stdout` → AI へのコンテキストとして渡される
  - `stderr` → ユーザーのターミナルに表示される
  - exit code 0 = 成功、非 0 = ツール使用をブロック
- したがって **stderr にログを出す** のが、ユーザーへのフィードバックとして最も直接的

## Current structure

- `ai-agents/settings/claude/hooks/shfmt.sh` — `.sh` を shfmt で整形
- `ai-agents/settings/claude/hooks/goimports.sh` — `.go` を goimports で整形
- `ai-agents/settings/claude/hooks/markdown-format.sh` — `.md` を markdownlint-cli2 + prettier で整形
- `ai-agents/settings/claude/hooks/prettier.sh` — `.html/.css/.js/.ts/.json/.yaml/.yml` を prettier で整形
- 全 hook 共通: stdin から JSON を読み、`tool_input.file_path` を抽出 → 拡張子で早期 exit → フォーマッタ実行

## Design policy

- **stderr にログを出す**: ユーザーのターミナルに直接表示される
- **統一フォーマット**: `[hook名] status: ファイルパス` の形式で揃える
- **exit code を正しく伝搬する**: フォーマッタの終了コードをそのまま返す
- **最小限の変更**: 既存ロジックは変えず、ログ出力とエラーハンドリングだけ追加
- **スキップ時もログ**: 対象外ファイルのスキップは出力しない（ノイズになるため）
- **後から切り替え可能**: 環境変数 `HOOK_LOG_LEVEL` で出力レベルを制御。デフォルトは `error`（失敗時のみ）、`all` に設定すると成功時もログ出力。stderr 出力があると Claude Code が hook error 扱いするため、成功時はサイレントをデフォルトとした

## Implementation steps

1. 各 hook にフォーマッタ実行後の exit code キャプチャを追加
2. 成功時: `[hook名] ok: <file_path>` を stderr に出力
3. 失敗時: `[hook名] fail: <file_path>` を stderr に出力し、フォーマッタの stderr もそのまま流す
4. `markdown-format.sh` は 2 ステップ（markdownlint-cli2 → prettier）あるので、各ステップの結果を個別にログ出力

## File changes

| File                                                 | Change                                                            |
| ---------------------------------------------------- | ----------------------------------------------------------------- |
| `ai-agents/settings/claude/hooks/shfmt.sh`           | shfmt 実行後に exit code をキャプチャし、結果を stderr に出力     |
| `ai-agents/settings/claude/hooks/goimports.sh`       | goimports 実行後に exit code をキャプチャし、結果を stderr に出力 |
| `ai-agents/settings/claude/hooks/markdown-format.sh` | markdownlint-cli2, prettier 各ステップの結果を stderr に出力      |
| `ai-agents/settings/claude/hooks/prettier.sh`        | prettier 実行後に exit code をキャプチャし、結果を stderr に出力  |

## Risks and mitigations

| Risk                                                           | Mitigation                                                                                                                    |
| -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| stderr 出力がターミナルをノイジーにする                        | スキップ時は出力しない。成功時は 1 行のみ                                                                                     |
| markdownlint-cli2 の exit code が非 0 でも修正済みの場合がある | `--fix` モードでは修正後に exit 0 になるはずだが、修正不能なルール違反は非 0 で返る。その場合はエラーメッセージをそのまま表示 |

## Validation

- [ ] `.sh` ファイルを Edit して shfmt hook のログが stderr に出ることを確認
- [ ] `.go` ファイルを Edit して goimports hook のログが stderr に出ることを確認
- [ ] `.md` ファイルを Edit して markdown-format hook のログが stderr に出ることを確認
- [ ] `.json` ファイルを Edit して prettier hook のログが stderr に出ることを確認
- [ ] 存在しないファイルパスを渡して失敗ログが出ることを確認
- [ ] shellcheck で各 hook にエラーがないことを確認

## Open questions

- ~~成功時のログも不要と感じる場合は、失敗時のみ出力に切り替えるか？~~ → 解決済み。stderr 出力があると Claude Code が `PostToolUse hook error` 扱いするため、デフォルトは `error`（失敗時のみ）に変更。`HOOK_LOG_LEVEL=all` で成功時も出力可能
