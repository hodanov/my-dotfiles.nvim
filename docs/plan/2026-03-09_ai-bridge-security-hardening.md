# Plan: ai-bridge セキュリティハードニング

ai-bridge-daemon および関連ファイルに対するセキュリティレビュー指摘（Critical 2件、Warning 4件）を修正する。パストラバーサル、TOCTOU、入力検証不足、パーミッション未設定、クォーティング不備、信頼境界の文書化が対象。

## Background

- ai-bridge は Neovim からプロンプトを JSON ファイル経由で AI CLI（claude 等）に橋渡しする仕組み
- daemon がファイル監視 → JSON パース → 一時スクリプト生成 → ランチャー経由で実行、という流れ
- セキュリティレビューで 6 件の指摘を受けた（Critical 2、Warning 4）

## Current structure

- `scripts/ai-bridge-daemon.sh` — ファイル監視と一時スクリプト生成
- `scripts/launchers/tmux.sh` — tmux ランチャー
- `scripts/launchers/wezterm.sh` — wezterm ランチャー
- `nvim/config/lua/ai_bridge.lua` — Neovim 側の request.json 書き出し
- `environment/docker/docker-compose.yml` — Docker ボリュームマウント定義

## Design policy

- 入力検証はホワイトリスト方式を優先し、可能な限り入力段階でブロックする
- 既存の動作を壊さない最小限の変更に留める
- dev 用途のリスクは文書化で対応し、過剰な防御は避ける

## Implementation steps

1. **[Critical] LAUNCHER 名のホワイトリスト検証** (`ai-bridge-daemon.sh:19-20`): `LAUNCHER` 変数を `^[a-z][a-z0-9_-]*$` で検証し、パストラバーサルを防止する
2. **[Critical] TOCTOU 解消** (`ai-bridge-daemon.sh:47-53`): `chmod +x` を書き込み完了後に移動し、空ファイルが実行可能な状態で露出する競合ウィンドウを除去する
3. **[Warning] cwd のディレクトリ存在チェック** (`ai-bridge-daemon.sh:41`): JSON 由来の `cwd` が実在ディレクトリか `-d` で検証し、不正値をスキップする
4. **[Warning] tmux.sh のクォーティング修正** (`launchers/tmux.sh:10`): シングルクォート前提のスクリプトパス展開を `printf %q` に変更し、特殊文字を安全にエスケープする
5. **[Warning] request.json のパーミッション設定** (`ai_bridge.lua:59`): `vim.uv.fs_chmod` で書き込み後に `600` を設定し、プロンプト内の機密情報を保護する
6. **[Warning] Docker マウントのリスク文書化** (`docker-compose.yml:23`): コンテナ侵害時の escape vector について SECURITY NOTE コメントを追記する

## File changes

| File                                       | Change                                                                        |
| ------------------------------------------ | ----------------------------------------------------------------------------- |
| `scripts/ai-bridge-daemon.sh:19-20`        | LAUNCHER 名を `^[a-z][a-z0-9_-]*$` で検証するガードを追加                     |
| `scripts/ai-bridge-daemon.sh:47-48`        | `chmod +x` を書き込み後（L53 相当）に移動                                     |
| `scripts/ai-bridge-daemon.sh:41`           | `cwd` の `-d` チェックと不正時の `continue` を追加                            |
| `scripts/launchers/tmux.sh:10`             | `'$script'` を `$(printf '%q' "$script")` に変更                              |
| `nvim/config/lua/ai_bridge.lua:61`         | `f:close()` の後に `vim.uv.fs_chmod(request_file, tonumber("600", 8))` を追加 |
| `environment/docker/docker-compose.yml:23` | `~/.ai-bridge` マウントに SECURITY NOTE コメントを追加                        |

## Risks and mitigations

| Risk                                            | Mitigation                                                                        |
| ----------------------------------------------- | --------------------------------------------------------------------------------- |
| LAUNCHER の正規表現が厳しすぎて既存の名前を弾く | `[a-z][a-z0-9_-]*` はハイフン・アンダースコアを許可しており、一般的な命名には十分 |
| `cwd` チェックでシンボリックリンク先を弾く      | `-d` はシンボリックリンクも解決するため問題なし                                   |
| `vim.uv.fs_chmod` が古い Neovim で未対応        | Neovim 0.10+ で利用可能。それ以前は `vim.loop.fs_chmod` にフォールバック可能      |
| Docker コメント追加は実質的な防御にならない     | dev 用途のため文書化で十分。プロダクション利用は想定外                            |

## Validation

- [ ] `AI_BRIDGE_LAUNCHER=../../../etc/evil` でデーモン起動時にエラー終了することを確認
- [ ] `AI_BRIDGE_LAUNCHER=wezterm` で正常起動することを確認
- [ ] 一時スクリプトが書き込み完了後にのみ実行権限を持つことを確認（`ls -l` で中間状態を観察）
- [ ] 存在しない `cwd` を含む request.json を投入し、WARNING ログが出て処理がスキップされることを確認
- [ ] tmux ランチャーでスペースを含むスクリプトパスが正しく処理されることを確認
- [ ] request.json 書き出し後のパーミッションが `600` であることを確認（`stat` で検証）
- [ ] Docker Compose ファイルにセキュリティコメントが含まれることを目視確認

## Open questions

- `AI_BRIDGE_CLI` の値も同様にホワイトリスト検証すべきか（現状は未検証だが、ユーザーが自由に設定する想定）
- daemon 側で request.json のオーナーチェック（`stat` で uid 検証）を追加すべきか（Docker 経路の追加防御）
