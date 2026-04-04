#!/usr/bin/env bash
set -euo pipefail

# Credential Leak Prevention — セットアップ（冪等）
# リポジトリルートから実行すること。

ok() { printf '✓ %s\n' "$1"; }
info() { printf '→ %s\n' "$1"; }
err() {
	printf 'ERROR: %s\n' "$1" >&2
	exit 1
}

# 前提ツール確認
if ! command -v pre-commit >/dev/null 2>&1 || ! command -v gitleaks >/dev/null 2>&1; then
	err "pre-commit と gitleaks の両方がインストールされている必要があります。
  brew install pre-commit gitleaks"
fi

# .pre-commit-config.yaml
if [ ! -f .pre-commit-config.yaml ]; then
	info ".pre-commit-config.yaml を新規作成します"
	cat >.pre-commit-config.yaml <<'YAML'
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.30.1
    hooks:
      - id: gitleaks
YAML
	ok ".pre-commit-config.yaml を作成しました"
elif grep -q 'gitleaks' .pre-commit-config.yaml; then
	ok ".pre-commit-config.yaml に gitleaks hook が設定済みです（スキップ）"
else
	info "既存の .pre-commit-config.yaml に gitleaks hook を追記します"
	cat >>.pre-commit-config.yaml <<'YAML'
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.30.1
    hooks:
      - id: gitleaks
YAML
	ok "gitleaks hook を追記しました"
fi

# .gitleaks.toml
if [ -f .gitleaks.toml ]; then
	ok ".gitleaks.toml が存在します（スキップ）"
else
	info ".gitleaks.toml を作成します"
	cat >.gitleaks.toml <<'TOML'
[extend]
useDefault = true

[allowlist]
paths = [
  '''\.gitleaks\.toml$''',
  '''go\.sum$''',
]
TOML
	ok ".gitleaks.toml を作成しました"
fi

# pre-commit install
info "pre-commit install を実行します"
pre-commit install
ok "git hook を有効化しました"

printf '\nセットアップ完了。以下で動作確認を実行してください:\n'
printf '  bash ai-agents/skills/credential-leak-prevention/scripts/validate.sh\n'
