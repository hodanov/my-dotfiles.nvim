# GitHub Actions SHA ピン留めガイド

## 概要

GitHub Actions の `uses:` で指定する Action は、タグ指定だと攻撃者が同一タグに悪意あるコードを上書き公開するリスクがある。
SHA（コミットハッシュ）でピン留めすることで、取得するコードを不変に固定する。

## 前提条件

**pinact が必須。** 未インストールの場合は以下を参照:
<https://github.com/suzuki-shunsuke/pinact/blob/main/INSTALL.md>

## 未ピン留め Action の検出

```bash
# 外部 Action で SHA ピン留めされていないもの一覧
grep -rn 'uses:' .github/workflows/ \
  | grep -v '#' \
  | grep -v '\./'
```

- `# vX.Y.Z` コメントがある行はピン留め済み
- `./.github/` で始まるローカル参照はピン留め不要
- `org/repo/.github/workflows/x.yml@ref` は reusable workflow

## ピン留め対象の判定

| パターン                       | 例                                    | 対応         |
| ------------------------------ | ------------------------------------- | ------------ |
| タグ指定（未ピン留め）         | `actions/checkout@v6`                 | ピン留め対象 |
| SHA + コメント（ピン留め済み） | `actions/checkout@abc...def # v6.0.2` | verify のみ  |
| ローカル参照                   | `./.github/common/action`             | 対象外       |
| reusable workflow              | `org/repo/...yml@main`                | ピン留め対象 |
| reusable workflow（SHA）       | `org/repo/...yml@abc...def`           | verify のみ  |

## pinact によるピン留め

### 全ワークフローを一括ピン留め

```bash
pinact run .github/workflows/
```

- 未ピン留めの全 Action を自動で SHA ピン留めする
- `SHA # vX.Y.Z` 形式のコメントも自動付与される
- Dependabot が正しく更新 PR を作るためにこのコメントが必要

### 整合性チェック

```bash
pinact run --verify .github/workflows/*
```

- 既にピン留めされた SHA が正しいタグに対応しているか検証する
- 不整合がある場合はエラーを返す → `pinact run` で再ピン留めする

## 2 週間ルール

ピン留め後のバージョンが **2 週間以上前のリリース** であることを確認する。
2 週間未満のバージョンは、攻撃が発覚していない可能性があるため注意が必要。

確認方法:

- GitHub の Releases ページ（`https://github.com/{owner}/{repo}/releases`）でリリース日を目視確認する
- pinact が出力するバージョンコメント（`# vX.Y.Z`）のバージョン番号を元にリリースページを確認する

2 週間未満のバージョンしかない場合:

1. 1 つ前のマイナー / パッチバージョンに下げることを検討する
2. ユーザーに判断を委ねる

## reusable workflow の取り扱い

reusable workflow は `org/repo/.github/workflows/x.yml@ref` 形式。
pinact はこの形式も自動的にピン留めする。

ピン留め後:

```yaml
uses: org/repo/.github/workflows/ci.yml@abc123def # main
```
