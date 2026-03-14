#!/bin/bash
FILE_PATH=$(python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('file_path', ''))
")

if [[ "$FILE_PATH" != *.md ]]; then
  exit 0
fi

markdownlint-cli2 --fix "$FILE_PATH"
prettier --write "$FILE_PATH"
