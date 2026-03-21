# Amendment Proposal Template

amendment 記録ファイル（`observations/amendments/YYYY-MM-DD_NNN_amendment.md`）のテンプレート。

---

```markdown
---
skill: <スキル名>
date: YYYY-MM-DD
version_before: <変更前バージョン>
version_after: <変更後バージョン>
---

# Amendment: <スキル名> — YYYY-MM-DD_NNN

## 分析サマリ

- **対象期間**: YYYY-MM-DD 〜 YYYY-MM-DD
- **observation 件数**: N 件
- **failure 率**: X% (N/M)
- **partial 率**: X% (N/M)

## 検出パターン

### 再発パターン

- パターン1: ...（出現回数: N）
- パターン2: ...（出現回数: N）

### コンテキスト依存

- 条件1: ...（失敗率: X%）

### フィードバック傾向

- キーワード1: ...（出現回数: N）

## 変更内容

### 変更箇所

（SKILL.md の変更を diff 形式で記載）

- 変更前の行
+ 変更後の行

### 変更理由

（どの observations がエビデンスか、具体的に参照）

- obs1: YYYY-MM-DD_obs.md — ...
- obs2: YYYY-MM-DD_obs.md — ...

### 期待される効果

- ...

### リスク

- ...

## 前回 amendment の効果（該当する場合）

- **前回適用日**: YYYY-MM-DD
- **適用前 failure 率**: X%
- **適用後 failure 率**: X%
- **評価**: 改善 / 変化なし / 悪化
- **備考**: ...
```
