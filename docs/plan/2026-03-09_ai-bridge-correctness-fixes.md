# Plan: ai-bridge 正確性レビュー指摘の修正

レビューで指摘された正確性の問題（TOCTOU による デーモン停止、macOS 非互換、null 値の未検証、マウントパスの不整合）を修正し、デーモンの堅牢性を向上させる。

## Background

- セキュリティ・パフォーマンス・変更容易性のレビュー修正は適用済み
- 正確性レビューで Critical 2件、Warning 3件の指摘が残っている
- macOS 環境での運用を前提とするため、BSD 互換性は必須
- ai_bridge.lua のデフォルトパス修正（指摘 #4）は既に対応済み

## Current structure

- `scripts/ai-bridge-daemon.sh` — fswatch ベースのデーモン。request.json を検知して AI CLI を起動
- `scripts/ai-bridge-defaults.sh` — 設定のデフォルト値を定義（single source of truth）
- `nvim/config/lua/ai_bridge.lua` — Neovim 側の送信ロジック
- `environment/docker/docker-compose.yml` — 開発用コンテナ定義。ai-bridge ディレクトリをマウント

## Implementation steps

1. `ai-bridge-daemon.sh`: `mv` に `2>/dev/null || continue` を追加し、TOCTOU による デーモン停止を防止
2. `ai-bridge-daemon.sh`: `date +%s%N` を `date +%s` + `$$` + `$RANDOM` に置き換え、macOS 互換にする
3. `ai-bridge-daemon.sh`: jq パース後に cwd/prompt の null・空チェックを追加
4. `docker-compose.yml`: `environment` セクションに `AI_BRIDGE_DIR=/.ai-bridge` を追加し、マウントパスとの対応を明示

## File changes

| File | Change |
| --- | --- |
| `scripts/ai-bridge-daemon.sh` | mv に `\|\| continue` 追加（TOCTOU 対策） |
| `scripts/ai-bridge-daemon.sh` | consumed ファイル名を macOS 互換に変更 |
| `scripts/ai-bridge-daemon.sh` | jq 結果の null/空チェック追加 |
| `environment/docker/docker-compose.yml` | `AI_BRIDGE_DIR` 環境変数を追加、コメント整理 |

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| mv 失敗を continue でスキップするとリクエストが消える | mv 失敗＝別プロセスが先に消費した場合のみ。正常動作 |
| `$RANDOM` の一意性が不十分 | PID + epoch秒 + RANDOM の3要素で実用上衝突しない |
| null チェックで正当なリクエストを誤って弾く | `"null"` リテラルと空文字のみ対象。正常な値は通る |

## Validation

- [ ] macOS で `date +%s` が正常にエポック秒を返すことを確認
- [ ] request.json に cwd/prompt が欠けた JSON を書き込み、WARNING が出てスキップされることを確認
- [ ] fswatch イベント中にファイルが消えた場合、デーモンが停止せず continue することを確認
- [ ] Docker コンテナ内で `echo $AI_BRIDGE_DIR` が `/.ai-bridge` を返すことを確認
- [ ] shellcheck で新規の警告が出ないことを確認
