---
name: commit-and-draft-pr
description: 変更内容を確認してコミットし、ドラフトPRを作成する一連のGit/ghワークフローを実行する。git status/diff/log確認、適切なgit add、命令形コミットメッセージ作成、push、gh pr create --draft を含む作業で使用する。
---

# Commit and Draft PR

## 事前確認

- `git status` と `git diff` で変更を把握する
- `git log --oneline -5` で直近の履歴を把握する
- `git branch` で現在ブランチを確認する
- `main` の場合は feature ブランチを作成する

## ステージング

- 必要な変更のみ `git add` する
- 不要なファイル（例: `hogehoge`, `*.json`, `prompt.md`, `testcase.md` など）は除外する

## コミットメッセージ

- タイトルは命令形・72文字以内
- 本文は以下を含める:
  - 変更内容（何を変更したか）
  - 変更理由（なぜ変更したか）
  - 技術的な詳細（どのように変更したか）
  - 注意事項（影響範囲、レビュー時の確認ポイント）

## コミット実行

- Copilot CLI はコマンド置換内の heredoc（`git commit -m "$(cat <<'EOF'...)"` 形式）をセキュリティポリシーでブロックするため、**一時ファイル経由の2ステップ方式**を使う
- 例（内容は実際の変更に合わせて調整する）:

  ```bash
  # Step 1: コミットメッセージを一時ファイルに書き出す
  cat > /tmp/commit_msg.txt << 'EOF'
  タイトル（72文字以内）

  ## 変更内容
  - 変更点1
  - 変更点2

  ## 変更理由
  理由の説明

  ## 技術的な詳細
  詳細な説明

  ## 注意事項
  レビュー時の確認ポイントなど

  Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
  EOF

  # Step 2: ファイルを読み込んでコミットし、後始末する
  git commit -F /tmp/commit_msg.txt && rm /tmp/commit_msg.txt
  ```

## プッシュ

- `git push -u origin <ブランチ名>`
- リモートに同名ブランチがある場合は `--force-with-lease` を検討する
- push 前に対象ブランチを再確認する

## ドラフトPR作成

- `gh pr create --draft --base main --head <ブランチ名> --title "<タイトル>" --body "<本文>" --assignee hodanov`
- PR作成時は必ず `--assignee hodanov` を付けて自分をassignする
- 自動生成ツールの出力は必ず目視チェックしてから送信する
- 本文は以下のテンプレートに従い、実際の変更内容に合わせて記述する:

  ```markdown
  ## 実装経緯の説明

  <変更の背景と目的を簡潔に説明>

  ## チケット

  <チケットURL>

  ## 補足

  ### 主な変更内容

  - <変更点1: 具体的な説明>
  - <変更点2: 具体的な説明>

  ### 技術的な詳細

  - <実装の詳細1>
  - <実装の詳細2>

  ### 確認事項

  デプロイ後や動作確認時のチェックポイント

  - <確認項目1>
  - <確認項目2>
  ```

## 注意

- `gh` が未ログインの場合は `gh auth status` を確認し、必要ならログインする
- 既存のPRテンプレートがある場合は適宜整形する
