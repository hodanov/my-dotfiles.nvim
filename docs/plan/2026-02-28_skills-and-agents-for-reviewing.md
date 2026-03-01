# /review スキル + 並列レビューサブエージェント 実装計画

Context

コードレビューの効率化のため、/review スキルと4つの専門レビューサブエージェントを追加する。Claude Code ドキュメントの「Skill + Subagent パターン」に従い、/review
がオーケストレーターとして4つのサブエージェントを並列起動し、統合レポートを出力する。既存の code-review-scanner / code-review-critic パイプラインはそのまま残し、Critical/High 指摘があれば code-review-critic
  への Phase.2 ハンドオフを推奨する。

 アーキテクチャ

 /review [PR番号 | ブランチ名 | staged]
     │
     ▼
 ┌──────────────────────────────┐
 │  /review スキル（SKILL.md）   │  メインコンテキストで起動
 │  diff取得 → 4エージェント並列  │
 └──────┬───────────────────────┘
        │ Agent tool × 4（同一レスポンスで並列）
        ├──────────────┬──────────────┬──────────────┐
        ▼              ▼              ▼              ▼
  review-security  review-      review-       review-
                   performance  correctness   changeability
        │              │              │              │
        └──────────────┴──────────────┴──────────────┘
                               │
                     統合 Review Report
                               │
                     (Critical/High あれば)
                               ▼
                     code-review-critic で Phase.2 推奨

 作成ファイル一覧（5ファイル）

 ┌─────┬────────────────────────────────┬───────┬───────────────────────────────┐
 │  #  │              パス              │ 種別  │             概要              │
 ├─────┼────────────────────────────────┼───────┼───────────────────────────────┤
 │ 1   │ agents/review-security.md      │ Agent │ セキュリティ専門レビュアー    │
 ├─────┼────────────────────────────────┼───────┼───────────────────────────────┤
 │ 2   │ agents/review-performance.md   │ Agent │ パフォーマンス専門レビュアー  │
 ├─────┼────────────────────────────────┼───────┼───────────────────────────────┤
 │ 3   │ agents/review-correctness.md   │ Agent │ 正確性専門レビュアー          │
 ├─────┼────────────────────────────────┼───────┼───────────────────────────────┤
 │ 4   │ agents/review-changeability.md │ Agent │ 変更容易性専門レビュアー      │
 ├─────┼────────────────────────────────┼───────┼───────────────────────────────┤
 │ 5   │ skills/review/SKILL.md         │ Skill │ オーケストレーター（/review） │
 └─────┴────────────────────────────────┴───────┴───────────────────────────────┘

 Makefile の変更は不要（auto-discovery で自動認識される）。

 各ファイルの設計

 1-4. サブエージェント共通設計

 全4エージェントで共通のフロントマター:

 ---

name: review-<dimension>
 description: "<観点>に特化したレビューサブエージェント。..."
 tools: Read, Grep, Glob
 model: sonnet
 permissionMode: plan
 maxTurns: 15
 color: magenta
 ---

- model: sonnet — コスト効率。Phase.2 が必要なら opus の code-review-critic に渡す
- tools — Read/Grep/Glob のみ（Bash なし、読み取り専用）
- permissionMode: plan — 読み取り専用を強制
- memory なし — ステートレスなワーカー
- color: magenta — yellow（code-review系）、cyan（investigation系）と区別

 本体の構成（全エージェント共通パターン）:

1. ロール紹介文

2. ## Your mission — diff を受け取り、観点に特化した分析を行う

3. ## Review scope — 観点ごとのチェック項目

4. ## Rules — 根拠必須、観点外はスキップ、file:line 引用、コンパクト出力

5. ## Output format — Findings Report テンプレート

 各エージェントの Review scope:

 ┌──────────────────────┬───────────────────────────────────────────────────────────────────────────────────────────────┐
 │     エージェント     │                                       主なチェック項目                                        │
 ├──────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
 │ review-security      │ OWASP Top 10、認証/認可、シークレット、インジェクション、信頼境界、パストラバーサル、暗号誤用 │
 ├──────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
 │ review-performance   │ N+1クエリ、計算量、メモリリーク、キャッシュ、データ構造、バッチ処理、インデックス             │
 ├──────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
 │ review-correctness   │ ロジックバグ、エッジケース、off-by-one、null安全性、型安全性、エラー処理、テストカバレッジ    │
 ├──────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
 │ review-changeability │ SOLID/DRY/KISS/YAGNI、可読性、凝集度/結合度、境界規律、運用性、不変条件保護                   │
 └──────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────┘

 Findings Report 出力フォーマット（全エージェント共通）:

## Findings Report: <Category>

### サマリ

 (1-2文の所見サマリ)

### 指摘リスト

#### [Critical] 概要

- **場所**: `path/to/file:line`
- **問題**: (内容)
- **根拠**: (根拠)

#### [Warning] 概要

- **場所**: `path/to/file:line`
- **問題**: (内容)
- **根拠**: (根拠)

#### [Info] 概要

- **場所**: `path/to/file:line`
- **問題**: (内容)

### 問題なし

- (チェックして問題がなかった領域)

 1. /review スキル設計

 フロントマター:

 ---

name: review
 description: コード変更をセキュリティ・パフォーマンス・正確性・変更容易性の4観点から並列レビューし、統合レポートを出力する。
 disable-model-invocation: true
 argument-hint: "[PR番号 | ブランチ名 | staged]"
 ---

 本体の手順:

 1. diff 取得 — 引数に応じた git diff / gh pr diff を実行
 2. 並列起動 — 4つのサブエージェントを Agent tool で同一レスポンス内に並列起動し、diff を渡す
 3. 結果収集 — 4つの Findings Report を待ち受け
 4. 統合 Review Report 生成 — 以下のフォーマットで出力
 5. Phase.2 推奨 — Critical/High があれば code-review-critic での深掘りを提案

 統合 Review Report フォーマット:

## Review Report

### 総評

 (全体評価 2-4文)

### セキュリティ

 (review-security 結果サマリ + 指摘)

### パフォーマンス

 (review-performance 結果サマリ + 指摘)

### 正確性

 (review-correctness 結果サマリ + 指摘)

### 変更容易性

 (review-changeability 結果サマリ + 指摘)

### Phase.2 推奨

 (Critical/High があれば code-review-critic を推奨。なければ Phase.2 不要と記載)

### 判定

- [ ] Approve
- [ ] Approve with comments
- [ ] Request changes

 実装順序

 1. agents/review-security.md を作成（パターン確立）
 2. agents/review-performance.md を作成
 3. agents/review-correctness.md を作成
 4. agents/review-changeability.md を作成
 5. skills/review/SKILL.md を作成
 6. 全5ファイルに markdownlint-cli2 --fix を実行

 参照ファイル

- agents/code-review-scanner.md — review categories、出力フォーマットの参考
- agents/code-review-critic.md — 深掘り分析フォーマット、Phase.2 ハンドオフ先
- agents/investigation-scout.md — 軽量エージェントの frontmatter パターン参考
- skills/agent-codex-convert/SKILL.md — disable-model-invocation: true パターン参考

 検証

- markdownlint-cli2 --fix が全ファイルでエラーなく通ること
- make claude-skills-copy で review/ が認識されること
- make claude-agents-copy で review-*.md
