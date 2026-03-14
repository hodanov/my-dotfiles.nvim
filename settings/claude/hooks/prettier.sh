#!/bin/bash
FILE_PATH=$(echo "$CLAUDE_TOOL_OUTPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('filePath', ''))
" 2>/dev/null)

case "$FILE_PATH" in
*.html | *.css | *.js | *.ts | *.json | *.yaml | *.yml)
	prettier --write "$FILE_PATH"
	;;
esac
