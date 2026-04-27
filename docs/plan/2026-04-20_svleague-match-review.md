# Plan: svleague-match-review Skill

SV リーグ公式サイトの試合詳細ページから REPORT-A / REPORT-B / LiveScore を取得し、「よかった点」「改善点」「選手にとって必要な情報」を 3 つの視点で分析する Markdown レビューを生成する Agent Skill を新設する。

## Background

- SV リーグ（日本バレーボールリーグ）の試合結果は `https://www.svleague.jp/ja/match/detail/<id>` で公開されている
- 試合ごとに以下 3 系統のデータが用意されている
  - REPORT-A: 試合メタデータ、スタメン、交代記録、コーチコメント
  - REPORT-B: 個人成績（アタック、ブロック、サーブ、サーブレシーブ等）
  - LiveScore: 試合経過と個人成績の時系列
- 観戦後に毎回自力で良し悪しを整理するのが手間で、一定のテンプレで振り返りを残したい
- 選手視点での「次に活かす情報」を引き出せる粒度にしたい

## Current structure

- 既存 Skill 置き場: `ai-agents/skills/<skill-name>/`（`SKILL.md` 必須）
- 反映導線: `make claude-skills-copy` で `~/.claude/skills/` へコピー
- 類似 Skill: `trip-log-from-calendar`, `blog-idea-draft-export`, `plan-markdown-export`
  - Markdown 出力の流儀（日付プリフィックス付きファイル名、kebab-case スラッグ、テンプレ配置）は既存に揃える
- Web 取得手段: WebFetch ツール（本セッションで挙動確認済み）

## Design policy

- Skill 名は `svleague-match-review` 固定。配置は `ai-agents/skills/svleague-match-review/`
- 入力は試合 ID（例: `33741`）または試合詳細ページ URL。任意で視点指定（team / versus / player）と注目選手
- デフォルトでは **3 視点すべて** を生成する（team / versus / player を全部）
- データソースは以下の URL パターンに沿って WebFetch で取得
  - 試合詳細: `https://www.svleague.jp/ja/match/detail/<id>`
  - REPORT-A: `https://www.svleague.jp/ja/<category>/form/a/<id>`
  - REPORT-B: `https://www.svleague.jp/ja/<category>/form/b/<id>`
  - LiveScore: `https://www.svleague.jp/ja/<category>/livescore/v/<id>`（「ローテーション / 試合経過 / 個人成績」の 3 タブ構成）
  - `<category>` は `sv_women` / `sv_men` など。試合詳細ページから自動判定する
  - 判定に失敗した場合はユーザーに確認（毎回問い合わせるスタイル）
- 出力は Markdown。保存先 `docs/svleague-match-review/YYYY-MM-DD_<slug>.md`（`<slug>` 例: `saga-vs-pfu`）
- 一次データ（生スタッツ表・取得元 URL）は末尾付録に残し、本文は分析重視
- 取得失敗や速報版注釈（REPORT-B 冒頭の「本帳票は速報版です」等）は Markdown 内で明示
- ユーザー承認ステップを必須化（抽出結果と保存パスを提示 → OK なら書き出し）

## 3 つの分析視点

| 視点               | キー     | 目的                                                                   |
| ------------------ | -------- | ---------------------------------------------------------------------- |
| 応援チーム視点     | `team`   | 応援チームのパフォーマンスを、勝敗に関わらずチーム単体で振り返る       |
| 両チーム対比視点   | `versus` | REPORT-B を左右に並べ、勝敗を分けた項目（効果率差/失点差など）を抽出   |
| 特定選手ズーム視点 | `player` | 指定選手のスタッツ・出場セット・推移を詳細化し、個人の課題と強みを整理 |

## 「選手にとって必要な情報」の扱い

独立セクションにはせず、各視点（team / versus / player）の「よかった点」「改善点」に畳み込む。各視点で以下の観点を織り交ぜて記述する。

- スタッツの相対感: チーム内平均比、セット別ムラ、出場セットあたりの貢献
- 弱点の具体化: 低決定率の局面、失点が集中したセット、レセプション崩れの傾向
- 強みの言語化: 効果率が高かった局面、流れを呼んだサーブ/ブロック
- 相手チームの特徴メモ: 次戦・類似対戦への持ち越し課題
- 次に向けた問い: 「このスタッツをどう動かす？」の具体的アクション候補（断定しすぎない）

## 出力テンプレ（ドラフト）

```markdown
# <YYYY-MM-DD> <HomeTeam> vs <AwayTeam> レビュー

- **試合 ID**: <id>
- **最終スコア**: <HomeTeam> <sets>-<sets> <AwayTeam>
- **セット別**: <s1>, <s2>, <s3>, ...
- **会場 / 大会**: <venue> / <tournament>
- **データ鮮度**: REPORT-B 速報版 / 確定版、LiveScore 取得可否

## 試合経過サマリー

- <1-3 行でセット毎の流れ>

## 視点 1: 応援チーム視点 (team)

### よかった点

### 改善点

### 選手に活かす情報

## 視点 2: 両チーム対比視点 (versus)

### よかった点

### 改善点

### 選手に活かす情報

## 視点 3: 特定選手ズーム視点 (player: <name>)

### よかった点

### 改善点

### 選手に活かす情報

## 付録: 生スタッツ

- REPORT-A 要点
- REPORT-B: アタック / ブロック / サーブ / サーブレシーブ表
- 取得元 URL 一覧
```

## Implementation steps

1. `ai-agents/skills/svleague-match-review/` を作成
   1. `SKILL.md`（目的 / 入力 / URL パターン / 処理 / 承認 / 出力）を記述
   2. `templates/match-review.md` を配置（上記テンプレを ASCII ベースで）
   3. `examples/33741-saga-vs-pfu.md` をドライラン結果で作成（可能な範囲で）
2. URL 解決ロジックを SKILL.md に明文化
   1. カテゴリ判定: 試合詳細 HTML からリンク中の `sv_women` / `sv_men` を抽出
   2. PDF リンク併設時は HTML を優先、失敗時に PDF を fallback
3. データ取得の手順化
   1. `match/detail/<id>` 取得 → 対戦カード/スコア/カテゴリ
   2. `form/a/<id>` 取得 → スタメン・交代・コメント
   3. `form/b/<id>` 取得 → 個人スタッツ
   4. `<category>/livescore/v/<id>` 取得 → ローテーション・試合経過・個人成績（JS 依存で取得不可の場合は欠損として記録）
4. 分析パスの組み立て
   1. デフォルトは 3 視点全出力
   2. `player` 視点時は `--player <name>` 相当の引数で注目選手を指定
5. ユーザー承認ステップ
   1. 抽出データ要約 + 書き出し予定パスを提示
   2. OK → `docs/svleague-match-review/YYYY-MM-DD_<slug>.md` へ保存
6. `make claude-skills-copy` で `~/.claude/skills/` に反映
7. `33741`（SAGA久光 vs PFU, 2026-04-18）でドライラン

## File changes

| File                                                                   | Change                       |
| ---------------------------------------------------------------------- | ---------------------------- |
| `ai-agents/skills/svleague-match-review/SKILL.md`                      | 新規作成                     |
| `ai-agents/skills/svleague-match-review/templates/match-review.md`     | 新規作成                     |
| `ai-agents/skills/svleague-match-review/examples/33741-saga-vs-pfu.md` | 新規作成                     |
| `docs/svleague-match-review/`                                          | 初回実行時に必要なら自動生成 |

## Risks and mitigations

| Risk                                           | Mitigation                                                                                       |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| LiveScore が JS レンダリング依存で取得できない | 欠損として Markdown に明記し、REPORT-A/B のみで分析継続。JS 実行を要する代替手段は今回スコープ外 |
| カテゴリ（`sv_women` / `sv_men`）を誤判定      | 試合詳細 HTML から抽出。失敗時はユーザーに確認                                                   |
| REPORT-B が速報版でデータが後日変わる          | 本文冒頭に「REPORT-B: 速報版 (取得日時)」を明記し、最終版差し替え手順を SKILL.md に記述          |
| PDF リンクを辿ると WebFetch で中身が読めない   | HTML レンダリング側を優先し、PDF は参考 URL として出力に貼るだけに留める                         |
| 同姓同名 / 漢字表記揺れで選手ズームが誤マッチ  | 背番号 + 氏名で一意化。曖昧な場合はユーザーに候補提示                                            |
| 1 試合データから強すぎる結論を出す             | 表現は「〜の傾向が見られた」等に留め、断定を避けるガイドを SKILL.md に明記                       |
| 無関係な URL（他リーグ、古い試合）を渡される   | 取得 HTML の対戦カード/日付を検証し、想定外なら中断してユーザーに確認                            |
| ネットワーク失敗                               | 取得失敗は Skill 内でリトライしすぎず、失敗時はエラーサマリをユーザーに返す                      |

## Validation

- [ ] `svleague-match-review 33741` で SAGA久光 vs PFU のレビューが生成される
- [ ] 3 視点（team / versus / player）すべてが本文に含まれる
- [ ] セット別スコア・最終スコアが本文ヘッダーに正しく入る
- [ ] REPORT-B の個人成績（アタック決定率、ブロック、サーブ効果率、サーブレシーブ成功率）が付録表に反映される
- [ ] LiveScore が JS レンダリング等で取得できないケースで欠損注記付きで出力が完了する
- [ ] 出力ファイル名が `docs/svleague-match-review/YYYY-MM-DD_<slug>.md` になる
- [ ] 書き出し前にユーザー承認ステップが機能する
- [ ] 速報版 / 最終版の注釈が本文に残る

## Decisions

- カテゴリ判定に失敗した場合は、毎回ユーザーに確認するスタイルで進める（`--category` 引数は用意しない）
- LiveScore が JS レンダリング依存で取得できない場合の JS 実行系代替手段は **スコープ外**
- リーグ平均値との比較は **スコープ外**
- 「選手にとって必要な情報」は独立セクションにせず、各視点の「選手に活かす情報」として畳み込む
- `examples/33741-saga-vs-pfu.md` は Skill リポジトリ（`ai-agents/skills/svleague-match-review/examples/`）に置く
