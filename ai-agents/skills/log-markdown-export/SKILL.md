---
name: log-markdown-export
description: 作業ログをMarkdownファイルとして出力し、`docs/log/YYYY-MM-DD_<plan-name>.md`に保存する作業で使用する。ログの書き出し、命名、markdownlintの実行が必要なときに使う。
---

# Log Markdown Export

## 手順

1. 依頼内容からプラン名を短いkebab-caseで決める（指定がある場合はそれを使う）。
2. `docs/log/` が無ければ作成する。
3. 日付はローカルの日付を使い、`YYYY-MM-DD_<plan-name>.md` でファイルを作成する（必要なら `date +%F` で確認する）。
4. `# Log` から始まるMarkdownで内容を書く。
5. `markdownlint-cli2 --fix <file>` を実行する。
6. 生成したファイルパスを返す。

## テンプレート

```markdown
# Log

<date summary sentence>

## Summary

- <Item 1>
- <Item 2>
- <Item 3>

## Details

- <Area 1>
- <Area 2>
```

## 注意

- 既存ファイルがある場合は上書き前に確認する。
- ファイル名はASCIIを優先する。
