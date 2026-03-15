# Plan

`.codex/skills` を `skills/` に移し、Codex/Claude/Cursor 向けにユーザーレベルの symlink を作れるようにする。あわせて、プランを書き出すスキルを追加し、README/Makefileを更新する。

## Scope

- In: skillsディレクトリ移行、symlink/copyのMakeターゲット追加、README更新、plan出力スキル追加、今回のプランをdocs/planに保存
- Out: 既存スキル内容の変更、各ツール側の挙動変更

## Action items

[ ] `.codex/skills` を `skills/` に移動し参照パスを更新する
[ ] Makefileに `skills-link`/`skills-unlink` と各ツール別link/copyターゲットを追加する
[ ] README/README.ja を新しいskills構成・コマンドに合わせて更新する
[ ] `plan-markdown-export` スキルを追加する
[ ] `docs/plan/YYYY-MM-DD_<plan-name>.md` に今回のプランを出力する
[ ] 新規Markdownに `markdownlint-cli2 --fix` を実行する
[ ] Cursorでsymlinkが効かない場合の代替（コピー/プロジェクト配置）をメモする

## Open questions

- なし
