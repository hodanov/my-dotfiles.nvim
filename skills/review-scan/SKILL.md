---
name: review-scan
description: >-
  code-review-scanner と code-review-critic による2フェーズレビュー。
  大きなPRや複雑な変更を丁寧にレビューしたいときに使う。
  scanner がトリアージして重要な指摘だけ critic が深掘りする。
  軽いチェックには /review（4並列専門レビュー）を使う。
disable-model-invocation: true
argument-hint: "[PR番号 | ブランチ名 | staged]"
---

# /review-scan スキル

## Goal

code-review-scanner（Phase 1）で変更を広くスキャンし、
code-review-critic（Phase 2）で高優先の指摘を深掘りする2段階レビュー。

## Workflow

### Step 1: diff 取得

引数に応じて diff を取得する:

- **PR番号** (例: `123`, `#123`): `gh pr diff <番号>` を実行
- **ブランチ名** (例: `feature/xxx`): `git diff main...<ブランチ名>` を実行
- **`staged`**: `git diff --staged` を実行
- **引数なし**: `git diff --staged` を実行（デフォルト）

diff が空の場合はユーザーに通知して終了する。

### Step 2: Phase 1 — code-review-scanner

Agent tool で `code-review-scanner` を起動する。

- `subagent_type`: `code-review-scanner`
- プロンプト:

```text
以下の diff をレビューしてください。

<diff>
{diff内容}
</diff>
```

scanner から **Scan Report**（優先度付きの指摘リスト）を受け取る。

### Step 3: Scan Report 提示

Scan Report の内容をユーザーに表示する。以下の形式で出力する:

```markdown
## Scan Report (Phase 1)

### 概要
(scanner の総合所見 2-3文)

### 指摘一覧
(各指摘を優先度順に記載。Critical → Warning → Info の順。)

### Phase 2 推奨
(Critical/Warning があれば Phase 2 での深掘りを推奨。なければ「Phase 2 不要」。)
```

### Step 4: Phase 2 — code-review-critic（ユーザー判断）

Critical または Warning レベルの指摘がある場合:

1. Phase 2 の実行をユーザーに提案する
2. ユーザーが承認したら Agent tool で `code-review-critic` を起動する
   - `subagent_type`: `code-review-critic`
   - プロンプトには Scan Report 全文を含める
3. critic から受け取った結果を以下の形式で出力する:

```markdown
## Deep Review Report (Phase 2)

### 詳細分析
(critic の深掘り結果。具体的な改善提案を含む。)

### 判定
- [ ] Approve — 問題なし、マージ可能
- [ ] Approve with comments — 軽微な指摘あり、修正推奨だがマージ可能
- [ ] Request changes — 修正が必要、再レビュー推奨
```

Critical/Warning がない場合は Phase 1 の結果のみで完了とする。

## Notes

- Phase 1 のみで完了できるケースも多い。Phase 2 は本当に必要なときだけ
- 日常的な軽いチェックには `/review`（4並列専門レビュー）が適している
- `/review` との使い分け: 大きなPR・複雑な変更 → `/review-scan`、小〜中規模の変更 → `/review`
