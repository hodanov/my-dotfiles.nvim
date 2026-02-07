# Plan

Dockerコンテナ上で動くNeovimから、ヤンク内容をmacOSホストのクリップボードへ渡せるようにする。  
Neovim標準のOSC52プロバイダを使って `vim.g.clipboard` を構成し、既存設定への影響を最小化する。  
あわせて、反映手順と実行時の注意点（再ビルドとtmux設定）を明確にする。

## Scope

- In:
  - `nvim/config/init.lua` のクリップボード設定を `OSC52` ベースに更新する。
  - `unnamedplus` を使う設定へ揃える。
  - 反映手順（コンテナ再ビルド）と補足（tmux）を記録する。
- Out:
  - Dockerイメージへの `pbcopy/xclip` 追加。
  - ターミナルアプリ固有設定の自動変更。
  - tmux設定ファイルそのものの編集。

## Action items

[x] 現在のNeovim/Docker設定を確認し、クリップボード連携の前提条件を特定する。  
[x] `nvim/config/init.lua` で `vim.ui.clipboard.osc52` を使う設定へ置き換える。  
[x] `OSC52` が使えない場合のフォールバックを残す。  
[x] Neovim起動チェックを実施し、変更で致命的な起動エラーがないことを確認する。  
[x] 反映にコンテナ再ビルドが必要である点を明示する。  
[x] tmux利用時の `set -g set-clipboard on` を補足する。

## Open questions

- 普段使っているターミナルはOSC52を有効化済みか。  
- tmuxを常用しているか（有効なら設定追加が必要）。  
- 将来的に貼り付け側（`paste`）の挙動を追加検証するか。
