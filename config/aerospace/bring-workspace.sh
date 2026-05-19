#!/bin/bash
# bring-workspace.sh — AeroSpace equivalent of your i3 switch-workspace.py
#
# Usage: bring-workspace.sh <workspace-number>
#
# Behavior: switches focus to workspace N, ensures it's on the monitor that
# was focused when you pressed the keybind, then refocuses it.
#
# i3 original (switch-workspace.py):
#   - Get the currently focused output
#   - workspace N; move workspace to output <focused>; workspace N
#
# AeroSpace mapping:
#   - aerospace list-monitors --focused -> current monitor id
#   - aerospace workspace N -> switch to N (focus jumps to wherever it lives)
#   - aerospace move-workspace-to-monitor <id> -> drag it to where we were
#   - aerospace workspace N -> ensure focus is on it

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <workspace-number>" >&2
    exit 1
fi

target_ws="$1"

# Capture the currently focused monitor BEFORE we switch workspaces.
current_monitor_id=$(aerospace list-monitors --focused | awk '{print $1}' | tr -d ':')

# Switch to the target workspace (focus may jump to another monitor here).
aerospace workspace "$target_ws"

# Drag that workspace back to the monitor we were on.
aerospace move-workspace-to-monitor "$current_monitor_id"

# Refocus, just in case.
aerospace workspace "$target_ws"
