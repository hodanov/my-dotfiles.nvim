#!/bin/bash
# tmux launcher for ai-bridge
# Usage: tmux.sh <cwd> <script_file>
# Requires an active tmux session.
set -euo pipefail

cwd="$1"
script="$2"

tmux new-window -c "$cwd" "bash -l $(printf '%q' "$script")"
