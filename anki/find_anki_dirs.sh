#!/usr/bin/env bash
# output_path_dynamic helper: prints one line per Anki add-on directory for
# the given generated filename, creating the directory. Covers the native
# layout ($HOME/.local/share/Anki2) and the Flatpak layout
# ($HOME/.var/app/net.ankiweb.Anki/data/Anki2). addons21 is shared by all
# profiles, so one path per Anki data root is enough.
#
# Usage: find_anki_dirs.sh <generated-file-name>
# Override the roots with ANKI_ROOTS="dir1:dir2".
set -euo pipefail

generated_name="${1:?usage: find_anki_dirs.sh <generated-file-name>}"

roots=("$HOME/.local/share/Anki2" "$HOME/.var/app/net.ankiweb.Anki/data/Anki2")
if [ -n "${ANKI_ROOTS:-}" ]; then
    IFS=: read -ra roots <<< "$ANKI_ROOTS"
fi

found=0
for root in "${roots[@]}"; do
    [ -d "$root" ] || continue
    mkdir -p "$root/addons21/noctalia_theme"
    echo "$root/addons21/noctalia_theme/$generated_name"
    found=1
done

if [ "$found" -ne 1 ]; then
    echo "Warning: no Anki data directory found (checked: ${roots[*]}). " \
         "Start Anki once, or set ANKI_ROOTS." >&2
    exit 1
fi
