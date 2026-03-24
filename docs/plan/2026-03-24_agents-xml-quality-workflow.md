# Plan: agents.xml にテスト・リンター検証ワークフローを追加

agents.xml にワークフロー定義を追加し、新規開発・既存改修の両方でテスト実装とリンター検証を必須化する。Claude Code のベストプラクティス「自分の作業を検証する手段を与える」に基づき、手戻りの削減と品質向上を図る。

## Background

- 現状の agents.xml はエージェントプロフィール（名前・役割・トーン）のみ定義
- テストやリンターの実行に関する指示がなく、検証なしでコミットに進むケースがある
- Claude Code ベストプラクティスで「検証手段の提供」が最も効果の高い施策として推奨されている
- 参照: <https://code.claude.com/docs/en/best-practices#give-claude-a-way-to-verify-its-work>

## Current structure

- `ai-agents/agents.xml`: エージェントプロフィール定義のみ（14行）
- `~/.claude/CLAUDE.md`: agents.xml を `@` で参照

## Design policy

- 既存の `agent_profile` はそのまま維持する
- `workflow` セクションを新設し、新規開発と既存改修のワークフローを分離する
- 検証ルールを `verification_rules` として横断的に定義する
- 各プロジェクト固有のコマンド（lint, test）は CLAUDE.md 側に記載し、agents.xml は汎用的に保つ
- 既存改修では test-first（失敗するテストを先に書く）アプローチを採用する

## Implementation steps

1. agents.xml に `<workflow>` セクションを追加
2. `<new_product>` ブロックに explore → plan → implement → verify → commit の 5 ステップを定義
3. `<existing_product>` ブロックに explore → plan → test_first → implement → verify → commit の 6 ステップを定義
4. `<verification_rules>` ブロックに横断的な検証ルールを定義
5. markdownlint で本プランファイルを検証

## File changes

| File                   | Change                                                                                       |
| ---------------------- | -------------------------------------------------------------------------------------------- |
| `ai-agents/agents.xml` | `<workflow>`, `<new_product>`, `<existing_product>`, `<verification_rules>` セクションを追加 |

## Risks and mitigations

| Risk                                                   | Mitigation                                                                   |
| ------------------------------------------------------ | ---------------------------------------------------------------------------- |
| agents.xml が長くなり、指示が埋もれる                  | `verification_rules` を簡潔に保ち、プロジェクト固有の設定は CLAUDE.md に分離 |
| テスト/リンターコマンドが不明なプロジェクトで実行失敗  | verification_rules に「設定ファイルを先に確認する」ルールを含める            |
| 既存改修で test-first が適用しにくいケース（UI変更等） | test_first ステップの説明に「再現テストが書ける場合」の前提を明記            |

## Validation

- [x] agents.xml が well-formed な XML であること
- [x] 既存の `agent_profile` が変更されていないこと
- [x] `<workflow>` 内に `<new_product>` と `<existing_product>` の両ワークフローが存在すること
- [x] `<verification_rules>` にテスト・リンター・型チェックのルールが含まれること
- [x] agents.xml を参照している CLAUDE.md が正常に読み込めること

## Open questions

- テスト/リンター実行後にサマリーを出力するフォーマットを統一するか（現時点では未定）
- CI 連携（hooks でリンターを強制実行するなど）は別途検討するか
