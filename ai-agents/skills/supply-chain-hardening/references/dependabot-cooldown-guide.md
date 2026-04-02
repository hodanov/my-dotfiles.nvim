# Dependabot / Renovate クールダウン設定ガイド

## 概要

依存関係の自動更新ツールにクールダウン期間（14 日）を設定し、リリース直後の攻撃的なバージョンを自動取得するリスクを排除する。

## 対象ツールの検出

```bash
# Dependabot
ls .github/dependabot.yml .github/dependabot.yaml 2>/dev/null

# Renovate
ls renovate.json renovate.json5 .renovaterc .renovaterc.json 2>/dev/null
```

## Dependabot の設定

### cooldown の追加

`.github/dependabot.yml` の各 `package-ecosystem` エントリに `cooldown` を追加する。

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    cooldown:
      default-days: 14

  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
    cooldown:
      default-days: 14

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    cooldown:
      default-days: 14

  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    cooldown:
      default-days: 14
```

### dependabot.yml に設定済みかの確認

```bash
# cooldown が設定されているエコシステム数
grep -c 'cooldown' .github/dependabot.yml

# 各エコシステムの cooldown 値を確認
grep -A2 'cooldown' .github/dependabot.yml
```

### エコシステムごとの cooldown 一覧

全てのエコシステムに `cooldown: default-days: 14` が必要。
一部だけ設定されている場合は未設定のエコシステムに追加する。

確認方法:

```bash
# エコシステム数
grep -c 'package-ecosystem' .github/dependabot.yml

# cooldown 数
grep -c 'default-days' .github/dependabot.yml
```

この 2 つの数が一致していれば全エコシステムに設定済み。

## Renovate の設定

### minimumReleaseAge の追加

Renovate は `packageRules` 内の `minimumReleaseAge` でクールダウン期間を設定する。値は `"14 days"` 形式。

#### 全エコシステム共通で設定する場合

```json
{
  "extends": ["config:base"],
  "packageRules": [
    {
      "matchUpdateTypes": [
        "minor",
        "patch",
        "pin",
        "digest"
      ],
      "minimumReleaseAge": "14 days"
    }
  ]
}
```

#### GitHub Actions のみに設定する場合

```json
{
  "extends": ["config:base"],
  "packageRules": [
    {
      "matchManagers": ["github-actions"],
      "minimumReleaseAge": "14 days"
    }
  ]
}
```

#### 複数のマネージャーに個別設定する場合

```json
{
  "extends": ["config:base"],
  "packageRules": [
    {
      "matchManagers": ["github-actions"],
      "minimumReleaseAge": "14 days"
    },
    {
      "matchManagers": ["gomod"],
      "minimumReleaseAge": "14 days"
    },
    {
      "matchManagers": ["npm"],
      "minimumReleaseAge": "14 days"
    }
  ]
}
```

### renovate.json に設定済みかの確認

```bash
grep 'minimumReleaseAge' renovate.json renovate.json5 \
  .renovaterc .renovaterc.json 2>/dev/null
```

## どちらも未導入の場合

ユーザーに Dependabot の導入を提案する。

### 最小構成テンプレート

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    cooldown:
      default-days: 14
```

必要に応じてエコシステム（gomod, npm, docker, pip 等）を追加するようユーザーに案内する。

## 自動マージとの組み合わせ

自動マージルールが有効な場合、クールダウン設定は特に重要。
クールダウンなしの自動マージは攻撃されたバージョンを即座に取り込むリスクがある。

確認ポイント:

- Dependabot: `open-pull-requests-limit` や
  GitHub の auto-merge 設定
- Renovate: `automerge: true` の設定
