#!/bin/bash
# ai-bridge-daemon: watches ~/.ai-bridge/request.json and launches Claude Code
# in a new terminal tab via the configured launcher.
#
# Environment variables:
#   AI_BRIDGE_LAUNCHER  Launcher name (default: wezterm). Must match a script in launchers/.
#   AI_BRIDGE_DIR       Bridge directory to watch (default: ~/.ai-bridge).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAUNCHERS_DIR="${SCRIPT_DIR}/launchers"

BRIDGE_DIR="${AI_BRIDGE_DIR:-${HOME}/.ai-bridge}"
REQUEST_FILE="${BRIDGE_DIR}/request.json"

LAUNCHER="${AI_BRIDGE_LAUNCHER:-wezterm}"
LAUNCHER_SCRIPT="${LAUNCHERS_DIR}/${LAUNCHER}.sh"

# Validate launcher
if [[ ! -x "$LAUNCHER_SCRIPT" ]]; then
    echo "ERROR: Launcher not found or not executable: ${LAUNCHER_SCRIPT}" >&2
    exit 1
fi

mkdir -p "$BRIDGE_DIR"

echo "ai-bridge-daemon: started (launcher=${LAUNCHER}, watching ${REQUEST_FILE})"

fswatch -o "$REQUEST_FILE" | while read -r _; do
    [[ -f "$REQUEST_FILE" ]] || continue

    # Atomically consume the request to prevent duplicate launches
    consumed="${REQUEST_FILE}.$(date +%s%N).consumed"
    mv "$REQUEST_FILE" "$consumed"

    # Parse fields from JSON
    prompt=$(jq -r '.prompt' "$consumed")
    cwd=$(jq -r '.cwd' "$consumed")

    rm -f "$consumed"

    # Create a temp script that runs claude with the finalized prompt.
    # printf %q handles all quoting safely regardless of prompt content.
    tmp_script=$(mktemp /tmp/ai-bridge-XXXXXX.sh)
    chmod +x "$tmp_script"
    {
        echo "#!/bin/bash"
        printf "claude %q\n" "$prompt"
        printf "rm -f %q\n" "$tmp_script"
    } > "$tmp_script"

    echo "ai-bridge-daemon: launching for cwd=${cwd}"
    "$LAUNCHER_SCRIPT" "$cwd" "$tmp_script"
done
