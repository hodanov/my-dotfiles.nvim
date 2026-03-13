# Plan: ai-bridge ポーリング廃止 → fsnotify イベント駆動化

ai-bridge の request.json 検知を `time.Ticker` による 1 秒間隔ポーリングから、OS レベルのファイルシステム通知 (kqueue) に置き換え、即時検知に変更する。`github.com/fsnotify/fsnotify` を導入し、`watcher.go` の Ticker を全面置換する。

## Background

- ai-bridge は Neovim (Docker) と AI CLI (macOS ホスト) を `~/.ai-bridge/request.json` のファイル経由で接続している
- 現在 `time.Ticker` で 1 秒間隔ポーリングしており、最悪 1 秒のレイテンシが発生する
- Neovim Lua 側の変更は不要

## Current structure

- `scripts/ai-bridge/internal/watcher/watcher.go` — `Watcher` 構造体が `time.Ticker` でポーリング
- `scripts/ai-bridge/internal/daemon/daemon.go` — `Config.PollInterval` で interval を管理、`Run()` で `watcher.New(dir, interval)` を呼び出し
- `scripts/ai-bridge/internal/watcher/watcher_test.go` — `New(dir, 50*time.Millisecond)` で 5 箇所呼び出し
- `scripts/ai-bridge/internal/daemon/daemon_test.go` — `pollInterval` フィールドと "zero poll interval" テストケースが存在

## Design policy

- `github.com/fsnotify/fsnotify` を導入し、`time.Ticker` を完全置換
- `Create + Write` の両方をトリガーにする。Lua 側は `open("w")` → `write()` → `close()` の順で処理するため、`tryConsume()` のアトミック rename で重複イベントを排除
- fsnotify 開始前に既存の `request.json` があれば起動時チェックで即処理
- Docker for Mac の VirtioFS は kqueue イベントを伝播するため互換性あり
- テストカバレッジ 80% 以上を維持

## Implementation steps

1. `go get github.com/fsnotify/fsnotify` で依存追加
2. `watcher.go` を書き換え: `interval` フィールド・引数を削除、`isRequestEvent` ヘルパー追加、`Watch()` 内で fsnotify ベースのイベントループに置換、起動時チェック追加
3. `daemon.go` を変更: `Config.PollInterval` 削除、`LoadConfig()` / `Run()` から interval 関連コード削除、`watcher.New(cfg.BridgeDir)` に変更
4. テスト修正: `watcher_test.go` の `New(dir, 50*time.Millisecond)` → `New(dir)` (5 箇所)、`daemon_test.go` の `pollInterval` 削除と "zero poll interval" テストケース削除
5. カバレッジ向上テスト追加: `TestWatch_InvalidDirClosesChannel`、`TestTryConsume_RenameError`、`TestWatch_IgnoresNonRequestFile`、`TestWatch_ExistingFileConsumedOnStart`
6. Dependabot に gomod エコシステム追加、GitHub Actions CI ワークフロー追加
7. `go mod tidy && go build ./... && go test ./... -v -count=1` で全テスト通過を確認

## File changes

| File | Change |
| --- | --- |
| `scripts/ai-bridge/go.mod` (+`go.sum`) | `github.com/fsnotify/fsnotify v1.9.0` 追加 |
| `scripts/ai-bridge/internal/watcher/watcher.go` | Ticker → fsnotify。`New()` から `interval` 引数削除。`isRequestEvent` ヘルパー追加。起動時チェック追加 |
| `scripts/ai-bridge/internal/watcher/watcher_test.go` | `New()` 呼び出しから `interval` 引数削除 (5 箇所)。カバレッジ向上テスト 4 件追加 |
| `scripts/ai-bridge/internal/daemon/daemon.go` | `Config.PollInterval` 削除。`LoadConfig()` / `Run()` から interval 関連コード削除 |
| `scripts/ai-bridge/internal/daemon/daemon_test.go` | `pollInterval` 参照削除。"zero poll interval" テストケース削除 |
| `.github/dependabot.yml` | gomod エコシステム (`scripts/ai-bridge`) 追加 |
| `.github/workflows/test_ai_bridge.yml` | PR 時に `scripts/ai-bridge/**` 変更で `go test` を実行する CI ワークフロー新規作成 |

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| fsnotify が VirtioFS 経由のイベントを拾えない可能性 | Docker for Mac の VirtioFS は kqueue イベントを伝播するため互換性あり。手動検証で確認 |
| 起動前に書き込まれた request.json が未処理になる | イベントループ開始前に `tryConsume()` で起動時チェックを実行 |
| 重複イベント (Create + Write が連続発火) で二重処理される | `tryConsume()` のアトミック rename (`os.Rename`) が二重消費を排除 |
| テストで起動時チェックとイベントループの consume がレースする | ファイル書き込み前に `time.Sleep(100ms)` を挿入してイベントループ到達を保証 |

## Validation

- [ ] `go test ./... -v -count=1` で全テスト通過
- [ ] watcher.go テストカバレッジ 80% 以上 (実績: 81.0%)
- [ ] daemon.go テストカバレッジ 80% 以上 (実績: 84.7%)
- [ ] `ai-bridge daemon` を起動し、Neovim から `<Space>ai` でリクエスト送信 → 即座に (1 秒待ちなく) ターミナルが開くことを確認
- [ ] 連続送信しても重複処理されないことを確認
- [ ] GitHub Actions CI が PR で正しくトリガーされることを確認

## Open questions

なし
