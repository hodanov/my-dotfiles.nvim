# Plan: write-blog-entry スキルの作成

ブログ執筆を対話的に支援するスキルを `.claude/skills/write-blog-entry/` に作成する。
AIとの壁打ち結果やメモを入力として、アウトライン提案 → 承認 → 執筆 → textlint 校正までを段階的に進める。

## Background

- このリポジトリは DMM Developers Blog の記事を管理しており、`draft_entries/` で下書き、`entries/` で公開記事を保持する
- 記事はてなブログ形式の Markdown（YAML Front Matter + はてなブログ記法）で書かれる
- textlint による日本語校正、prh による表記統一が CI で自動実行される
- 既存の `blog-idea-draft-export` スキルはアイデアの下書きエクスポートに特化しており、対話的な執筆支援はカバーしていない

## Current structure

- `draft_entries/` — 下書き記事の配置先（執筆はここで行う）
- `entries/dmmtech.hatenablog.com/entry/YYYY/MM/DD/HHMMSS.md` — 公開済み記事
- `draft.template` — 新規記事テンプレート（Front Matter + サムネイル + `[:contents]`）
- `.textlintrc` — textlint 設定（JSONC 形式）
- `prh_rules.yml` — 校正ルール（禁止表現・表記統一）
- `allowlist.yml` — textlint 誤検知回避リスト
- `AGENTS.md` — リポジトリ規約（AIエージェント向け）

## Design policy

- Phase 2（アウトライン提案）でユーザー承認を得るまで執筆に進まない（対話ゲート）
- 入力解決は 引数ファイル → セッションコンテキスト → ユーザーに確認 の3段階
- textlint のバリデーションループで校正エラーを自動修正する
- テンプレートは `template.md` に分離し、SKILL.md は手順に集中する（progressive disclosure）
- prh / textlint の詳細ルールは AGENTS.md に記載済みなのでスキル内では重複させない

## Implementation steps

1. `.claude/skills/write-blog-entry/` ディレクトリを作成する
2. `SKILL.md` を作成する（4フェーズのワークフロー: 入力把握 → アウトライン提案 → ファイル解決 → 執筆+校正）
3. `template.md` を作成する（`draft.template` の Front Matter 形式 + はてなブログ記法を反映した記事骨格）
4. `.cursor/rules/` に Cursor 向けの `.mdc` ファイルを作成し、スキルの存在を認識させる

## File changes

| File | Change |
| ---- | ------ |
| `.claude/skills/write-blog-entry/SKILL.md` | 新規作成 — 執筆支援スキルのメイン手順書 |
| `.claude/skills/write-blog-entry/template.md` | 新規作成 — 記事の骨格テンプレート |
| `.cursor/rules/write-blog-entry.mdc` | 新規作成 — Cursor 向けスキル認識ルール |

## Risks and mitigations

| Risk | Mitigation |
| ---- | ---------- |
| textlint 自動修正で意図しない書き換えが起きる | バリデーションループ後にユーザーに差分を確認させる |
| 入力が曖昧なまま執筆が始まる | Phase 1 で入力不足時は推測せずユーザーに確認する |
| アウトラインが承認なしで進む | Phase 2 に明示的な承認ゲートを設ける |
| Front Matter の自動生成フィールドを壊す | `Title` 以外の Front Matter フィールドは編集しないルールを明記 |

## Validation

- [ ] `/write-blog-entry` で SKILL.md が正しく読み込まれる
- [ ] メモファイルを入力にアウトライン提案ができる
- [ ] 承認後に `draft_entries/` 配下のファイルが正しく更新される
- [ ] `npx textlint` でエラーが出た場合に修正ループが動く
- [ ] 新規記事作成時に `draft.template` のフォーマットが反映される

## Open questions

- `draft_entries/` に新規ファイルを作成する場合のファイル名規則（GitHub Actions の `create-draft` ワークフローとの整合性）
- Cursor 環境では `.claude/skills/` を直接読み込めないため、`.cursor/skills/` にもコピーを置くべきか
