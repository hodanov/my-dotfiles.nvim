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

# 順番に実行
markdownlint-cli2 --config "$HOME/.gemini/hooks/.markdownlint-cli2.yaml" --fix "$FILE_PATH"
prettier --write "$FILE_PATH"
