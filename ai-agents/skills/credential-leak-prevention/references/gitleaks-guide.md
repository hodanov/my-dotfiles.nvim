# gitleaks セットアップガイド

## 概要

gitleaks は Go 製のシークレットスキャナ。regex + エントロピー解析でコミット内のクレデンシャルを検出する。
pre-commit フレームワークと統合することで、コミット前に自動的にブロックできる。

## ツール比較（採用根拠）

| 観点            | gitleaks                 | git-secrets                     |
| --------------- | ------------------------ | ------------------------------- |
| 開発状況        | 活発（v8.30.1, 2026-03） | 実質メンテナンスモード          |
| 言語            | Go（高速）               | Bash（大規模リポジトリで遅い）  |
| pre-commit 対応 | 公式対応                 | 非対応                          |
| ルール定義      | TOML（`.gitleaks.toml`） | gitconfig にシェル regex を登録 |

**結論: gitleaks を採用。**

## .gitleaks.toml の構成

リポジトリルートに置くことで自動的に読み込まれる。

```toml
[extend]
useDefault = true   # ← 必須: デフォルトルールセットを継承する

[allowlist]
paths = [
  '''\.gitleaks\.toml$''',   # 設定ファイル自体を除外
  '''go\.sum$''',            # Go モジュールのチェックサムを除外
]
```

### useDefault = true が必要な理由

`.gitleaks.toml` を置いた場合、デフォルト設定を **完全に上書き** する。
`useDefault = true` がないとルールが空になり、何も検出されなくなる。

### allowlist のカスタマイズ

プロジェクト固有の誤検知が出た場合は `[allowlist]` に追加する:

```toml
[allowlist]
paths = [
  '''\.gitleaks\.toml$''',
  '''go\.sum$''',
  '''tests/fixtures/.*''',   # テスト用フィクスチャを除外する場合
]
regexes = [
  '''EXAMPLE_KEY''',         # ドキュメント内のサンプル値を除外する場合
]
```

## pre-commit との統合

`.pre-commit-config.yaml` に以下を追加する:

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.30.1
    hooks:
      - id: gitleaks
```

フックを有効化:

```bash
pre-commit install
```

## 誤検知への対処

### 一時的にスキップする

```bash
SKIP=gitleaks git commit -m "..."
```

### 特定行を無視する

ファイル内のコメントで個別に除外できる:

```python
api_key = "example-value"  # gitleaks:allow
```

## git 履歴のフルスキャン（インシデント対応用）

過去のコミットに混入した疑いがある場合:

```bash
gitleaks detect --source . --report-format json --report-path gitleaks-report.json
```

検出されたシークレットが見つかった場合:

1. 該当キーをローテーション（再発行 + 旧キー無効化）
2. `git filter-repo` で履歴からシークレットを除去
3. リモートに force push

> **注意**: 履歴除去は破壊的操作。チーム全員がリベースし直す必要があるため、関係者全員の合意を取ること。
