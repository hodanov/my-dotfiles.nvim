# Plan

Incremental Drilling パターンを2つのカスタムSubagentで実現する。
Phase.1（広く浅く）と Phase.2（狭く深く）を独立したコンテキストで動かすことで、
調査ごとにメインコンテキストを汚染せず、再利用性の高い調査基盤を作る。

## Scope

- In:
  - `~/.claude/agents/` への Phase.1/Phase.2 subagent ファイル作成
  - 両 Agent の system prompt 設計（読み取り専用ツールに限定）
  - オーケストレーション手順のドキュメント化
- Out:
  - スキル（`.claude/skills/`）の作成
  - MCP サーバーの追加
  - Phase.1 → Phase.2 の自動連携（サブエージェントはサブエージェントを生成不可のため、
    メイン会話がオーケストレーターを担う）

## Subagent 設計

### Phase.1: `investigation-scout`

広く・浅く・速く調査し、候補リストを返す。

```yaml
name: investigation-scout
model: haiku          # 速度・コスト優先
tools: Read, Grep, Glob
permissionMode: plan  # 読み取り専用を強制
```

System prompt の責務:

- 仮説なしで全体構造を把握する
- 怪しいファイル・モジュールを列挙する（深読みしない）
- 出力を**構造化 Markdown**（候補リスト + 優先度）で返す

出力フォーマット（Agent が必ず従う）:

```markdown
## Scout Report

### 調査概要
<何を調べたか 1〜3 文>

### 候補リスト（優先度順）
| 優先度 | ファイル/モジュール | 根拠 |
|--------|---------------------|------|
| High   | src/foo/bar.ts      | ...  |

### 推奨 Phase.2 クエリ
- <具体的な深掘り観点 1>
- <具体的な深掘り観点 2>
```

### Phase.2: `investigation-diver`

Phase.1 の Scout Report を入力とし、候補を深く分析する。
**複数 Scout の Report をまとめて受け取ることも可能**（Layered Delegation 拡張時）。

```yaml
name: investigation-diver
model: sonnet         # 推論品質優先
tools: Read, Grep, Glob
permissionMode: plan  # 読み取り専用を強制
memory: project       # 調査ナレッジをプロジェクト単位で蓄積
```

System prompt の責務:

- Scout Report の候補リストと推奨クエリを起点にする
- 根拠コードを引用し、証拠ベースで結論を出す
- 反証（否定できる点）も必ず記述する

出力フォーマット（Agent が必ず従う）:

```markdown
## Diver Report

### 結論
<1〜3 文で核心を述べる>

### 根拠
- `ファイル:行番号` — <引用と説明>

### 反証・限界
- <この調査で確認できなかった点>

### 推奨アクション
- [ ] <次にやるべき具体的な作業>
```

## オーケストレーション手順

サブエージェントはサブエージェントを生成できないため、
メイン会話が以下の順序でオーケストレーターを担う。

### 基本パターン（Scout × 1）

```text
1. ユーザー → メイン会話: 調査依頼
2. メイン会話 → investigation-scout: Phase.1 実行
3. investigation-scout → メイン会話: Scout Report 返却
4. メイン会話 → investigation-diver: Phase.2 実行（Scout Report を渡す）
5. investigation-diver → メイン会話: Diver Report 返却
6. メイン会話 → ユーザー: 統合サマリー提示
```

呼び出しテンプレート:

```text
# Phase.1
Use the investigation-scout subagent to broadly investigate [調査対象].

# Phase.2（Scout Report をそのまま渡す）
Use the investigation-diver subagent. Here is the Scout Report from Phase.1:
[Scout Report の内容]
Deep dive into the High-priority candidates.
```

### Layered Delegation 拡張（Scout を並列起動）

調査対象が広い場合、ドメインを分割して Scout を並列起動し、
複数の Scout Report を Diver に一括で渡す。

```text
1. ユーザー → メイン会話: 広域調査依頼
2. メイン会話 → investigation-scout × N（並列）: ドメイン別 Phase.1
   例: Scout-A（認証モジュール）/ Scout-B（DB層）/ Scout-C（API層）
3. 各 scout → メイン会話: Scout Report × N 返却
4. メイン会話 → investigation-diver: 全 Scout Report を統合して Phase.2
5. investigation-diver → メイン会話: 統合 Diver Report 返却
```

呼び出しテンプレート:

```text
# Phase.1（並列）
Use three investigation-scout subagents in parallel:
- Scout A: investigate the authentication module in [path]
- Scout B: investigate the database layer in [path]
- Scout C: investigate the API layer in [path]

# Phase.2（全 Report を結合して渡す）
Use the investigation-diver subagent. Here are Scout Reports from Phase.1:

## Scout A Report（認証モジュール）
[Scout A の出力]

## Scout B Report（DB層）
[Scout B の出力]

## Scout C Report（API層）
[Scout C の出力]

Synthesize all reports and deep dive into cross-cutting High-priority candidates.
```

## Action items

- [ ] `~/.claude/agents/` ディレクトリを作成する
- [ ] `investigation-scout.md` を作成する（frontmatter + system prompt）
- [ ] `investigation-diver.md` を作成する（frontmatter + system prompt）
- [ ] `/agents` コマンドでロード確認する
- [ ] サンプル調査で動作検証する（TATSU リポジトリを対象に試す）

## 決定済み事項

| 項目 | 決定 |
| ---- | ---- |
| Scout Report のサイズ問題 | 今回は考慮しない（一時ファイル方式は将来の拡張） |
| Diver の memory | `memory: project` を付けてナレッジ蓄積する |
| 並列 Scout 拡張 | Layered Delegation パターンを実装に含める |
