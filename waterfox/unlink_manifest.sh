#!/usr/bin/env bash
# undo_hook for the colors.json entry: remove only the manifest this template
# copied into Waterfox's host directory (i.e. one whose path points at
# noctalia). No-op otherwise.
set -euo pipefail

manifest="$HOME/.waterfox/native-messaging-hosts/pywalfox.json"

if [ -f "$manifest" ] && grep -q '"path"[[:space:]]*:[[:space:]]*"[^"]*noctalia' "$manifest"; then
    rm -f "$manifest"
fi
exit 0
