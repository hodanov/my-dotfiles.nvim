# Plan: WezTerm 設定ファイルのモジュール分割

`.wezterm.lua`（364行）が肥大化し可読性が低下している。関心ごとに分離したモジュール構成に再編し、ワークスペース定義をデータ駆動にすることで、設定の見通しと保守性を改善する。

## Background

- `dotfiles/.wezterm.lua` に外観・キーバインド・ワークスペースレイアウトがすべて詰め込まれている
- ワークスペース定義（`setup_blog`, `setup_stable_diffusion`, `setup_my_pde`, `setup_new_project`）は同じパターンの繰り返しで約150行を占める
- 新しいワークスペースを追加するたびに関数コピペが発生し、変更忘れのリスクがある
- WezTerm は Lua の `require` によるモジュール分割をサポートしている（`$HOME/.config/wezterm/` 配下に配置）

## Current structure

```txt
dotfiles/
├── .wezterm.lua      # 364行、すべての設定が1ファイル
└── .zshrc
```

`.wezterm.lua` の内容構成：

| 行範囲  | 責務                                           | 行数 |
| ------- | ---------------------------------------------- | ---- |
| 1-50    | カラースキーマ・タブバー外観                   | ~50  |
| 52-71   | タブタイトルフォーマット（`format-tab-title`） | ~20  |
| 73-81   | フォント設定                                   | ~10  |
| 83-151  | 背景設定（コメントアウト含む）                 | ~70  |
| 153-157 | IME 設定                                       | ~5   |
| 159-209 | キーバインド                                   | ~50  |
| 211-361 | ワークスペースレイアウト定義 + gui-startup     | ~150 |

## Design policy

- **WezTerm の標準的なモジュール分割方式に従う**: `$HOME/.config/wezterm/wezterm.lua` をエントリポイントとし、同ディレクトリ内の Lua ファイルを `require` で読み込む
- **関心の分離**: 外観（色・フォント・背景）、キーバインド、ワークスペースを別ファイルに分ける
- **ワークスペース定義をデータ駆動にする**: 各ワークスペースの差分（名前・パス・タブ構成）だけをテーブルで宣言し、共通のセットアップロジックは1箇所にまとめる
- **dotfiles 管理との整合性**: `dotfiles/` ディレクトリ内に `wezterm/` を作り、symlink 先を `$HOME/.config/wezterm/` とする。既存の `.wezterm.lua` → `$HOME/.wezterm.lua` symlink からの移行も考慮する
- **コメントアウトされた背景画像設定は削除する**: git 履歴に残っているため、設定ファイルからは除去して見通しを良くする

## Implementation steps

1. **ディレクトリ構成を作成する**
   - `dotfiles/wezterm/` ディレクトリを新規作成
   - エントリポイント `dotfiles/wezterm/wezterm.lua` を作成

2. **外観設定を分離する** → `dotfiles/wezterm/appearance.lua`
   - カラースキーマ、タブバー、フォント、背景、`format-tab-title` イベントを移動
   - コメントアウトされた背景画像設定は削除（git 履歴で参照可能）
   - `return function(config) ... end` パターンで config を受け取って設定する関数を返す

3. **キーバインド設定を分離する** → `dotfiles/wezterm/keybindings.lua`
   - `config.keys` テーブルと `macos_forward_to_ime_modifier_mask` を移動
   - `update-right-status` イベントもワークスペース表示関連なのでここに含める

4. **ワークスペース定義をデータ駆動に再設計する** → `dotfiles/wezterm/workspaces.lua`
   - ワークスペース定義をテーブルの配列で宣言する：

     ```lua
     local workspaces = {
       {
         name = "blog",
         cwd = "workspace/hodalog-hugo",
         tabs = {
           { title = "nvim" },
           { title = "ai-cli" },
           { title = "ops" },
         },
       },
       {
         name = "stable-diffusion",
         cwd = "workspace/stable_diffusion_modal",
         tabs = {
           { title = "nvim+ops", split = { direction = "Bottom", size = 0.20 } },
         },
       },
       -- ...
     }
     ```

   - 共通セットアップロジック（`workspace_exists` チェック、タブ生成、ペイン分割）を1つの関数にまとめる
   - `gui-startup` と `setup-project-layouts` イベントの登録もこのモジュールで行う
   - デフォルトワークスペース名（起動時にアクティブにするもの）も設定可能にする

5. **エントリポイントを組み立てる** → `dotfiles/wezterm/wezterm.lua`

   ```lua
   local wezterm = require("wezterm")
   local config = wezterm.config_builder()

   require("appearance")(config)
   require("keybindings")(config)
   require("workspaces")(config)

   return config
   ```

6. **symlink 管理を更新する**
   - 既存の `.wezterm.lua` → `$HOME/.wezterm.lua` symlink を削除
   - `dotfiles/wezterm/` → `$HOME/.config/wezterm/` への symlink を設定
   - 必要に応じて Makefile やセットアップスクリプトを更新

7. **旧ファイルを削除する**
   - `dotfiles/.wezterm.lua` を削除（git 履歴で参照可能）

## File changes

| File                                | Change                                                          |
| ----------------------------------- | --------------------------------------------------------------- |
| `dotfiles/wezterm/wezterm.lua`      | 新規作成: エントリポイント、各モジュールを require して組み立て |
| `dotfiles/wezterm/appearance.lua`   | 新規作成: カラー・タブバー・フォント・背景・タブタイトル        |
| `dotfiles/wezterm/keybindings.lua`  | 新規作成: キーバインド・IME設定・ステータスバー                 |
| `dotfiles/wezterm/workspaces.lua`   | 新規作成: データ駆動のワークスペース定義 + セットアップロジック |
| `dotfiles/.wezterm.lua`             | 削除                                                            |
| Makefile 等のセットアップスクリプト | symlink 先を `.wezterm.lua` → `.config/wezterm/` に変更         |

## Risks and mitigations

| Risk                                                                                       | Mitigation                                                                                                          |
| ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------- |
| WezTerm の `require` パス解決が `$HOME/.config/wezterm/` 以外を見ない可能性                | WezTerm は `wezterm.lua` と同じディレクトリを `package.path` に含める仕様。事前にミニマル構成で動作確認する         |
| 既存の `$HOME/.wezterm.lua` symlink が残っていると旧設定が優先される                       | WezTerm の設定ファイル優先順位: `.wezterm.lua` > `.config/wezterm/wezterm.lua`。移行時に旧 symlink を確実に削除する |
| ワークスペースのデータ駆動化で `stable-diffusion` のようなペイン分割付き定義が表現できない | テーブル定義に `split` オプションを持たせ、分割パターンも宣言的に記述できるようにする                               |
| 背景画像のコメントアウト削除で過去設定の参照が面倒になる                                   | git 履歴で十分参照可能。必要なら `appearance.lua` 内にコメントで commit hash を残す                                 |

## Validation

- [x] `dotfiles/wezterm/wezterm.lua` を `$HOME/.config/wezterm/wezterm.lua` に symlink して WezTerm を再起動し、全設定が反映されることを確認
- [x] タブバーの外観（アクティブ/非アクティブ/ホバー）が変更前と同一であること
- [x] フォント・背景が正しく表示されること
- [x] `format-tab-title` によるタブタイトル表示が動作すること
- [x] キーバインド（`CMD+S`, `CTRL+SHIFT+W`, `CMD+N`, `SHIFT+Enter`, `CMD+SHIFT+R`）が全て動作すること
- [x] `gui-startup` で4つのワークスペースが作成され、`blog` がアクティブになること
- [x] `CMD+SHIFT+R` でワークスペースの追加生成（既存スキップ）が動作すること
- [x] `stable-diffusion` ワークスペースのペイン分割が正しく動作すること
- [x] 旧 `.wezterm.lua` symlink を削除した状態で起動エラーが出ないこと

## Open questions

All resolved:

- ~~Makefile に dotfiles 用ターゲットは無かった~~ → `dotfiles-link` / `dotfiles-unlink` を追加
- ~~`new-project` はテンプレート？~~ → 実際のプロジェクト。まっさらな状態から新規開発する起点
- ~~外部ファイル（TOML/JSON）にするか？~~ → Lua テーブルで OK
