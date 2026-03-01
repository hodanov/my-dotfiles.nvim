# Plan

code-review-scanner と code-review-critic による2フェーズレビューパイプラインを `/review-scan` スキルとして新規追加する。既存の `/review`（4並列専門レビュー）はそのまま残し、用途で使い分ける構成にする。

## Scope

- In:
  - `/review-scan` スキルの新規作成（SKILL.md）
  - scanner → critic の2フェーズワークフロー定義
  - 既存 `/review` の description に使い分けガイドを追記
- Out:
  - 既存 `/review` のワークフロー変更
  - サブエージェント定義の変更
  - テストやCI設定

## Design

### 使い分け基準

| スキル | 用途 | 特徴 |
| --- | --- | --- |
| `/review` | 日常の軽いチェック、特定観点の網羅的カバー | 4並列・速い・広く浅く |
| `/review-scan` | 大きなPR、複雑な変更の丁寧なレビュー | 逐次・深い・トリアージ+深掘り |

### `/review-scan` ワークフロー

1. diff取得（引数に応じてPR番号/ブランチ名/staged）
2. Phase 1: `code-review-scanner` で Scan Report 生成
3. Scan Report をユーザーに提示
4. Phase 2: Critical/Warning があれば `code-review-critic` で深掘り（ユーザー判断）

### ディレクトリ構成

```text
skills/review-scan/
└── SKILL.md
```

## Action items

- [ ] `skills/review-scan/SKILL.md` を新規作成
- [ ] 既存 `skills/review/SKILL.md` の description に使い分けガイドを追記
- [ ] markdownlint 実行

## Open questions

- なし
