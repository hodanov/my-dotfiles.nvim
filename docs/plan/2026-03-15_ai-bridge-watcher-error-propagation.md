# Plan: Watcher 初期化エラーの伝播

`Watch` メソッドの fsnotify 初期化をゴルーチン外に移動し、初期化失敗時にエラーを呼び出し元へ返すようにする。
現状はチャネルが即クローズされるだけで `daemon.Run` が正常終了してしまい、サイレント停止の運用事故につながる。

## Background

- コードレビュー（Phase 2）で [High] として検出された問題
- `Watch` 内の `fsnotify.NewWatcher()` / `fsw.Add()` の失敗がゴルーチン内で `slog.Error` されるだけで、呼び出し元に伝播しない
- `daemon.Run` は `range ch` の終了を正常終了と見なし `nil` を返す
- launchd の `KeepAlive: true` により無限再起動ループになるリスクがある

## Current structure

- `internal/watcher/watcher.go` — `Watch(ctx) <-chan string` で fsnotify 監視を開始
- `internal/daemon/daemon.go` — `Run` が `Watch` を呼び、チャネルからリクエストを消費
- `internal/watcher/watcher_test.go` — 8 テストケース（正常系・異常系）
- `internal/daemon/daemon_test.go` — `TestRun` で daemon ループの統合テスト

## Design policy

- fsnotify の初期化（`NewWatcher` + `Add`）をゴルーチンの外で同期的に実行する
- 初期化失敗は `error` として呼び出し元に返す
- 成功時のみゴルーチンを起動してイベントループに入る
- `slog.Error` のログは削除する（エラーハンドリングは呼び出し元の責務）

## Implementation steps

1. `watcher.go`: `Watch` のシグネチャを `Watch(ctx context.Context) (<-chan string, error)` に変更
2. `watcher.go`: `fsnotify.NewWatcher()` と `fsw.Add()` をゴルーチンの外に移動し、失敗時は `(nil, error)` を返す
3. `watcher.go`: 成功時のみゴルーチンを起動し、`(ch, nil)` を返す
4. `daemon.go`: `Watch` の戻り値にエラーチェックを追加
5. `watcher_test.go`: 全テストで `ch, err` の2値を受け取るよう更新
6. `watcher_test.go`: `TestWatch_InvalidDirClosesChannel` を `TestWatch_InvalidDirReturnsError` にリネームし、エラーが返ることを検証する形に変更
7. 全テスト実行で既存テストが壊れていないことを確認

## File changes

| File | Change |
| --- | --- |
| `internal/watcher/watcher.go` | `Watch` のシグネチャ変更、初期化を同期実行に移動、`slog.Error` 削除 |
| `internal/daemon/daemon.go` | `Watch` 呼び出しにエラーチェック追加（2行） |
| `internal/watcher/watcher_test.go` | 全テストで `ch, err` 対応、`InvalidDir` テストの検証方法変更 |
| `internal/daemon/daemon_test.go` | 変更不要（`Run` 経由で間接的にカバー） |

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| シグネチャ変更で外部から `Watch` を呼ぶコードが壊れる | `Watch` の呼び出し元は `daemon.Run` のみ。同時に修正する |
| 初期化成功後のイベントループ内エラー（`fsw.Errors`）は従来通りログのみ | イベントループ中のエラーは一時的なものが多く、ログで十分。今回のスコープ外 |

## Validation

- [ ] `go test ./internal/watcher/...` が全パス
- [ ] `go test ./internal/daemon/...` が全パス
- [ ] `go test ./...` が全パス
- [ ] `TestWatch_InvalidDirReturnsError` で `error != nil` が検証されている
- [ ] 正常系テストで `err == nil` が検証されている

## Open questions

- なし
