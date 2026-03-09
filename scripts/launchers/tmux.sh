#!/bin/bash
# tmux launcher for ai-bridge
# Usage: tmux.sh <cwd> <script_file>
# Requires an active tmux session.
#
# Launcher contract:
#   - Receives: $1=cwd (working directory), $2=script (absolute path to temp script)
#   - Must: open a new terminal window/tab, cd to $cwd, and execute `bash -l $script`
#   - Escaping: tmux new-window takes a shell command string (not an argv list),
#     so $script must be escaped with printf %q to handle special characters.
set -euo pipefail

cwd="$1"
script="$2"

tmux new-window -c "$cwd" "bash -l $(printf '%q' "$script")"
