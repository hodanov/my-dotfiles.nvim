#!/bin/bash
# WezTerm launcher for ai-bridge
# Usage: wezterm.sh <cwd> <script_file>
set -euo pipefail

cwd="$1"
script="$2"

wezterm cli spawn --cwd "$cwd" -- bash -l "$script"
