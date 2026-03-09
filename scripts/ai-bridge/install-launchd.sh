#!/bin/bash
# install-launchd.sh: Install ai-bridge-daemon as a launchd agent.
# Replaces %%REPO_DIR%% in the plist template and loads the agent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

PLIST_SRC="${SCRIPT_DIR}/com.ai-bridge.daemon.plist"
PLIST_DST="${HOME}/Library/LaunchAgents/com.ai-bridge.daemon.plist"

if [[ ! -f "$PLIST_SRC" ]]; then
	echo "ERROR: plist template not found: ${PLIST_SRC}" >&2
	exit 1
fi

mkdir -p "$(dirname "$PLIST_DST")"

sed "s|%%REPO_DIR%%|${REPO_DIR}|g" "$PLIST_SRC" >"$PLIST_DST"
echo "Installed: ${PLIST_DST}"

launchctl unload "$PLIST_DST" 2>/dev/null || true
launchctl load "$PLIST_DST"
echo "Loaded: com.ai-bridge.daemon"
