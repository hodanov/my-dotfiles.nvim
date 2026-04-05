#!/bin/bash
# stdin から JSON を読み込む
INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('tool_input', {}).get('file_path', ''))
")

# .mdファイルじゃなければ何もしない
if [[ "$FILE_PATH" != *.md ]]; then
	exit 0
fi

# markdownlint-cli2
if ! markdownlint-cli2 --config "$HOME/.claude/hooks/.markdownlint-cli2.yaml" --fix "$FILE_PATH" 2>&1; then
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
