# Plan: Git コミットへのクレデンシャル混入防止

AI や人が誤ってシークレットをコミットするリスクを、ローカル（pre-commit）と CI の 2 層で機械的にブロックする。ツール選定と導入手順をまとめる。

## Background

- AI コーディングアシスタントや開発者が、API キー・トークン等を含むコードを誤ってコミットするリスクがある
- 手動レビューだけでは漏れが避けられないため、機械的な検出・ブロックの仕組みが必要
- ローカル（pre-commit hook）と CI（PR スキャン）の 2 層で防御するのが業界標準のアプローチ

## ツール比較

### ローカル: gitleaks vs git-secrets

| 観点                      | gitleaks                                              | git-secrets                                           |
| ------------------------- | ----------------------------------------------------- | ----------------------------------------------------- |
| メンテナ                  | gitleaks org (Zach Rice)                              | awslabs (AWS)                                         |
| 開発状況                  | 活発（v8.30.1, 2026-03）                              | 実質メンテナンスモード（最終タグ 1.3.0、長期停滞）    |
| 言語                      | Go（高速）                                            | Bash スクリプト（大規模リポジトリで遅い）             |
| ルール定義                | TOML (`.gitleaks.toml`) — regex + allowlist + entropy | `.gitconfig` にシェルベースの regex を登録            |
| pre-commit フレームワーク | 公式対応（`pre-commit-hooks.yaml` あり）              | 非対応（独自 hook を `git secrets --install` で導入） |
| Git 履歴スキャン          | `gitleaks detect` で高速スキャン可能                  | `git secrets --scan-history` で可能だが低速           |
| ライセンス                | MIT                                                   | Apache 2.0                                            |

**結論: gitleaks を採用。** git-secrets は開発停滞、Bash 依存で遅く、pre-commit フレームワーク非対応。

### CI: gitleaks vs TruffleHog

| 観点           | gitleaks                                          | TruffleHog                                                          |
| -------------- | ------------------------------------------------- | ------------------------------------------------------------------- |
| メンテナ       | gitleaks org (OSS)                                | Truffle Security Co.（商用企業が OSS 版も提供）                     |
| 検出方式       | regex + entropy（ルール単位）                     | regex + entropy + **クレデンシャル検証**（実際に有効か API で確認） |
| 誤検知の少なさ | ルール次第で誤検知あり                            | 検証機能により誤検知を大幅削減                                      |
| GitHub Actions | `gitleaks-action`（org 利用は有料ライセンス必要） | `trufflehog-action`（OSS CLI は無料）                               |
| diff スキャン  | `--log-opts` で範囲指定可能                       | `--since-commit`, `--branch`, `--only-verified` 対応                |
| 出力形式       | JSON, CSV, SARIF                                  | JSON, plain text（SARIF はコンバータ経由）                          |
| ライセンス     | MIT（Action v2+ は商用ティアあり）                | AGPL-3.0（エンタープライズ SaaS は有料）                            |

**結論: CI は TruffleHog を推奨。** クレデンシャル検証による誤検知削減が最大の差別化ポイント。AGPL ライセンスが問題になる場合は gitleaks で代替可能。

## Design policy

- **2 層防御**: ローカル（gitleaks + pre-commit）で早期ブロック、CI（TruffleHog）で最終防御
- ローカルは pre-commit フレームワーク経由で導入し、チーム全体で統一する
- `.gitleaks.toml` でプロジェクト固有の allowlist を管理し、誤検知を制御する
- CI はPR 単位の diff スキャンに限定し、実行時間を短縮する

## Implementation steps

### Phase 1: ローカル — gitleaks + pre-commit

1. `pre-commit` がインストール済みか確認（`.pre-commit-config.yaml` の有無）
2. `.pre-commit-config.yaml` に gitleaks hook を追加:

   ```yaml
   repos:
     - repo: https://github.com/gitleaks/gitleaks
       rev: v8.30.1 # 最新バージョンを確認して指定
       hooks:
         - id: gitleaks
   ```

3. `.gitleaks.toml` をリポジトリルートに作成し、プロジェクト固有の allowlist を定義:

   ```toml
   [allowlist]
   paths = [
     '''\.gitleaks\.toml$''',
     '''go\.sum$''',
   ]
   ```

4. `pre-commit install` で hook を有効化
5. テスト用のダミーシークレットでブロックされることを確認

### Phase 2: CI — TruffleHog GitHub Action

1. `.github/workflows/` に secret scanning ワークフローを追加:

   ```yaml
   name: Secret Scan
   on:
     pull_request:
   jobs:
     trufflehog:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
           with:
             fetch-depth: 0
         - uses: trufflesecurity/trufflehog@main
           with:
             extra_args: --only-verified
   ```

2. `--only-verified` で検証済みシークレットのみ検出し、誤検知を抑制
3. テスト PR で動作確認

### Phase 3: 既存履歴のスキャン（現時点では実施しない — 手順のみ記録）

> 既存履歴のスキャンは今回のスコープ外。ただし機微情報が混入した場合の対応手順として残す。

1. `gitleaks detect --source . --report-format json --report-path gitleaks-report.json` でフルスキャン
2. 検出された過去のシークレットをローテーション（キー再発行 + 旧キー無効化）
3. 必要に応じて `git filter-repo` で履歴からシークレットを除去

## Risks and mitigations

| Risk                                              | Mitigation                                                                        |
| ------------------------------------------------- | --------------------------------------------------------------------------------- |
| 誤検知でコミットがブロックされ開発速度が低下する  | `.gitleaks.toml` の allowlist で制御。`SKIP=gitleaks git commit` で一時回避も可能 |
| `--only-verified` でも検出漏れが発生する          | ローカル gitleaks（regex ベース）との 2 層で補完                                  |
| pre-commit hook を `--no-verify` でスキップされる | CI 側の TruffleHog が最終防御。PR マージ要件に secret scan パスを追加             |
| 過去の履歴に既にシークレットが含まれている        | 今回はスコープ外。発覚時は Phase 3 の手順でキーローテーション + 履歴除去          |
| gitleaks-action の org 利用が有料化               | ローカルは pre-commit 経由なので無料。CI は TruffleHog で対応                     |

## Validation

- [ ] gitleaks pre-commit hook がダミーシークレット含むコミットをブロックする
- [ ] `.gitleaks.toml` の allowlist が意図通り動作する
- [ ] TruffleHog GitHub Action が PR でシークレットを検出する
- [ ] `--only-verified` で誤検知が抑制されている
- [ ] 既存の pre-commit hook（もしあれば）と共存できる
- [ ] `--no-verify` スキップ時でも CI がキャッチする

## Decisions

- **TruffleHog (AGPL-3.0) の CI 利用**: 組織ポリシーで OK 確認済み。採用する
- **既存履歴のスキャン**: 今回は実施しない。インシデント対応用に手順のみ Phase 3 に残す
- **`.gitleaks.toml` カスタムルール**: プロジェクト依存のため初期導入時は最小構成で。将来追加できる余地を残す
