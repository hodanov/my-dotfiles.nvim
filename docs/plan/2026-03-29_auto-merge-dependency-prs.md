# Plan: Auto-merge dependency PRs

CI が自動生成する依存パッケージ・ツール更新 PR を、全チェック通過後に自動マージする仕組みを導入する。
手動マージの手間を省きつつ、Docker ビルド等の既存ゲートで安全性を担保する。

## Background

- Dependabot が pip / npm / docker / gomod / github-actions の更新 PR を毎週作成している
- `bump-tool-versions.yml` が Node / Go / Neovim / Rust / npm のバージョンバンプ PR を毎週月曜に作成している
- `update-go-tools.yml` が Go ツールの更新 PR を毎週月曜に作成している
- これらの PR はすべて手動マージが必要で、溜まりやすい
- `pr-docker-build.yml` が依存更新 PR に対して Docker イメージビルドを実行しており、ビルド破壊の検知は既にできている

## Current structure

- `.github/dependabot.yml` - Dependabot 設定（5 エコシステム、グループ化済み）
- `.github/workflows/bump-tool-versions.yml` - ツールバージョンバンプ PR 作成（ブランチ: `chore/bump-tool-versions`、ラベル: `dependencies`）
- `.github/workflows/update-go-tools.yml` - Go ツール更新 PR 作成（ブランチ: `update/go-tools`、ラベル: `dependencies`）
- `.github/workflows/pr-docker-build.yml` - 依存 PR 向け Docker ビルド検証
- `.github/workflows/lint_format.yml` - 全 PR 向けフォーマットチェック
- その他 lint / test ワークフロー - パス条件付きで実行

## Design policy

- **GitHub native auto-merge を活用する**: `gh pr merge --auto --squash` で GitHub 側の auto-merge キューに入れる。全 required status checks が通過した時点で自動マージされる
- **ワークフローは 1 ファイルに集約する**: 各 PR 作成ワークフローに分散させず、`auto-merge-deps.yml` に一元化して管理しやすくする
- **対象を明確に限定する**: Dependabot bot と自作ワークフローのブランチパターンのみを対象にし、人間の PR は対象外
- **Branch protection rule が前提**: auto-merge は required status checks が設定された branch protection rule がないと機能しない。まだ設定していない場合は先に設定する
- **Docker ビルドを required check にする**: `pr-docker-build.yml` のパスフィルタを job レベルの `if:` に移し、全 PR でワークフローが起動するようにする。依存系以外の PR では job が skipped（= 通過扱い）になるため、通常 PR をブロックしない

## Implementation steps

1. **GitHub リポジトリ設定で auto-merge を有効化する**
   - Settings > General > Pull Requests > "Allow auto-merge" にチェック

2. **`pr-docker-build.yml` のトリガーを変更する**
   - `on.pull_request.paths` フィルタを削除し、全 PR でワークフローが起動するようにする
   - 代わりに既存の job レベル `if:` 条件で依存 PR のみ実行する（既に `if:` は設定済み）
   - これにより、依存系以外の PR では job が skipped = 通過扱いとなり、required check にしても他の PR をブロックしない

   ```yaml
   # Before
   on:
     pull_request:
       types: [opened, synchronize, reopened, ready_for_review]
       paths:
         - "environment/docker/nvim.dockerfile"
         - "environment/tools/python/**"
         - "environment/tools/node/**"
         - "environment/tools/go/**"
         - ".github/workflows/bump-tool-versions.yml"
         - ".github/dependabot.yml"

   # After
   on:
     pull_request:
       types: [opened, synchronize, reopened, ready_for_review]
   ```

3. **`main` ブランチに branch protection rule を設定する**
   - Settings > Branches > Add rule
   - "Require status checks to pass before merging" を有効化
   - Required checks:
     - `lint-format`（`lint_format.yml` の job 名）
     - `Docker build (environment/docker/nvim.dockerfile)`（`pr-docker-build.yml` の job name）

4. **新しいワークフロー `.github/workflows/auto-merge-deps.yml` を作成する**

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
         startsWith(github.head_ref, 'chore/bump-tool-versions') ||
         startsWith(github.head_ref, 'update/go-tools')
       runs-on: ubuntu-latest
       steps:
         - name: Enable auto-merge
           env:
             GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
           run: gh pr merge "${{ github.event.pull_request.number }}" --auto --squash --repo "${{ github.repository }}"
   ```

5. **動作確認する**
   - `workflow_dispatch` で `bump-tool-versions` または `update-go-tools` を手動実行して PR を作成
   - auto-merge ワークフローがトリガーされ、CI チェック通過後に自動マージされることを確認

## File changes

| File                                    | Change                                                                   |
| --------------------------------------- | ------------------------------------------------------------------------ |
| `.github/workflows/pr-docker-build.yml` | `on.pull_request.paths` を削除し、全 PR でワークフローが起動するよう変更 |
| `.github/workflows/auto-merge-deps.yml` | 新規作成: 依存更新 PR の auto-merge ワークフロー                         |

## Risks and mitigations

| Risk                                                                    | Mitigation                                                                                                                                                                                            |
| ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Branch protection rule 未設定だと、チェック未完了で即マージされる       | Step 3 を先に実施する。`--auto` フラグは required checks 通過まで待機するため、rule さえあれば安全                                                                                                    |
| `pr-docker-build` のパスフィルタ削除で全 PR でワークフローが起動する    | job レベルの `if:` で依存 PR 以外は skipped になるため、実行コストは増えない。required check としても skipped = 通過扱いで通常 PR をブロックしない                                                    |
| メジャーバージョンアップで破壊的変更が入る                              | Dependabot はグループ化されているため個別制御が難しい。`dependabot.yml` に `ignore` ルールや `update-types: ["minor", "patch"]` を追加して major を除外する運用も検討可能                             |
| `GITHUB_TOKEN` の権限不足で approve / merge が失敗する                  | `permissions: contents: write, pull-requests: write` をワークフローに明示。Dependabot PR では `GITHUB_TOKEN` のスコープが制限されるため、`pull_request_target` の使用が必要になる可能性がある（後述） |
| Dependabot PR で `pull_request` イベントだと secrets にアクセスできない | `pull_request_target` に変更する必要がある場合、セキュリティリスクを考慮して checkout は行わず `gh` コマンドのみ実行する設計にする                                                                    |

## Validation

- [ ] GitHub リポジトリ設定で "Allow auto-merge" が有効になっている
- [ ] `main` に branch protection rule が設定され、`lint-format` と `Docker build (environment/docker/nvim.dockerfile)` が required checks に指定されている
- [ ] `pr-docker-build.yml` の `on.pull_request.paths` が削除されている
- [ ] 依存系以外の PR で `pr-docker-build` の job が skipped になり、PR がブロックされない
- [ ] `auto-merge-deps.yml` が正しく配置されている
- [ ] Dependabot PR が作成された時に auto-merge が有効化される
- [ ] `bump-tool-versions` PR が作成された時に auto-merge が有効化される
- [ ] `update-go-tools` PR が作成された時に auto-merge が有効化される
- [ ] CI チェックが失敗した場合、マージされない
- [ ] 人間が作成した通常の PR は auto-merge の対象にならない

## Open questions

- **`pull_request` vs `pull_request_target`**: Dependabot PR では `pull_request` イベントだと `GITHUB_TOKEN` の権限が制限される。`pull_request_target` を使えば解決するが、セキュリティ上の考慮が必要。実際にデプロイして動作確認した上で判断するのが現実的
