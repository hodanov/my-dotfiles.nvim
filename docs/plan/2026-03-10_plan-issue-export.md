# Plan: plan-issue-export skill

`plan-markdown-export` と同じ入力解釈・正規化ロジックを持ちつつ、出力先を `docs/plan/` ではなく GitHub Issue にする新スキルを作成する。リポジトリ・Status・Estimate・Sprint などの繰り返し入力を省くために YAML config ファイルを設計し、スキル実行時にデフォルト値として参照する仕組みにする。正規化ルールは `plan-markdown-export` 側に `normalize-rules.md` として切り出し、両スキルから共有する。

## Background

- AI との壁打ちで練ったプランを、同じセッション内で GitHub Issue に書き出したい
- 現状は `plan-markdown-export` でファイルに保存した後、手動で Issue を作っている
- `plan-markdown-export` と入力解釈・正規化ロジックは共通で、出力先だけが異なる
- リポジトリ名・Sprint・Status・Estimate は毎回入力するのが手間なので、config で省略可能にしたい

## Current structure

- `skills/plan-markdown-export/SKILL.md` がプランの入力解釈・正規化・Markdown 整形・ファイル保存を一貫して担っている
- `skills/plan-markdown-export/template.md` が出力フォーマットを定義している
- 正規化ルールは `plan-markdown-export/SKILL.md` にインラインで記述されている
- Issue 作成に特化したスキルは存在しない

## Design policy

- 正規化ルールを `plan-markdown-export/normalize-rules.md` に切り出し、`plan-issue-export` から相対パスで参照する（案B）
- `plan-markdown-export` が正規化の本家という位置づけを維持する
- config ファイル（`config.yaml`）でリポジトリ・Sprint・Status・Estimate のデフォルト値を定義し、引数で上書き可能にする
- `config.yaml` は `.gitignore` に追加し、`config.example.yaml` を雛形として git 管理する
- GitHub Projects フィールドの設定は `gh` CLI の範囲に限定し、GraphQL API 直叩きは含めない
- 想定フローは「先に `plan-markdown-export` → 続けて `plan-issue-export`」だが、`plan-issue-export` 単体でも動作する

## Implementation steps

1. `plan-markdown-export/SKILL.md` の正規化ルールセクションを `plan-markdown-export/normalize-rules.md` に切り出し、SKILL.md からは参照リンクに置き換える
2. `skills/plan-issue-export/` ディレクトリを作成する
3. `skills/plan-issue-export/SKILL.md` を作成する — 入力の扱い・正規化ルール参照・Issue 作成手順・config 読み込み仕様を定義する
4. `skills/plan-issue-export/template.md` を作成する — `plan-markdown-export/template.md` をベースに Issue body 向けに調整する
5. `skills/plan-issue-export/config.example.yaml` を作成する — `repository`, `project`, `sprint`, `status`, `estimate` フィールドの雛形を用意する
6. `.gitignore` に `skills/plan-issue-export/config.yaml` を追加する
7. markdownlint を実行する

## File changes

| File                                             | Change                                                               |
| ------------------------------------------------ | -------------------------------------------------------------------- |
| `skills/plan-markdown-export/normalize-rules.md` | 正規化ルールを SKILL.md から切り出して新規作成する                   |
| `skills/plan-markdown-export/SKILL.md`           | インラインの正規化ルールを `normalize-rules.md` への参照に置き換える |
| `skills/plan-issue-export/SKILL.md`              | Issue 作成スキルを新規作成する                                       |
| `skills/plan-issue-export/template.md`           | Issue body 向けテンプレートを新規作成する                            |
| `skills/plan-issue-export/config.example.yaml`   | config の雛形を新規作成する                                          |
| `.gitignore`                                     | `skills/plan-issue-export/config.yaml` を追加する                    |

## Risks and mitigations

| Risk                                                                           | Mitigation                                                                                               |
| ------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| `gh` CLI が未認証またはスコープ不足で Issue 作成に失敗する                     | SKILL.md に事前確認手順と `gh auth status` の実行を記述する                                              |
| Sprint の "current" 自動判定が `gh project` のデータ構造に依存して不安定になる | config に `sprint: current` と書いた場合の取得手順を明示し、取得できない場合はスキップする               |
| config.yaml が存在しない場合にスキルが動作しない                               | config.yaml 不在時は全項目を引数またはユーザー確認で入力するフォールバックを定義する                     |
| 正規化ルールの切り出しで `plan-markdown-export` の動作が変わる                 | 切り出し後に既存の動作が維持されることを確認する                                                         |
| Issue body が長すぎて GitHub の文字数制限に引っかかる                          | 極端に長い場合は要約版を body に入れ、詳細は別途コメントまたはファイルリンクにする旨を注意事項に記述する |

## Validation

- [ ] `plan-markdown-export` が `normalize-rules.md` 切り出し後も既存通り動作する
- [ ] `plan-issue-export` がセッション内のプランを拾って Issue を作成できる
- [ ] `plan-issue-export` がファイルパス指定でプラン内容を読み取り Issue を作成できる
- [ ] `config.yaml` が存在する場合にデフォルト値が適用される
- [ ] `config.yaml` が存在しない場合にフォールバックでユーザー確認が走る
- [ ] 作成した Issue の Title が h1 見出しから取得されている
- [ ] Status・Estimate・Sprint が config 指定時に `gh project item-edit` で設定される

## Open questions

- なし
