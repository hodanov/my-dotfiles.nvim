#!/bin/bash
# WezTerm launcher for ai-bridge
# Usage: wezterm.sh <cwd> <script_file>
#
# Launcher contract:
#   - Receives: $1=cwd (working directory), $2=script (absolute path to temp script)
#   - Must: open a new terminal window/tab, cd to $cwd, and execute `bash -l $script`
#   - Escaping: wezterm cli spawn accepts $script as a direct argument (no shell
#     expansion), so no additional escaping is needed.
set -euo pipefail

cwd="$1"
script="$2"

wezterm cli spawn --cwd "$cwd" -- bash -l "$script"
