#!/bin/bash
FILE_PATH=$(python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('file_path', ''))
")

if [[ "$FILE_PATH" != *.sh ]]; then
	exit 0
fi

shfmt -w "$FILE_PATH"
