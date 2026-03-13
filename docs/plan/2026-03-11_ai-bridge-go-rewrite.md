# Plan: ai-bridge ホストスクリプトの Go 移行

`scripts/ai-bridge/` 配下の host-side shellscript を Go に集約する実装プランを整理する。目的は daemon、launcher、launchd インストール処理を単一の Go 実装に寄せ、利用技術の統一感、保守性、テスト容易性を上げること。Neovim 側の Lua クライアントと `request.json` ベースの bridge プロトコルは維持し、ホスト側の実装だけを Go に置き換える。合わせて unit test を実装し、Go module 単位で 80% 以上の statement coverage を達成する。

## Background

- 現状の `ai-bridge` は、Neovim が共有ディレクトリに `request.json` を書き、ホスト側 daemon がそれを読んで AI CLI を起動する構成になっている
- 送信側の JSON 仕様は `prompt`、`cwd`、`timestamp` で、Neovim 側は [`nvim/config/lua/ai_bridge.lua`](/Users/hodanov/workspace/my_dotfiles_nvim/nvim/config/lua/ai_bridge.lua) が担当している
- ホスト側は [`scripts/ai-bridge/daemon.sh`](/Users/hodanov/workspace/my_dotfiles_nvim/scripts/ai-bridge/daemon.sh)、[`scripts/ai-bridge/install-launchd.sh`](/Users/hodanov/workspace/my_dotfiles_nvim/scripts/ai-bridge/install-launchd.sh)、[`scripts/ai-bridge/launchers/`](/Users/hodanov/workspace/my_dotfiles_nvim/scripts/ai-bridge/launchers) 配下の shellscript に責務が分散している
- 現行の shell 実装は `jq` に依存している。Go に移行すれば `encoding/json` で完結し、ホスト側の `jq` インストールが不要になる
- リポジトリにはすでに Go toolchain と Go 向け開発環境があり、host-side の実装を Go に寄せても技術選定として浮きにくい
- 今回のプランは「bridge プロトコルは維持しつつ、host-side の shellscript 群を Go アプリケーションへ統合する」方針を明文化することが目的

## Current structure

- [`nvim/config/lua/ai_bridge.lua`](/Users/hodanov/workspace/my_dotfiles_nvim/nvim/config/lua/ai_bridge.lua)
  Neovim 側クライアント。`~/.ai-bridge/request.json` にリクエストを書き出す
- [`scripts/ai-bridge/daemon.sh`](/Users/hodanov/workspace/my_dotfiles_nvim/scripts/ai-bridge/daemon.sh)
  ホスト側 daemon。`request.json` を監視し、JSON を読み、作業用スクリプトを作って launcher を呼ぶ
- [`scripts/ai-bridge/install-launchd.sh`](/Users/hodanov/workspace/my_dotfiles_nvim/scripts/ai-bridge/install-launchd.sh)
  launchd plist を配置し、`launchctl load` する
- [`scripts/ai-bridge/launchers/wezterm.sh`](/Users/hodanov/workspace/my_dotfiles_nvim/scripts/ai-bridge/launchers/wezterm.sh)
  WezTerm 用 launcher。`<cwd> <script_file>` を受け取り、新しいタブで `bash -l <script_file>` を実行する
- [`scripts/ai-bridge/launchers/tmux.sh`](/Users/hodanov/workspace/my_dotfiles_nvim/scripts/ai-bridge/launchers/tmux.sh)
  tmux 用 launcher。インターフェースは WezTerm 版と同じ
- [`scripts/ai-bridge/com.ai-bridge.daemon.plist`](/Users/hodanov/workspace/my_dotfiles_nvim/scripts/ai-bridge/com.ai-bridge.daemon.plist)
  shell 版 daemon を launchd から起動するための plist テンプレート
- [`docs/ai-bridge.md`](/Users/hodanov/workspace/my_dotfiles_nvim/docs/ai-bridge.md)
  セットアップ、運用、環境変数、アーキテクチャの説明を持つ

### Proposed structure

現行の shell 実装は全体で約 140 行と小規模なため、Go 側のパッケージ構成もスリムに保つ。実際に肥大化した段階で分割する方針とし、初期は 5 パッケージで構成する。

```text
scripts/ai-bridge/
├── go.mod
├── go.sum
├── cmd/
│   └── ai-bridge/
│       └── main.go
├── internal/
│   ├── daemon/
│   │   ├── daemon.go          # メインループ、設定、リクエスト処理、一時スクリプト生成
│   │   └── daemon_test.go
│   ├── launcher/
│   │   ├── launcher.go        # interface 定義と factory
│   │   ├── tmux.go
│   │   ├── tmux_test.go
│   │   ├── wezterm.go
│   │   └── wezterm_test.go
│   ├── launchd/
│   │   ├── plist.go           # plist 生成とインストール処理
│   │   └── plist_test.go
│   ├── watcher/
│   │   ├── watcher.go         # ポーリング監視、debounce、atomic consume
│   │   └── watcher_test.go
│   └── testutil/
│       └── exec_stub.go       # daemon loop テスト用の exec stub
└── testdata/
    ├── plist/
    │   └── expected.plist
    └── request/
        ├── invalid.json
        └── valid.json
```

## Design policy

- 既存の bridge 契約を維持する
  `AI_BRIDGE_DIR`、`AI_BRIDGE_CLI`、`AI_BRIDGE_LAUNCHER`、`request.json` の JSON 形式は維持する
- host-side の shellscript は段階的に廃止する
  `daemon.sh`、`install-launchd.sh`、`launchers/*.sh` の責務は Go 側へ移し、移行完了後は削除可能な状態にする
- 監視方式はポーリングを primary とする
  現行の `sleep 1` ポーリングと同様に、短い間隔でのポーリングを基本方式とする。Docker ボリュームマウント（VirtioFS / gRPC FUSE）環境では `fsnotify`（inotify / kqueue ベース）のイベントが伝播しないケースがあるため、ポーリングの方が信頼性が高い。将来的に fsnotify を optional enhancement として追加する余地は残すが、初期実装ではポーリングに統一する
- consume は現行と同じく atomic rename を基本にする
  ポーリングで `request.json` の存在を検知した後、一意な `*.consumed` に rename してから parse し、二重起動を防ぐ
- launcher 実装も Go へ寄せる
  WezTerm / tmux の分岐は Go interface で吸収し、shell launcher wrapper は残さない
- login shell 起動互換は維持する
  現行どおり `bash -l` 経由で AI CLI を起動し、ホストのシェル環境依存を壊さない。一時スクリプト生成は維持する。`bash -lc` 方式は長いプロンプトで引数長制限に当たるリスクがあるため採用しない
- launchd セットアップも Go の subcommand に統合する
  plist はテンプレートファイルを `sed` で置換するのではなく、Go 側で完全生成・配置する。現行の plist テンプレートファイルは Go 移行完了後に削除する
- パッケージ構成はスリムに保つ
  現行 shell 実装が約 140 行と小規模なため、初期は `daemon`、`launcher`、`launchd`、`watcher`、`testutil` の 5 パッケージで構成する。環境変数解決、リクエスト parse、一時スクリプト生成、ログ出力は責務の近いパッケージに同居させ、実際に肥大化した段階で分割する
- unit test を成立させるために副作用境界を interface 化する
  外部コマンド実行は薄い interface に閉じ込め、pure logic を単体で検証できる形にする。ただし exec stub は daemon loop のテストに限定し、stub メンテのコストを抑える。launcher のテストは生成されるコマンドライン引数の検証に絞り、watcher のテストは実際に tmp ディレクトリへファイルを書いて consume を確認する integration 寄りのテストを基本とする
- テストは各実装ステップと同時に書く
  実装とテストを同時に進めることで coverage を自然に積み上げる。後追いでまとめてテストを書く方針は取らない
- カバレッジ目標は Go module 全体で 80% 以上に置く
  `go test -coverprofile=coverage.out ./...` を基準にし、主要 package は table-driven test を基本にして coverage を積み上げる
- シグナルハンドリングの方針を明確にする
  launchd は停止時に `SIGTERM` を送るため、`SIGTERM` と `SIGINT` をハンドルする。シグナル受信時は watcher のポーリングループを停止し、処理中のリクエストがあれば完了を待ってから終了する。一時スクリプトの cleanup は launcher 側の自己削除に任せ、daemon 側では consumed ファイルの残留チェックのみ行う
- Go バイナリは repo 内に配置する
  `go build -o scripts/ai-bridge/ai-bridge ./cmd/ai-bridge` で repo 内にバイナリを出力する。plist からの参照が楽で、`go install` のような PATH 依存を避けられる

## Responsibility split

### `cmd/ai-bridge/main.go`

- `daemon` と `install-launchd` の subcommand を束ねる
- 環境変数と引数を読み、設定を組み立てる
- `log/slog` でロガーを初期化する
- 各 use case を `internal/daemon` と `internal/launchd` に委譲する

### `internal/daemon/daemon.go`

- 環境変数（`AI_BRIDGE_DIR`、`AI_BRIDGE_CLI`、`AI_BRIDGE_LAUNCHER`）の解決と入力検証
- `request.json` の構造体定義、JSON decode、`cwd` / `prompt` の妥当性検証
- AI CLI 実行用の一時スクリプト生成と cleanup
- watcher、launcher を組み合わせてメインループを起動する
- `SIGTERM` / `SIGINT` を受けて graceful shutdown する。処理中のリクエストがあれば完了を待ち、watcher を停止してから終了する

### `internal/watcher/watcher.go`

- 監視対象ディレクトリのポーリングループ
- `request.json` の存在チェック
- 短い debounce と重複イベント抑止
- rename による consume 処理

### `internal/launcher/launcher.go`

- launcher interface の定義
- `AI_BRIDGE_LAUNCHER` から実装を選択する factory

### `internal/launcher/wezterm.go`

- `wezterm cli spawn --cwd <cwd> -- bash -l <script>` を Go から実行する
- 引数エスケープとエラー処理を担当する

### `internal/launcher/tmux.go`

- `tmux new-window -c <cwd> "bash -l <script>"` を Go から実行する
- shell command string の組み立てを担当する

### `internal/launchd/plist.go`

- plist の文字列生成（Go 側で完全生成し、テンプレートファイルは使わない）
- launchd 向け `ProgramArguments` と `EnvironmentVariables` の組み立て
- plist を `~/Library/LaunchAgents/` に配置する
- 既存 plist の `launchctl unload` / `load` を行う

### `internal/testutil/exec_stub.go`

- `exec.Command` の代替 stub を提供する
- daemon loop の unit test で外部コマンド呼び出しを検証する
- stub の利用範囲は daemon loop テストに限定する

## Implementation steps

各ステップでは実装と同時にテストを書き、coverage を段階的に積み上げる。

1. `scripts/ai-bridge/` を独立した Go module にし、`cmd/ai-bridge/main.go` と `internal/` 配下の骨組みを追加する
2. `daemon` パッケージに環境変数解決、入力検証、JSON parse、ログ出力を実装する。`testdata/` の fixture を使った table-driven test を同時に追加する
3. `watcher` パッケージにポーリングループ、debounce、atomic consume を実装する。実際に tmp ディレクトリへファイルを書いて consume を確認する integration test を同時に追加する
4. `launcher` パッケージに interface、WezTerm / tmux の実装を追加する。生成されるコマンドライン引数の検証テストを同時に追加する
5. `daemon` パッケージに一時スクリプト生成とメインループを実装し、watcher と launcher を統合する。daemon loop 用の exec stub を `testutil` に追加し、daemon test を同時に追加する
6. `launchd` パッケージに plist 生成と `launchctl unload/load` を実装する。`testdata/` でスナップショット検証するテストを同時に追加する
7. `go test -coverprofile=coverage.out ./...` で coverage 80% 以上を確認し、不足があればテストを補強する
8. launchd plist、ドキュメント、起動導線を Go バイナリ前提に更新し、shellscript を非推奨または削除対象にする
9. 移行完了後に `daemon.sh`、`install-launchd.sh`、`launchers/*.sh`、`com.ai-bridge.daemon.plist` の削除可否を判断する

## File changes

| File                                                  | Change                                                                        |
| ----------------------------------------------------- | ----------------------------------------------------------------------------- |
| `scripts/ai-bridge/go.mod`                            | Go module を新設し、host-side 実装に必要な依存を定義する                      |
| `scripts/ai-bridge/cmd/ai-bridge/main.go`             | `daemon` / `install-launchd` subcommand の入口を実装する                      |
| `scripts/ai-bridge/internal/daemon/daemon.go`         | 設定、リクエスト処理、一時スクリプト生成、メインループを実装する              |
| `scripts/ai-bridge/internal/daemon/daemon_test.go`    | 設定解決、JSON parse、一時スクリプト生成、daemon loop の unit test を追加する |
| `scripts/ai-bridge/internal/watcher/watcher.go`       | ポーリング監視、debounce、atomic consume を実装する                           |
| `scripts/ai-bridge/internal/watcher/watcher_test.go`  | 実ファイルを使った consume の integration test を追加する                     |
| `scripts/ai-bridge/internal/launcher/launcher.go`     | launcher interface と factory を実装する                                      |
| `scripts/ai-bridge/internal/launcher/wezterm.go`      | WezTerm launcher の Go 実装を追加する                                         |
| `scripts/ai-bridge/internal/launcher/wezterm_test.go` | WezTerm コマンドライン引数生成の unit test を追加する                         |
| `scripts/ai-bridge/internal/launcher/tmux.go`         | tmux launcher の Go 実装を追加する                                            |
| `scripts/ai-bridge/internal/launcher/tmux_test.go`    | tmux コマンドライン引数生成の unit test を追加する                            |
| `scripts/ai-bridge/internal/launchd/plist.go`         | plist 生成、配置、launchctl 操作を実装する                                    |
| `scripts/ai-bridge/internal/launchd/plist_test.go`    | plist 生成の snapshot test を追加する                                         |
| `scripts/ai-bridge/internal/testutil/exec_stub.go`    | daemon loop テスト用の exec stub を追加する                                   |
| `scripts/ai-bridge/testdata/plist/expected.plist`     | plist 期待値 fixture を追加する                                               |
| `scripts/ai-bridge/testdata/request/valid.json`       | 正常系 request fixture を追加する                                             |
| `scripts/ai-bridge/testdata/request/invalid.json`     | 異常系 request fixture を追加する                                             |
| `scripts/ai-bridge/com.ai-bridge.daemon.plist`        | Go 移行完了後に削除する（plist は Go 側で完全生成する）                       |
| `scripts/ai-bridge/daemon.sh`                         | 削除、または一時的な互換ラッパーとして縮小する                                |
| `scripts/ai-bridge/install-launchd.sh`                | 削除、または Go subcommand 呼び出しラッパーへ置き換える                       |
| `scripts/ai-bridge/launchers/wezterm.sh`              | 削除、または移行期間限定の互換レイヤーにする                                  |
| `scripts/ai-bridge/launchers/tmux.sh`                 | 削除、または移行期間限定の互換レイヤーにする                                  |
| `docs/ai-bridge.md`                                   | セットアップ、ビルド、運用、トラブルシュートを Go 版に合わせて更新する        |

## Risks and mitigations

| Risk                                                                                            | Mitigation                                                                                                                          |
| ----------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Docker ボリュームマウント（VirtioFS / gRPC FUSE）では fsnotify のイベントが伝播しない場合がある | 初期実装ではポーリングを primary 方式とし、fsnotify は採用しない。現行 shell 版と同じくポーリングで Docker 環境との互換性を確保する |
| Go は標準ライブラリだけでファイルイベント監視を持たない                                         | ポーリング方式なら標準ライブラリのみで実装可能。将来 fsnotify を追加する場合も Go module 依存として閉じ込める                       |
| WezTerm / tmux 呼び出しの quoting 差分で挙動が変わる                                            | 既存 shell 実装を仕様として扱い、同じコマンドラインが生成されることをテストで固定する                                               |
| launchd インストールを Go に寄せると plist 生成バグで起動不能になる                             | plist 生成は `testdata` でスナップショット検証し、手動 smoke test も行う                                                            |
| shell 版と Go 版がしばらく並存すると起動経路が分かりにくい                                      | 移行期間を短くし、最終形は `ai-bridge daemon` と `ai-bridge install-launchd` に統一する                                             |
| バイナリ配布や build 手順が増えてセットアップが重くなる                                         | `go build -o scripts/ai-bridge/ai-bridge ./cmd/ai-bridge` の手順を docs に明記し、必要なら install 用の Make タスクを後続で追加する |
| coverage 80% を後追いで満たそうとすると無理なテストが増える                                     | 各実装ステップでテストを同時に書き、coverage を段階的に積み上げる                                                                   |

## Validation

- [ ] `go test ./...` が通る
- [ ] `go test -coverprofile=coverage.out ./...` の statement coverage が 80% 以上になる
- [ ] `ai-bridge daemon` が `AI_BRIDGE_DIR` 未設定時に `~/.ai-bridge/request.json` を監視できる
- [ ] `request.json` 作成後、1 回だけ launcher が起動する
- [ ] 同一リクエストで重複イベントが来ても二重起動しない
- [ ] `cwd` が存在しない場合に warning を出して安全にスキップする
- [ ] `prompt` または `cwd` が null / 空文字の JSON を安全に拒否できる
- [ ] WezTerm launcher と tmux launcher の Go 実装が既存 shell 版と同等に起動できる
- [ ] `ai-bridge install-launchd` が plist を正しく生成・配置し、`launchctl load` まで完了できる
- [ ] daemon 終了時に watcher が適切に停止し、consumed ファイルが残留していないこと
- [ ] Docker ボリュームマウント環境でポーリング監視が正常に動作すること
- [ ] `SIGTERM` 受信時に処理中のリクエストを完了してから終了すること

## Decisions

以下は当初 Open questions としていた項目への決定事項。

| Question            | Decision                                                             | Rationale                                                           |
| ------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------- |
| Go バイナリの配置先 | `go build -o` で repo 内の `scripts/ai-bridge/ai-bridge` に出力する  | plist からの参照が楽で、`go install` のような PATH 依存を避けられる |
| plist テンプレート  | Go で完全生成し、`com.ai-bridge.daemon.plist` は移行完了後に削除する | テンプレートファイルと `sed` の二重管理がなくなる                   |
| 監視方式            | ポーリングを primary にする。fsnotify は採用しない                   | Docker volume mount 環境での信頼性を優先する                        |
| 一時スクリプト方式  | 互換優先で維持する                                                   | `bash -lc` は長いプロンプトで引数長制限に当たるリスクがある         |
