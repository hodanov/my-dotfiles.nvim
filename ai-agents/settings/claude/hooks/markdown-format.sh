#!/bin/bash
FILE_PATH=$(echo "$CLAUDE_TOOL_OUTPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('filePath', ''))
" 2>/dev/null)

# .mdファイルじゃなければ何もしない
if [[ "$FILE_PATH" != *.md ]]; then
	exit 0
fi

# 順番に実行
markdownlint-cli2 --fix "$FILE_PATH"
prettier --write "$FILE_PATH"
