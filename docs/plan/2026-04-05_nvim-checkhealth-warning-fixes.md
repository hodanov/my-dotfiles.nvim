# Plan: Neovim checkhealth Warning 対策

Neovim 0.12.0 への更新後に `:checkhealth` で出ている Warning を解消する。
Nvim 0.12 での API 変更への追従と、Docker コンテナ環境のツール不足が主な対象。
対応不要な Warning（ヘッドレス環境起因）は明示的にスキップする。

## Background

- Neovim 0.12.0 で `vim.lsp.with()` が deprecated になり、LSP 設定の登録方式も変更された
- Docker コンテナ内で `fd` が未インストール、Neovim provider 用パッケージも未導入
- `:checkhealth` で計 16 件の Warning が出ている（対処対象は 14 件）

## Current structure

- `nvim/config/init.lua` — Neovim エントリーポイント（Docker 内で `/root/.config/nvim/init.lua` にコピー）
- `nvim/config/lua/lsp/init.lua` — LSP 設定（`vim.lsp.enable()` + キーマップ + diagnostics 設定）
- `nvim/config/lua/plugins.lua` — lazy.nvim プラグイン定義
- `environment/docker/nvim.dockerfile` — マルチステージ Dockerfile

## Implementation steps

1. `nvim/config/lua/lsp/init.lua` の `vim.lsp.with()` を `vim.diagnostic.config()` に置換する

   ```lua
   -- Before (deprecated in Nvim 0.12)
   vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
     vim.lsp.diagnostic.on_publish_diagnostics, { virtual_text = false }
   )

   -- After
   vim.diagnostic.config({ virtual_text = false })
   ```

2. `nvim/config/lua/plugins.lua` で `nvim-lspconfig` を即時読み込みに変更する

   ```lua
   -- Before
   { "neovim/nvim-lspconfig", lazy = true, event = { "BufRead", "BufNewFile" } }

   -- After
   { "neovim/nvim-lspconfig", lazy = false }
   ```

   `vim.lsp.enable()` が呼ばれる前に `vim.lsp.config()` が登録されている必要があるため。

3. `nvim/config/init.lua` の先頭付近で未使用 provider を無効化する

   ```lua
   vim.g.loaded_node_provider = 0
   vim.g.loaded_perl_provider = 0
   vim.g.loaded_python3_provider = 0
   vim.g.loaded_ruby_provider = 0
   ```

4. `environment/docker/nvim.dockerfile` の final stage で `fd-find` を追加する

## File changes

| File                                 | Change                                                               |
| ------------------------------------ | -------------------------------------------------------------------- |
| `nvim/config/lua/lsp/init.lua`       | `vim.lsp.with()` → `vim.diagnostic.config({ virtual_text = false })` |
| `nvim/config/lua/plugins.lua`        | `nvim-lspconfig` を `lazy = false` に変更                            |
| `nvim/config/init.lua`               | 先頭付近に未使用 provider 無効化（node, perl, python3, ruby）        |
| `environment/docker/nvim.dockerfile` | final stage の `apt-get install` に `fd-find` 追加                   |

## Risks and mitigations

| Risk                                                      | Mitigation                                             |
| --------------------------------------------------------- | ------------------------------------------------------ |
| `nvim-lspconfig` を即時読み込みにすると起動時間が微増する | nvim-lspconfig は軽量なので影響は無視できるレベル      |
| provider 無効化で将来プラグインが動かなくなる可能性       | 必要になった時点で該当 provider だけ再有効化すれば良い |
| `fd-find` 追加で Docker イメージサイズが微増する          | ~2MB 程度。telescope の機能拡張のメリットが上回る      |

## Validation

- [x] Docker イメージをリビルドする
- [x] コンテナ内で `nvim --headless -c 'checkhealth' -c 'qall'` を実行し Warning を確認する
- [x] 残る Warning が `vim.ui.open` の 1 件のみであることを確認する
- [x] 実際にファイルを開いて LSP（補完、定義ジャンプ等）が正常動作することを確認する

## Skipped (対応不要)

- **`vim.ui.open` no handler** — Docker コンテナ内に GUI オープナーがないため。ヘッドレス環境では想定内の Warning。

## Appendix: 補足事項

### A1. `vim.diagnostic.config()` を選ぶ理由

checkhealth の ADVICE には「`vim.lsp.buf` の同等関数を使え」と書かれているが、これは `vim.lsp.with()` の全ケースに対する汎用メッセージ。実際の代替先は元の用途によって異なる。

- `vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })` → `vim.lsp.buf.hover({ border = "rounded" })` — ハンドラのオプション変更は `vim.lsp.buf` 側で渡す
- `vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, { virtual_text = false })` → diagnostics の表示制御なので `vim.diagnostic.config()` が正解

今回のコードは diagnostic の `virtual_text` 設定であり、`vim.lsp.buf` に該当する API は存在しない。

### A2. Neovim provider とは何か・無効化の判断根拠

provider は外部言語で書かれたプラグイン（リモートプラグイン）を実行するためのブリッジ。

| Provider | 用途                       | 必要パッケージ | 使用例                         |
| -------- | -------------------------- | -------------- | ------------------------------ |
| Python3  | Python 製プラグインの実行  | `pynvim`       | `deoplete.nvim`, `denite.nvim` |
| Node.js  | Node.js 製プラグインの実行 | `neovim` npm   | `coc.nvim`                     |
| Ruby     | Ruby 製プラグインの実行    | `neovim` gem   | 一部の Vim プラグイン          |
| Perl     | Perl 製プラグインの実行    | `Neovim::Ext`  | ほぼ使われていない             |

現在の設定で使っているプラグインは全て Lua か Vimscript ベース（blink.cmp, telescope, conform, nvim-lint 等）。リモートプラグインを使うものがないため、無効化して問題ない。将来 provider が必要なプラグインを入れた場合は、該当行を削除すれば復活する。

### A3. `fd` の役割と telescope での用途

`fd` は `find` コマンドの高速な代替（Rust 製）。telescope では主にファイル名ベースの検索（`Telescope find_files` 等）でファイル一覧の取得に使われる。

| 機能                       | `fd` なし                      | `fd` あり                     |
| -------------------------- | ------------------------------ | ----------------------------- |
| ファイル名でのファジー検索 | 内蔵のファイルスキャン（遅め） | `fd` で高速にファイル一覧取得 |
| ファイル内容の grep 検索   | `rg` で動作（影響なし）        | 変わらず `rg`                 |

なくても動作するが、大きいワークスペースでファイルを探す際に体感差が出る。
