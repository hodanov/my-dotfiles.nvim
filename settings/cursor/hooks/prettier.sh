#!/bin/bash
FILE_PATH=$(python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('file_path', ''))
")

case "$FILE_PATH" in
*.html | *.css | *.js | *.ts | *.json | *.yaml | *.yml)
	prettier --write "$FILE_PATH"
	;;
esac
