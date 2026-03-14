#!/bin/bash
FILE_PATH=$(echo "$CLAUDE_TOOL_OUTPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('filePath', ''))
" 2>/dev/null)

if [[ "$FILE_PATH" != *.sh ]]; then
  exit 0
fi

shfmt -w "$FILE_PATH"
