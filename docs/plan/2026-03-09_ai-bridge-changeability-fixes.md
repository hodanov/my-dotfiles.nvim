# Plan: ai-bridge 変更容易性の改善

セキュリティ・パフォーマンスレビュー修正に続き、変更容易性のレビュー指摘 4 件を修正する。
DRY 違反の解消、セットアップ自動化、リソースリーク防止、ランチャー契約の明文化を行う。

## Background

- ai-bridge はシェルスクリプト（daemon）、Lua（Neovim プラグイン）、Docker Compose の 3 コンポーネントで構成される
- コードレビューで変更容易性に関する指摘が 4 件あがった（Critical 1、Warning 3）
- セキュリティ・パフォーマンスの修正は別ブランチで完了済み

## Current structure

- `scripts/ai-bridge-daemon.sh` — デーモン本体。`~/.ai-bridge` をデフォルトディレクトリとしてハードコード
- `nvim/config/lua/ai_bridge.lua` — Neovim プラグイン。同じデフォルトパスを独立して定義（HOME 欠落バグあり）
- `environment/docker/docker-compose.yml` — Docker ボリュームマウントで同じパスを指定
- `scripts/com.ai-bridge.daemon.plist` — launchd 用テンプレート。`%%REPO_DIR%%` の手動置換が必要
- `scripts/launchers/wezterm.sh` / `tmux.sh` — ランチャー実装。エスケープ方針がコメント未記載

## Design policy

- デフォルト値の正規定義は 1 ファイル（`scripts/ai-bridge-defaults.sh`）に集約する
- 言語境界を越える場合（Lua、YAML）は source できないため、正規定義場所をコメントで参照する
- セットアップの暗黙的な手順はスクリプトで自動化し、手動 sed を不要にする
- ランチャーの実装契約をヘッダコメントで統一し、新規追加時の判断コストを下げる

## Implementation steps

1. `scripts/ai-bridge-defaults.sh` を新設し、`AI_BRIDGE_DIR` のデフォルト値を一元定義する
2. `scripts/ai-bridge-daemon.sh` で `ai-bridge-defaults.sh` を source し、ハードコードされたデフォルトを削除する
3. `nvim/config/lua/ai_bridge.lua` の `bridge_dir` 定義を修正する（HOME 欠落バグ修正 + 正規定義への参照コメント追加）
4. `environment/docker/docker-compose.yml` に正規定義への参照コメントを追加する
5. `scripts/install-launchd.sh` を新設し、`%%REPO_DIR%%` 置換と `launchctl load` を自動化する
6. `scripts/com.ai-bridge.daemon.plist` の Setup コメントを更新し、install スクリプトを案内する
7. `nvim/config/lua/ai_bridge.lua` の `io.open` 周りを修正し、`f:close()` を例外時にも保証する
8. `scripts/launchers/wezterm.sh` と `tmux.sh` にランチャー契約コメントを追加する

## File changes

| File                                    | Change                                                            |
| --------------------------------------- | ----------------------------------------------------------------- |
| `scripts/ai-bridge-defaults.sh`         | 新設。`AI_BRIDGE_DIR` デフォルト値の正規定義                      |
| `scripts/ai-bridge-daemon.sh`           | `ai-bridge-defaults.sh` を source、ハードコード削除               |
| `nvim/config/lua/ai_bridge.lua`         | HOME 欠落バグ修正、参照コメント追加、`io.open` リソースリーク修正 |
| `environment/docker/docker-compose.yml` | 正規定義への参照コメント追加                                      |
| `scripts/install-launchd.sh`            | 新設。plist の置換・インストール自動化                            |
| `scripts/com.ai-bridge.daemon.plist`    | Setup コメントを install スクリプトへ誘導に更新                   |
| `scripts/launchers/wezterm.sh`          | ランチャー契約コメント追加                                        |
| `scripts/launchers/tmux.sh`             | ランチャー契約コメント追加                                        |

## Risks and mitigations

| Risk                                                        | Mitigation                                                                             |
| ----------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `source ai-bridge-defaults.sh` のパス解決失敗               | `SCRIPT_DIR` 基準の相対パスを使い、`shellcheck source=` ディレクティブで静的解析も通す |
| `install-launchd.sh` が既存 plist を上書き                  | 既存ファイルがある場合に警告を出すか、差分確認を挟む余地を残す                         |
| Lua 側は `source` できないため defaults.sh と乖離する可能性 | コメントで正規定義場所を明示し、CI やレビューで検知する運用とする                      |
| `f:close()` 修正で pcall のネストが深くなり可読性低下       | 内側の pcall は `f.write` 1 行だけなので複雑さは限定的                                 |

## Validation

- [ ] `ai-bridge-daemon.sh` を `AI_BRIDGE_DIR` 未設定で起動し、デフォルトが `~/.ai-bridge` になることを確認
- [ ] `ai-bridge-daemon.sh` を `AI_BRIDGE_DIR=/tmp/test-bridge` で起動し、環境変数が優先されることを確認
- [ ] `ai_bridge.lua` で `bridge_dir` が `$HOME/.ai-bridge` に解決されることを確認
- [ ] `install-launchd.sh` を実行し、`~/Library/LaunchAgents/com.ai-bridge.daemon.plist` に正しいパスが入ることを確認
- [ ] Neovim から `M.send_prompt()` を呼び、書き込みエラー時にファイルハンドルがリークしないことを確認
- [ ] `shellcheck scripts/ai-bridge-daemon.sh` がパスすることを確認
- [ ] `shellcheck scripts/install-launchd.sh` がパスすることを確認

## Open questions

- `install-launchd.sh` で既存 plist がある場合、上書きするかバックアップを取るか（一旦は上書きで進める想定）
- Docker Compose 側の `/.ai-bridge` マウント先パスは正規定義から自動生成すべきか（現状は YAML 直書きのまま、コメント参照で対応）
