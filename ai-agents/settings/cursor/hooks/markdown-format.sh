#!/bin/bash
# stdin から JSON を読み込む
INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FILE_PATH=$(printf '%s' "$INPUT" | python3 "$SCRIPT_DIR/get_file_path.py")

# .mdファイルじゃなければ何もしない
if [[ "$FILE_PATH" != *.md ]]; then
	exit 0
fi

markdownlint-cli2 --config "$HOME/.claude/hooks/.markdownlint-cli2.yaml" --fix "$FILE_PATH"
prettier --write "$FILE_PATH"
