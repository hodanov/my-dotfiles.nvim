#!/bin/bash
# ai-bridge-daemon: watches ~/.ai-bridge/request.json and launches an AI CLI
# in a new terminal tab via the configured launcher.
#
# Environment variables:
#   AI_BRIDGE_CLI       AI CLI command to run (default: claude). e.g. claude, cursor
#   AI_BRIDGE_LAUNCHER  Launcher name (default: wezterm). Must match a script in launchers/.
#   AI_BRIDGE_DIR       Bridge directory to watch (default: ~/.ai-bridge).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAUNCHERS_DIR="${SCRIPT_DIR}/launchers"

BRIDGE_DIR="${AI_BRIDGE_DIR:-${HOME}/.ai-bridge}"
REQUEST_FILE="${BRIDGE_DIR}/request.json"

AI_CLI="${AI_BRIDGE_CLI:-claude}"

LAUNCHER="${AI_BRIDGE_LAUNCHER:-wezterm}"
if [[ ! "$LAUNCHER" =~ ^[a-z][a-z0-9_-]*$ ]]; then
	echo "ERROR: Invalid launcher name: ${LAUNCHER} (only [a-z0-9_-] allowed)" >&2
	exit 1
fi
LAUNCHER_SCRIPT="${LAUNCHERS_DIR}/${LAUNCHER}.sh"

# Validate launcher
if [[ ! -x "$LAUNCHER_SCRIPT" ]]; then
	echo "ERROR: Launcher not found or not executable: ${LAUNCHER_SCRIPT}" >&2
	exit 1
fi

mkdir -p "$BRIDGE_DIR"

echo "ai-bridge-daemon: started (cli=${AI_CLI}, launcher=${LAUNCHER}, watching ${REQUEST_FILE})"

fswatch -o "$REQUEST_FILE" | while read -r _; do
	[[ -f "$REQUEST_FILE" ]] || continue

	# Atomically consume the request to prevent duplicate launches
	consumed="${REQUEST_FILE}.$(date +%s%N).consumed"
	mv "$REQUEST_FILE" "$consumed"

	# Parse fields from JSON (cwd is always a single-line path, so read it
	# first; the remaining multiline content becomes prompt)
	{ read -r cwd; IFS= read -r -d '' prompt || true; } < <(jq -r '.cwd, .prompt' "$consumed")

	rm -f "$consumed"

	if [[ ! -d "$cwd" ]]; then
		echo "ai-bridge-daemon: WARNING: cwd is not a valid directory: ${cwd}, skipping" >&2
		continue
	fi

	# Create a temp script that runs the AI CLI with the finalized prompt.
	# printf %q handles all quoting safely regardless of prompt content.
	tmp_script=$(mktemp /tmp/ai-bridge-XXXXXX.sh)
	{
		echo "#!/bin/bash"
		printf "%s %q\n" "$AI_CLI" "$prompt"
		printf "rm -f %q\n" "$tmp_script"
	} >"$tmp_script"
	chmod +x "$tmp_script"

	echo "ai-bridge-daemon: launching for cwd=${cwd}"
	"$LAUNCHER_SCRIPT" "$cwd" "$tmp_script" || rm -f "$tmp_script"
done
