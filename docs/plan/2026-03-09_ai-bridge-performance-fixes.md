# Plan: ai-bridge パフォーマンス指摘の修正

コードレビューで指摘された3件のパフォーマンス問題（不要な毎回 `mkdir`、`jq` 二重起動、`tmp_script` リーク）を修正する。

## Background

- ai-bridge のコードレビューで、パフォーマンスに関する Warning レベルの指摘が3件あがった
- いずれも機能的なバグではないが、無駄な I/O・プロセス起動・一時ファイルのリークにつながる
- 対象ファイルは `nvim/config/lua/ai_bridge.lua` と `scripts/ai-bridge-daemon.sh`

## Current structure

- `ai_bridge.lua`: Neovim からプロンプトを `~/.ai-bridge/request.json` に書き出す Lua モジュール
- `ai-bridge-daemon.sh`: `fswatch` で `request.json` を監視し、AI CLI をランチャー経由で起動するデーモン

## Implementation steps

1. **`mkdir` をモジュールロード時に移動** (`ai_bridge.lua`)
   - `send_prompt()` 内の `vim.fn.mkdir(bridge_dir, "p")` をモジュールトップレベルに移す
   - `bridge_dir` はモジュール定数なので、ロード時に1回実行すれば十分

   ```lua
   -- Before (send_prompt 内)
   function M.send_prompt(prompt, cwd)
       vim.fn.mkdir(bridge_dir, "p")
       ...

   -- After (モジュールトップレベル)
   vim.fn.mkdir(bridge_dir, "p")

   function M.send_prompt(prompt, cwd)
       ...
   ```

2. **`jq` 呼び出しを1回に統合** (`ai-bridge-daemon.sh`)
   - `prompt` と `cwd` を別々の `jq` で取得していたのを、`@tsv` で1回にまとめる

   ```bash
   # Before
   prompt=$(jq -r '.prompt' "$consumed")
   cwd=$(jq -r '.cwd' "$consumed")

   # After
   IFS=$'\t' read -r prompt cwd < <(jq -r '[.prompt, .cwd] | @tsv' "$consumed")
   ```

3. **`tmp_script` のリーク防止** (`ai-bridge-daemon.sh`)
   - ランチャー起動失敗時にスクリプト内の `rm -f` に到達しないため `/tmp` にファイルが蓄積する
   - ランチャー呼び出しに `|| rm -f "$tmp_script"` を追加し、失敗時はデーモン側で削除する
   - 正常系ではスクリプト自身の自己削除に任せる（二重削除は `rm -f` なので無害）

   ```bash
   # Before
   "$LAUNCHER_SCRIPT" "$cwd" "$tmp_script"

   # After
   "$LAUNCHER_SCRIPT" "$cwd" "$tmp_script" || rm -f "$tmp_script"
   ```

## File changes

| File | Change |
| --- | --- |
| `nvim/config/lua/ai_bridge.lua` | `vim.fn.mkdir` を `send_prompt` 内からモジュールトップレベルに移動 |
| `scripts/ai-bridge-daemon.sh` | `jq` 2回呼び出しを `@tsv` で1回に統合 |
| `scripts/ai-bridge-daemon.sh` | ランチャー失敗時に `tmp_script` を削除するフォールバックを追加 |

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| `@tsv` でプロンプトにタブ文字が含まれると `cwd` の切り出しが壊れる | `jq` の `@tsv` はタブをエスケープするため問題ない |
| ランチャーが非同期の場合、`\|\| rm -f` が到達する前にスクリプトが読まれている必要がある | 正常系ではスクリプト自身の `rm -f` が実行されるため、`\|\|` はランチャー起動自体の失敗時のみ発動し安全 |
| `mkdir` をロード時に移すと、環境変数の遅延評価ができなくなる | `bridge_dir` はモジュールロード時に既に評価済みなので影響なし |

## Validation

- [ ] Neovim で `ai_bridge` をリロードし、`bridge_dir` が作成されることを確認
- [ ] `send_prompt` を複数回呼び出しても `mkdir` の stat が1回だけであることを確認
- [ ] プロンプトにタブ・改行・特殊文字を含めた場合に正しくパースされることを確認
- [ ] 存在しないランチャーを指定して起動失敗させ、`/tmp/ai-bridge-*.sh` が残らないことを確認
- [ ] 正常系でランチャーが起動し、スクリプトの自己削除が機能することを確認
