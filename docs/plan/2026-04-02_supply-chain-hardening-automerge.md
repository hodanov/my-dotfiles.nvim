# Plan: supply-chain-hardening スキルへの自動マージ設定の統合

`supply-chain-hardening` スキルに Phase 4 として自動マージ設定を統合する。
Dependabot・Renovate が生成する PR を CI 通過後に自動マージする仕組みを、スキルのワークフローから設定できるようにする。
このリポジトリでは既に自動マージが実装済みであり、その知見をスキルの手順に落とし込む。

## Background

- `supply-chain-hardening` スキルは現在、GHA の SHA ピン留めと Dependabot / Renovate のクールダウン設定（14日間）までを扱っている
- 自動マージは「クールダウンで 14 日待つ → チェック通過後に自動マージ」というセットで機能するため、スキルとして統合するのが自然
- このリポジトリでは `auto-merge-deps.yml` と branch protection rule がすでに設定済み
- Renovate を使うリポジトリでも同等の自動マージが必要になるため、両対応が必要

## Current structure

- `ai-agents/skills/supply-chain-hardening/SKILL.md` — 対象スキル本体
  - Phase 0: pinact 確認
  - Phase 1: 現状分析
  - Phase 2: GHA SHA ピン留め
  - Phase 3: Dependabot / Renovate クールダウン設定
  - Phase 4: 検証
- `$ARGUMENTS` で `all / gha / dependabot` のスコープ制御あり
- このリポジトリでの実装済み内容（参照実装）:
  - `.github/workflows/auto-merge-deps.yml` — Dependabot bot / 自作ワークフローのブランチを対象に `gh pr merge --auto --squash`
  - `.github/dependabot.yml` — 全エコシステムに `cooldown: default-days: 14` 設定済み
  - `main` branch protection rule — required checks 通過後に auto-merge が発動

## Design policy

- **スコープ引数に `automerge` を追加する**: `$ARGUMENTS` を `all / gha / dependabot / automerge` に拡張し、`all` 時は自動マージ設定も含む
- **フェーズ番号を繰り上げて Phase 4 として追加**: 既存の Phase 4（検証）を Phase 5 に移動し、自動マージ設定を Phase 4 として挿入する
- **Dependabot と Renovate で手順を分岐**: ツールごとに設定ファイルと方法が異なるため、既存の Phase 3 と同様に分岐して記述する
- **前提条件を明示する**: auto-merge は GitHub の branch protection rule + "Allow auto-merge" 設定が必要なため、Phase 4 の冒頭に前提チェックを設ける
- **ワークフローテンプレートをスキル内に持つ**: `auto-merge-deps.yml` のテンプレートをスキルに埋め込み、ユーザーがそのまま使えるようにする
- **Renovate の自動マージ設定も対象とする**: `automerge: true` + `automergeType: "pr"` を `packageRules` に追加する手順を含める

## Implementation steps

1. **`SKILL.md` のスコープ引数定義を更新する**
   - `argument-hint` を `"[対象スコープ: all / gha / dependabot / automerge]"` に変更
   - ワークフロー全体像に `Phase 4: 自動マージ設定` を追加し、既存の Phase 4 を Phase 5 に繰り上げる

2. **Phase 4: 自動マージ設定 を追加する**

   以下の構成で記述する:

   ### 4-0. 前提条件チェック
   - GitHub リポジトリ設定で "Allow auto-merge" が有効か確認する
     - Settings > General > Pull Requests > "Allow auto-merge"
   - `main` に branch protection rule があり、required status checks が設定されているか確認する

   ### 4-1. Dependabot の場合

   `.github/workflows/auto-merge-deps.yml` を新規作成する（既存の場合はスキップ）:

   ```yaml
   name: Auto-merge dependency PRs

   on:
     pull_request:
       types: [opened, synchronize, reopened]

   permissions:
     contents: write
     pull-requests: write

   jobs:
     auto-merge:
       if: |
         github.actor == 'dependabot[bot]' ||
         startsWith(github.head_ref, 'renovate/')
       runs-on: ubuntu-latest
       steps:
         - name: Enable auto-merge
           env:
             GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
           run: gh pr merge "${{ github.event.pull_request.number }}" --auto --squash --repo "${{ github.repository }}"
   ```

   - リポジトリ固有の自作ワークフローブランチ（例: `chore/bump-tool-versions`）がある場合は `if:` 条件に追加するよう案内する

   ### 4-2. Renovate の場合

   `renovate.json` の `packageRules` に以下を追加する:

   ```json
   {
     "matchManagers": ["github-actions"],
     "automerge": true,
     "automergeType": "pr"
   }
   ```

   - Renovate の自動マージは GitHub native auto-merge を利用できる
   - `automergeStrategy` を `"squash"` にすることも推奨する
   - 全エコシステムに適用する場合は `matchManagers` を省略する

   ### 4-3. どちらも未導入の場合

   Dependabot 導入を提案し、4-1 のワークフローテンプレートを提示する。

3. **Phase 5 として既存の Phase 4（検証）を移動する**
   - 内容はそのままで番号だけ変更する
   - 4-3（自動マージの検証項目）を Phase 5 の検証リストに追加する:
     - 依存 PR に auto-merge が有効化される
     - CI チェック失敗時はマージされない
     - 人間の PR は対象にならない

4. **スコープ制御の説明を更新する**
   - `all` の説明に Phase 4 も含まれることを追記する

## File changes

| File                                               | Change                                                                   |
| -------------------------------------------------- | ------------------------------------------------------------------------ |
| `ai-agents/skills/supply-chain-hardening/SKILL.md` | Phase 4 追加、Phase 5 に繰り上げ、`argument-hint` 更新、スコープ説明更新 |

## Risks and mitigations

| Risk                                                                     | Mitigation                                                                                                                                 |
| ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| branch protection rule 未設定で auto-merge が即発動してしまう            | Phase 4-0 の前提チェックを必須フェーズとして記述し、未設定の場合はユーザーに設定を促してから進む                                           |
| Dependabot PR で `pull_request` イベントの `GITHUB_TOKEN` 権限が不足する | `permissions: contents: write, pull-requests: write` をワークフローに明示。実際に動作しない場合は `pull_request_target` への変更を案内する |
| リポジトリ固有のブランチパターン（自作ワークフロー）を網羅できない       | `if:` 条件にリポジトリ固有ブランチを追加する旨をコメントで案内する                                                                         |
| Renovate の自動マージ設定がスキーマバージョンによって異なる              | Renovate の公式スキーマ（`$schema`）のバージョンを確認し、`automerge` フィールドのサポート状況を確認するよう案内する                       |

## Validation

- [ ] `SKILL.md` の `argument-hint` が `all / gha / dependabot / automerge` に更新されている
- [ ] ワークフロー全体像に Phase 4 が追加され、検証が Phase 5 に移動している
- [ ] Phase 4-0 の前提チェック手順が記述されている
- [ ] Phase 4-1 に Dependabot 向け `auto-merge-deps.yml` テンプレートが含まれている
- [ ] Phase 4-2 に Renovate 向け `automerge` 設定例が含まれている
- [ ] Phase 5 の検証リストに自動マージの確認項目が追加されている
- [ ] `$ARGUMENTS: automerge` でスコープを絞った実行が機能するよう記述されている

## Open questions (resolved)

- **`pull_request` vs `pull_request_target`**: `pull_request` で固定する。権限問題が発生した場合は `pull_request_target` への切り替えをユーザーに注意喚起するにとどめる（スキル内で詳細なセキュリティ考慮は記述しない）。
- **Renovate の branch name パターン**: デフォルトの `renovate/` のみ考慮する。カスタマイズされているリポジトリには、ブランチ名パターンの調整が必要な旨をユーザーに案内する。
