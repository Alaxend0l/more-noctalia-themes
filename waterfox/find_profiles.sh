#!/usr/bin/env bash
# output_path_dynamic helper: prints one line per Waterfox profile chrome
# directory (creating the directory) for the given generated filename.
# Covers the native layout ($HOME/.waterfox/<profile>) and the Flatpak layout
# ($HOME/.var/app/net.waterfox.waterfox/.waterfox/<profile>).
#
# Usage: find_profiles.sh <generated-file-name>
# Override the roots with WATERFOX_PROFILE_ROOTS="dir1:dir2".
set -euo pipefail

generated_name="${1:?usage: find_profiles.sh <generated-file-name>}"

roots=("$HOME/.waterfox" "$HOME/.var/app/net.waterfox.waterfox/.waterfox")
if [ -n "${WATERFOX_PROFILE_ROOTS:-}" ]; then
    IFS=: read -ra roots <<< "$WATERFOX_PROFILE_ROOTS"
fi

found=0
for root in "${roots[@]}"; do
    [ -d "$root" ] || continue
    shopt -s nullglob
    for profile in "$root"/*/ "$root"/profiles/*/; do
        # a profile directory is any directory holding prefs.js
        [ -f "${profile}prefs.js" ] || continue
        mkdir -p "${profile}chrome"
        echo "${profile}chrome/${generated_name}"
        found=1
    done
done

if [ "$found" -ne 1 ]; then
    echo "Warning: no Waterfox profile found (checked: ${roots[*]})." \
         "Start Waterfox once, or set WATERFOX_PROFILE_ROOTS." >&2
    exit 1
fi
