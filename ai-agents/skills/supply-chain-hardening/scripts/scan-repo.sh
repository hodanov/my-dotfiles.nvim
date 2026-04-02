#!/usr/bin/env bash
set -euo pipefail

# Supply Chain Hardening — リポジトリ現状スキャン
# Phase 1-1 で使用する調査スクリプト。
# リポジトリルートから実行すること。

section() {
	printf '\n## %s\n\n' "$1"
}

section "GitHub Actions ワークフロー一覧"
find .github/workflows -name '*.yml' 2>/dev/null | sort | head -30 ||
	echo "(GitHub Actions ワークフローなし)"

section "未ピン留めの外部 Action"
grep -rh 'uses:' .github/workflows/ 2>/dev/null |
	sed 's/.*uses: *//' |
	grep -v '#' |
	grep -v '^\.\/' |
	sort -u ||
	echo "(未ピン留め Action なし)"

section "ピン留め済みの Action"
grep -rh 'uses:' .github/workflows/ 2>/dev/null |
	sed 's/.*uses: *//' |
	grep '#' |
	sort -u |
	head -20 ||
	echo "(なし)"

section "Dependabot / Renovate 設定の存在"
ls -la .github/dependabot.yml .github/dependabot.yaml \
	renovate.json renovate.json5 .renovaterc .renovaterc.json 2>/dev/null ||
	echo "(依存関係更新ツールの設定なし)"

section "Dependabot の cooldown 設定状況"
grep -A2 'cooldown' .github/dependabot.yml 2>/dev/null ||
	echo "(cooldown 未設定または dependabot.yml なし)"

section "Renovate の minimumReleaseAge 設定状況"
grep 'minimumReleaseAge' \
	renovate.json renovate.json5 .renovaterc .renovaterc.json 2>/dev/null ||
	echo "(minimumReleaseAge 未設定または renovate 設定なし)"
