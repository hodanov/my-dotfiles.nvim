# Log

2026-02-07 に、Dockerコンテナ上のNeovimヤンクをmacOSホストのクリップボードへ連携する設定変更を実施した。

## Summary

- `nvim/config/init.lua` のクリップボード設定を `OSC52` ベースへ更新した。
- `vim.opt.clipboard` を `unnamedplus` に統一し、`OSC52` 不可時のフォールバックを残した。
- コンテナ内でNeovim起動確認を行い、反映に再ビルドが必要な点とtmux注意点を共有した。

## Details

- 既存設定は `vim.opt.clipboard = "unnamed"` だったため、`vim.ui.clipboard.osc52` を `pcall` で読み込んで `vim.g.clipboard` を構成する形へ変更。
- `docker container exec nvim-dev nvim --headless '+qall'` で起動エラーがないことを確認。
- `docker container exec nvim-dev nvim --headless -u NONE '+lua local ok,_=pcall(require,"vim.ui.clipboard.osc52"); print(ok)' '+qall'` で `osc52` モジュール利用可を確認。
- 変更反映手順として `docker compose -f environment/docker/docker-compose.yml up -d --build nvim` を案内。
- tmux利用時の追加設定として `set -g set-clipboard on` を案内。
