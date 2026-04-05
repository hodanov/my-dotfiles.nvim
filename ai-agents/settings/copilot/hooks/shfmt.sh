#!/bin/bash
# stdin から JSON を読み込む
INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FILE_PATH=$(printf '%s' "$INPUT" | python3 "$SCRIPT_DIR/get_file_path.py")

if [[ "$FILE_PATH" != *.sh ]]; then
	exit 0
fi

if ! shfmt -w "$FILE_PATH" 2>&1; then
	rc=$?
	echo "[shfmt] fail: $FILE_PATH" >&2
	exit "$rc"
fi
