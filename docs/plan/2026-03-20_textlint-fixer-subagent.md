# Plan: write-blog-entry Phase 4 の校正をサブエージェントに委譲する

Phase 4 の textlint 校正ループを専用サブエージェント `textlint-fixer` に切り出し、コンテキスト汚染を回避する。
親エージェント（スキル実行者）は執筆に集中し、校正結果は構造化レポートとして受け取る。

## Background

- 現行の Phase 4 は「執筆 → textlint 実行 → エラー修正 → 再実行」を親エージェントが全部やっており、校正のノイズがコンテキストウィンドウを圧迫する
- my-pde の review-scan スキルでは Phase 1（scanner）→ Phase 2（critic）を別サブエージェントに委譲するパターンが確立済み
- サブエージェントはサブエージェントを生成できないため、親がオーケストレーターを担う
- Claude Code の `.claude/agents/` にサブエージェント定義を配置し、Agent tool で起動する

## Current structure

- `.claude/skills/write-blog-entry/SKILL.md` — 執筆支援スキル（Phase 1〜4）
- `.claude/skills/write-blog-entry/template.md` — 記事骨格テンプレート
- `.textlintrc` — textlint 設定（JSONC 形式、`preset-ja-technical-writing` ベース）
- `prh_rules.yml` — 校正ルール（禁止表現・表記統一）
- `allowlist.yml` — textlint 誤検知回避リスト
- `.claude/agents/` — 未作成（今回新設）

## Design policy

- **校正のコンテキストを分離する**: lint エラー出力のパース・修正・再実行はすべてサブエージェント内で完結させ、親のコンテキストを汚さない
- **構造化レポートでインターフェースを明確にする**: my-pde の Scout Report / Diver Report パターンと同様、出力フォーマットを固定する
- **acceptEdits + Edit only で安全かつ高速に**: 修正ループの承認ストレスを排除しつつ、Write を外して意図しないファイル作成を防ぐ
- **model: sonnet で日本語対応を確保する**: 校正修正には日本語の文脈理解が必要なため haiku は避ける
- **プロジェクトスコープで配置する**: `.textlintrc` に依存するため `.claude/agents/`（プロジェクト）に置く
- **Cursor 版は今回スコープ外とする**: `.cursor/skills/` の SKILL.md は同期するが、Cursor 固有のサブエージェント対応は行わない

## Implementation steps

1. `.claude/agents/textlint-fixer.md` を作成する（frontmatter + system prompt + 出力フォーマット定義）
2. `.claude/skills/write-blog-entry/SKILL.md` の Phase 4 を Phase 4（執筆）+ Phase 5（校正）に分割し、サブエージェント委譲フローに書き換える
3. `.cursor/skills/write-blog-entry/SKILL.md` に同じ変更を反映する
4. `draft_entries/` の既存記事で動作検証する

## File changes

| File | Change |
| ---- | ------ |
| `.claude/agents/textlint-fixer.md` | 新規作成 — textlint 校正サブエージェント定義 |
| `.claude/skills/write-blog-entry/SKILL.md` | Phase 4 を Phase 4（執筆）+ Phase 5（校正サブエージェント委譲）に分割 |
| `.cursor/skills/write-blog-entry/SKILL.md` | `.claude/skills/` の変更を同期 |

## サブエージェント設計

### frontmatter

```yaml
name: textlint-fixer
description: "textlint の校正エラーを検出・修正する。記事ファイルパスを受け取り、エラーゼロになるまで lint→修正を繰り返す。write-blog-entry スキルの Phase 4 で自動的に使われる。"
tools: Read, Edit, Bash, Grep
model: sonnet
permissionMode: acceptEdits
maxTurns: 20
```

### 設計判断

| 項目 | 決定 | 理由 |
| --- | --- | --- |
| model | `sonnet` | 日本語の文脈理解が必要。校正修正は推論負荷が低いので opus は不要 |
| permissionMode | `acceptEdits` | 修正ループで毎回承認を求めると UX が劣化する |
| maxTurns | 20 | 3回の lint→修正サイクル（各5〜6ターン）を想定 |
| tools | Read, Edit, Bash, Grep | Write は不要（既存ファイルの部分修正のみ）。Glob も不要（対象はプロンプトで渡す） |
| memory | なし | 校正はステートレス。ルールは `.textlintrc` と `AGENTS.md` に集約済み |

### 出力フォーマット

```markdown
## Textlint Report

### 結果

- ステータス: PASS / FAIL
- 検出エラー数: N
- 修正エラー数: M
- 実行サイクル数: K

### 修正内容

| # | ルール | 行 | 修正前 | 修正後 |
| --- | --- | --- | --- | --- |
| 1 | sentence-length | 42 | <元の文> | <修正後の文> |

### 未解決エラー

(あれば記載。FAIL 時のみ。なければ「なし」)
```

### オーケストレーションフロー

```text
1. 親エージェント: Phase 1〜3 を対話的に実行
2. 親エージェント: Phase 4 で記事を執筆（ファイルに書き込み）
3. 親エージェント → textlint-fixer: Phase 5 でファイルパスを渡して校正依頼
4. textlint-fixer: lint→修正→再lint（最大3サイクル、親のコンテキスト外）
5. textlint-fixer → 親エージェント: Textlint Report を返却
6. 親エージェント → ユーザー: Report を表示して完了報告
```

## Risks and mitigations

| Risk | Mitigation |
| ---- | ---------- |
| sonnet が textlint エラーメッセージを誤解して意図しない修正をする | 出力フォーマットに修正前/修正後を含め、親エージェントがユーザーに差分を提示する |
| maxTurns 20 で足りない（大量エラーの記事） | 超過時は途中経過を返す指示を system prompt に含める |
| acceptEdits で意図しない箇所を壊す | Write を外し Edit のみに限定。Front Matter 保護ルールを system prompt に明記 |
| 校正修正が執筆のトーンを変えてしまう | system prompt に「修正は textlint エラーの解消に限定し、文体・トーンは変えない」ルールを明記 |

## Validation

- [ ] `.claude/agents/textlint-fixer.md` が Claude Code の `/agents` で認識される
- [ ] `draft_entries/` の既存記事で textlint-fixer が lint→修正→レポート返却できる
- [ ] 修正後の記事で `npx textlint` がエラーゼロになる
- [ ] Front Matter の自動生成フィールドが変更されていない
- [ ] SKILL.md の Phase 5 記述で Agent tool が正しく textlint-fixer を起動できる

## Decisions

- **スコープ**: `.claude/agents/`（プロジェクトスコープ）に配置する
- **Cursor 版**: 今回はスコープ外。`.cursor/skills/` の SKILL.md は同期するが Cursor 固有対応は行わない
- **Phase 分割**: Phase 4（執筆）+ Phase 5（校正）に分ける
- **出力フォーマット**: Textlint Report として構造化する
