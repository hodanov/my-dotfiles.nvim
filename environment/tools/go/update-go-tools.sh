#!/bin/bash

# Goツールのバージョン更新スクリプト
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
GO_TOOLS_FILE="$PROJECT_ROOT/environment/tools/go/go-tools.txt"
TEMP_FILE=$(mktemp)

echo "🔍 Goツールの最新バージョンをチェック中..."

# Goの環境をチェック
if ! command -v go &>/dev/null; then
	echo "❌ Goがインストールされていません"
	exit 1
fi

echo "✅ Go環境: $(go version)"
echo "✅ GOPATH: $(go env GOPATH)"
echo "✅ GOROOT: $(go env GOROOT)"

# 各ツールの最新バージョンを取得して更新
while IFS= read -r line || [[ -n "$line" ]]; do
	# コメント行や空行をスキップ
	if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
		echo "$line" >>"$TEMP_FILE"
		continue
	fi

	# パッケージパスと現在のバージョンを抽出
	if [[ "$line" =~ ^([^@]+)@(.+)$ ]]; then
		package_path="${BASH_REMATCH[1]}"
		current_version="${BASH_REMATCH[2]}"

		echo "📦 $package_path の最新バージョンをチェック中..."

		# 最新バージョンを取得（より堅牢な方法）
		echo "  🔍 最新バージョンを取得中..."

		# 一時的なディレクトリでGoモジュールを初期化
		temp_dir=$(mktemp -d)
		cd "$temp_dir"

		# go.modを作成
		echo "module temp" >go.mod

		# パッケージの最新バージョンを取得
		if latest_version=$(go get -d "$package_path"@latest 2>/dev/null && go list -m "$package_path" 2>/dev/null | cut -d' ' -f2); then
			if [[ -n "$latest_version" && "$latest_version" != "$current_version" ]]; then
				echo "  ✅ $current_version → $latest_version に更新"
				echo "$package_path@$latest_version" >>"$TEMP_FILE"
			else
				echo "  ℹ️  最新バージョン ($current_version) は既に使用中"
				echo "$line" >>"$TEMP_FILE"
			fi
		else
			echo "  ⚠️  最新バージョンの取得に失敗、現在のバージョンを保持: $current_version"
			echo "$line" >>"$TEMP_FILE"
		fi

		# 一時ディレクトリをクリーンアップ
		cd "$PROJECT_ROOT"
		rm -rf "$temp_dir"
	else
		# バージョン指定がない行はそのまま保持
		echo "$line" >>"$TEMP_FILE"
	fi
done <"$GO_TOOLS_FILE"

# ファイルを置き換え
mv "$TEMP_FILE" "$GO_TOOLS_FILE"

echo "🎉 Goツールのバージョン更新が完了しました！"
echo "📝 更新されたファイル: $GO_TOOLS_FILE"

# 変更内容を表示
if git diff --quiet "$GO_TOOLS_FILE"; then
	echo "ℹ️  更新は必要ありませんでした"
else
	echo "📋 変更内容:"
	git diff "$GO_TOOLS_FILE"
fi
