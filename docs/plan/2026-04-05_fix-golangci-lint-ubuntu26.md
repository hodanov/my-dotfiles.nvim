# Plan: Fix golangci-lint missing in nvim container after Ubuntu 26.04 upgrade

Ubuntu 26.04 ベースの nvim-dev コンテナで `golangci-lint` バイナリが欠落し、Neovim の diagnostic に `exec: "golangci-lint": executable file not found in $PATH` が出る問題を修正する。

## Background

- Ubuntu 26.04 (Resolute Raccoon) にアップグレード後、nvim-dev コンテナ内で `golangci-lint` が見つからなくなった
- Neovim でGoファイルを開くと diagnostic エラーが表示される
- ホスト (macOS) 側には `golangci-lint` v2.11.3 がインストール済みだが、コンテナ内には存在しない

## Current structure

- Docker イメージ: `docker-nvim` (コンテナ名: `nvim-dev`)
- Dockerfile: `environment/docker/nvim.dockerfile`
- Go ツール定義: `environment/tools/go/go-tools.txt`
- Go ツールは multi-stage build の `go-builder` ステージで `go install` によりビルドされ、final ステージへ `COPY --from=go-builder /root/go/bin/ /root/go/bin/` でコピーされる

### go-tools.txt の内容

```text
golang.org/x/tools/cmd/...@v0.36.0
golang.org/x/tools/gopls@v0.21.1
github.com/go-delve/delve/cmd/dlv@v1.26.1
github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.3.1
github.com/nametake/golangci-lint-langserver@v0.0.12
```

## Root cause

原因は2つの問題の組み合わせ。

### 1. Ubuntu 26.04 で `ld.gold` が削除された

Go 1.26 の CGO リンクは `-fuse-ld=gold` を使用するが、Ubuntu 26.04 では `binutils` パッケージから `ld.gold` が削除された（upstream で gold リンカが非推奨化）。`binutils-gold` パッケージも `Candidate: (none)` でインストール不可。

```
# コンテナ内のリンカ状態
/usr/bin/ld      -> aarch64-linux-gnu-ld (bfd のみ)
/usr/bin/ld.bfd  -> aarch64-linux-gnu-ld.bfd
# ld.gold は存在しない
```

これにより `go install` 時に以下のエラーが発生:

```
/usr/bin/gcc -Wl,-z,now -Wl,-z,nocopyreloc -fuse-ld=gold ...
collect2: fatal error: cannot find 'ld'
compilation terminated.
```

### 2. go-tools.txt のインストールループにエラーハンドリングがない

```dockerfile
RUN while read -r pkg; do go install "$pkg"; done < /tmp/go-tools.txt
```

`go install` が失敗しても `while read` ループは次のツールに進む。結果として `golangci-lint` のビルド失敗が無視され、次の `golangci-lint-langserver`（CGO 不要で成功）だけがインストールされた状態でイメージが完成していた。

## Design policy

- 開発ツール (`golangci-lint`, `gopls`, `dlv` 等) は C ライブラリへの依存が不要なため、`CGO_ENABLED=0` で静的ビルドする
- ツールインストールの失敗はビルドエラーとして検出できるようにする

## Implementation steps

1. `nvim.dockerfile` の go-builder ステージで `CGO_ENABLED=0` を追加し、`|| exit 1` でエラーハンドリングを追加する

## File changes

| File                                      | Change                                                                                       |
| ----------------------------------------- | -------------------------------------------------------------------------------------------- |
| `environment/docker/nvim.dockerfile` L106 | `go install` に `CGO_ENABLED=0` を追加し、`\|\| exit 1` でエラー時にビルドを停止するよう変更 |

### 変更前

```dockerfile
RUN while read -r pkg; do go install "$pkg"; done < /tmp/go-tools.txt
```

### 変更後

```dockerfile
RUN while read -r pkg; do \
      CGO_ENABLED=0 go install "$pkg" || exit 1; \
    done < /tmp/go-tools.txt
```

## Risks and mitigations

| Risk                                                                     | Mitigation                                                                                                         |
| ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| `CGO_ENABLED=0` により CGO 依存のツールがビルドできなくなる              | 現在の go-tools.txt に含まれるツールは全て CGO 不要。将来 CGO 必須ツールを追加する場合はそのツールだけ個別対応する |
| 今後 go-tools.txt に追加したツールが失敗するとイメージビルド全体が止まる | これは意図した動作。サイレントに壊れるより早期検出の方が望ましい                                                   |

## Validation

- [ ] `docker-nvim` イメージを再ビルドしてエラーなく完了することを確認
- [ ] コンテナ内で `golangci-lint version` が実行できることを確認
- [ ] コンテナ内で `which golangci-lint` が `/root/go/bin/golangci-lint` を返すことを確認
- [ ] Neovim で Go ファイルを開いた際に `executable file not found` の diagnostic が出ないことを確認
- [ ] 他の Go ツール (`gopls`, `dlv`, `golangci-lint-langserver`) も正常に動作することを確認
