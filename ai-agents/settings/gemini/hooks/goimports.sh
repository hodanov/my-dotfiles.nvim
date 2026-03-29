#!/bin/bash
# stdin から JSON を読み込む
INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('tool_input', {}).get('file_path', ''))
")

# .goファイルじゃなければ何もしない
if [[ "$FILE_PATH" != *.go ]]; then
	exit 0
fi

# goimportsを実行
goimports -w "$FILE_PATH"
