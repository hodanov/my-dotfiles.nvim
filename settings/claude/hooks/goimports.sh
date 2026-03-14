#!/bin/bash
# CLAUDE_TOOL_OUTPUT から filePath を取得
FILE_PATH=$(echo "$CLAUDE_TOOL_OUTPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('filePath', ''))
" 2>/dev/null)

# .goファイルじゃなければ何もしない
if [[ "$FILE_PATH" != *.go ]]; then
	exit 0
fi

# goimportsを実行
goimports -w "$FILE_PATH"
