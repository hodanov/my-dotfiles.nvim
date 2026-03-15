# Log

2026-02-01 に実施した作業ログ。

## Summary

- `.codex/skills` を `skills/` に移行し、`.codex` を削除
- Skills配布をsymlinkではなくコピーに寄せ、Makefile/READMEを更新
- プラン出力用の `plan-markdown-export` スキルを追加
- `docs/plan/2026-02-01_skills-symlink-plan.md` を作成
- Claude/Cursor に skills をコピー（Codexは既存スキル衝突でスキップ）

## Details

- Makefile
  - skills系ターゲットをcopy前提に整理
  - `skills-copy` とツール別 `*-skills-copy` を追加
- README
  - skillsの使い方をコピー前提で更新
- Skills
  - `skills/plan-markdown-export` を追加
- 実行
  - `make skills-copy` は Codex で上書き確認により停止
  - `make claude-skills-copy cursor-skills-copy` を実行
