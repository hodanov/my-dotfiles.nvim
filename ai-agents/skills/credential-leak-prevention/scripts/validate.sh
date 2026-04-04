#!/usr/bin/env bash
set -euo pipefail

# Credential Leak Prevention — 動作検証
# ダミーシークレットでブロックされることを確認する。
# リポジトリルートから実行すること。

DUMMY_FILE="test-credential-leak-dummy.txt"
# 実在しないダミートークン（テスト専用）
DUMMY_TOKEN="ghp_xkB7mP3nQR9sT5wY2uA8vE4cJ6hL1dF0iG" # gitleaks:allow

cleanup() {
	git restore --staged "$DUMMY_FILE" 2>/dev/null || true
	rm -f "$DUMMY_FILE"
}
trap cleanup EXIT

printf 'ダミーシークレットを含むファイルを作成します...\n'
printf 'GITHUB_TOKEN=%s\n' "$DUMMY_TOKEN" >"$DUMMY_FILE"
git add "$DUMMY_FILE"

printf 'pre-commit run gitleaks を実行します...\n\n'
if pre-commit run gitleaks --files "$DUMMY_FILE" 2>&1; then
	printf '\n✗ シークレットが検出されませんでした（.gitleaks.toml の useDefault = true を確認してください）\n'
	exit 1
else
	printf '\n✓ シークレットが正しく検出・ブロックされました\n'
fi
