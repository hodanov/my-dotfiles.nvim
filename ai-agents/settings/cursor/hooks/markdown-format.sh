#!/bin/bash
# stdin から JSON を読み込む
INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FILE_PATH=$(printf '%s' "$INPUT" | python3 "$SCRIPT_DIR/get_file_path.py")

# .mdファイルじゃなければ何もしない
if [[ "$FILE_PATH" != *.md ]]; then
	exit 0
fi

# markdownlint-cli2
if ! markdownlint-cli2 --config "$SCRIPT_DIR/.markdownlint-cli2.yaml" --fix "$FILE_PATH" 2>&1; then
	rc=$?
	echo "[markdownlint] fail: $FILE_PATH" >&2
	exit "$rc"
fi

# prettier
if ! prettier --write "$FILE_PATH" 2>&1; then
	rc=$?
	echo "[prettier:md] fail: $FILE_PATH" >&2
	exit "$rc"
fi
