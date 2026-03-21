# Plan: Self-Improving Skills システムの導入

スキル（SKILL.md）の品質を継続的に改善するため、Observe → Inspect → Amend → Evaluate ループを Markdown ファイルベースで実現する。Claude Code の制約（カスタムランタイムなし、DB なし）の中で、既存のスキル/エージェント基盤と git 履歴のみで運用する。

## Background

- スキルは現在「静的なプロンプトファイル」として運用されているが、コードベースやモデルの挙動、ユーザーの要求は変化し続ける
- 記事 "Self improving skills for agents" の改善ループを、Claude Code の制約内で実現したい
- cognee のようなグラフ DB やカスタムランタイムは使わず、全て Markdown + git で完結させる

## Design policy

- **Markdown + git 完結**: DB や構造化ストレージは使わない。Markdown で十分
- **手動 Observe**: PostSkillExecution フックが Claude Code にないため、ユーザーが `/skill-observe` を手動で呼ぶ。手動の方がユーザー判断を含むメリットもある
- **Amend は必ずユーザー承認**: SKILL.md の自動書き換えはしない。プロンプトの無制御な自動変更はリスクが高い
- **定性的パターン分析**: サンプルサイズが小さく統計的に無意味なため、数値スコアリングはしない
- **既存インフラ活用**: `copy-entries.sh` は `cp -R` で再帰コピーするため、`observations/` を追加しても変更不要

## Architecture

```text
ai-agents/skills/
├── skill-observe/           # observation 記録スキル
│   └── SKILL.md
├── skill-improve/           # 分析・改善提案スキル
│   ├── SKILL.md
│   └── template.md          # amendment proposal テンプレート
└── <既存スキル>/
    ├── SKILL.md             # version: フィールド追加（任意）
    └── observations/        # per-skill observation ログ
        ├── YYYY-MM-DD_obs.md
        └── amendments/
            └── YYYY-MM-DD_amendment.md
```

## Implementation steps

### Phase 1: Observation 基盤（今回のセッション）

1. `ai-agents/skills/skill-observe/SKILL.md` を作成
   - 引数パース（スキル名、結果、問題/フィードバック）
   - 6 フィールド構造化記録（タスク、スキル、結果、問題、フィードバック、コンテキスト）
   - `observations/YYYY-MM-DD_obs.md` への書き込み（同日は追記）
   - 引数なしバッチモード対応
2. `ai-agents/skills/review/observations/.gitkeep` を作成（PoC ディレクトリ）
3. `/skill-observe` の動作確認

### Phase 2: Improvement スキル（次回セッション）

1. `ai-agents/skills/skill-improve/SKILL.md` を作成
   - observations 読み込みとパターン分析（失敗頻度、再発パターン、コンテキスト依存、フィードバック傾向）
   - amendment proposal 生成（template.md フォーマット）
   - `--apply` フラグによるユーザー承認後の適用
   - 前回 amendment の効果評価（Evaluate フェーズ）
2. `ai-agents/skills/skill-improve/template.md` を作成
3. observations が 5-10 件溜まった後に `/skill-improve` をテスト

### Phase 3: 定着と自己改善（2-4 週間後）

1. `/skill-observe` と `/skill-improve` 自身に observations を蓄積
2. メタ改善（改善スキル自体を改善スキルで改善する）

## `/skill-observe` の仕様

使用後に以下の形式で呼び出す:

```text
/skill-observe <スキル名> <success|partial|failure> [問題やフィードバック]
```

記録する 6 フィールド:

| フィールド     | 内容                                           |
| -------------- | ---------------------------------------------- |
| タスク         | 何を試みたか                                   |
| スキル         | 使用したスキル名                               |
| 結果           | success / partial / failure                    |
| 問題           | 何が起きたか（なければ「なし」）               |
| フィードバック | ユーザーの所感（なければ「なし」）             |
| コンテキスト   | 関連する詳細（リポジトリ種別、規模、言語など） |

使用例:

```text
/skill-observe review success
/skill-observe commit-and-draft-pr failure PRテンプレートの補足セクションが不足
/skill-observe investigate partial scoutは良かったがdiverの深掘りが浅い
```

引数なしで呼ぶとバッチモード（セッション中の使用スキルを一括振り返り）。

## `/skill-improve` の仕様

```text
/skill-improve <スキル名|all> [--apply]
```

ワークフロー:

1. 対象スキルの `observations/*.md` を全て読み込み
2. 4 観点でパターン分析（失敗頻度、再発パターン、コンテキスト依存、フィードバック傾向）
3. 前回 amendment がある場合、適用前後の failure 率を比較し効果評価
4. SKILL.md の具体的な修正案を template.md フォーマットで生成
5. `--apply` フラグがあればユーザー確認のうえ適用。なければ提案のみ

## バージョニング

- **git 履歴が第一のバージョン管理**。amendment 適用は専用コミットで記録
- SKILL.md フロントマターに `version:` フィールドを任意で追加（整数、amendment 適用回数）
- `observations/amendments/YYYY-MM-DD_amendment.md` に修正記録を保存

## 評価（Evaluate）

- 完全な A/B テストは不可能。時間ベースの前後比較で代替
- amendment 適用前後の failure 率を比較
- amendment 後に新たな失敗パターンが出現した場合はロールバックを提案
- `/skill-improve` 実行時に「前回の amendment の効果はどうか」を自動チェック

## File changes

| File                                            | Change                                    |
| ----------------------------------------------- | ----------------------------------------- |
| `ai-agents/skills/skill-observe/SKILL.md`       | 新規作成。observation 記録スキル          |
| `ai-agents/skills/skill-improve/SKILL.md`       | 新規作成。分析・改善提案スキル            |
| `ai-agents/skills/skill-improve/template.md`    | 新規作成。amendment proposal テンプレート |
| `ai-agents/skills/review/observations/.gitkeep` | 新規作成。PoC ディレクトリ                |
| `ai-agents/scripts/copy-entries.sh`             | 変更なし（`cp -R` で再帰コピー対応済み）  |
| `ai-agents/Makefile`                            | 変更なし                                  |

## Risks and mitigations

| Risk                                      | Mitigation                                                     |
| ----------------------------------------- | -------------------------------------------------------------- |
| 手動 observe の忘れ・サボり               | 習慣化を促す。バッチモードで振り返りやすくする                 |
| observations のサンプル不足で分析が不正確 | 5 件未満の場合は信頼度が低い旨を注記                           |
| SKILL.md の自動書き換えによる品質劣化     | `--apply` は必ずユーザー承認を経る。自動書き換えはしない       |
| observations ファイルの肥大化             | 1 日 1 ファイルで追記。古い observations は git 履歴で参照可能 |
| amendment 後の regression                 | Evaluate フェーズで前後比較し、悪化時はロールバックを提案      |

## Excluded scope

| 除外項目                   | 理由                                                          |
| -------------------------- | ------------------------------------------------------------- |
| 自動 observation 記録      | PostSkillExecution フックがない。手動の方がユーザー判断を含む |
| DB / 構造化ストレージ      | Markdown で十分。ツール増加に見合わない                       |
| 数値スコアリング           | サンプルサイズが小さく統計的に無意味                          |
| Agent 定義への observation | スキル経由で呼ばれるため、スキル側で間接的にカバー            |
| SKILL.md の自動書き換え    | プロンプトの無制御な自動変更はリスクが高い                    |

## Validation

- [ ] `/skill-observe review success テスト` → `ai-agents/skills/review/observations/2026-03-17_obs.md` が正しく作成される
- [ ] `make claude-skills-copy` → `~/.claude/skills/review/observations/` にコピーされる
- [ ] `/skill-observe review partial 問題あり` を再度実行 → 同日ファイルに追記される
- [ ] Phase 2 以降: observations が溜まった状態で `/skill-improve review` → 改善提案が生成される

## Open questions

- observations の保持期間ポリシー（古いファイルの扱い）は未定。当面は全て保持し、必要に応じて検討
- `/skill-improve all` の横断分析でスキル間の相関をどこまで深掘りするかは、実運用を通じて調整
