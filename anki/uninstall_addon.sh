#!/usr/bin/env bash
# undo_hook: remove the noctalia_theme add-on directory installed by this
# template (add-on files + generated noctalia.css/noctalia.qss). Only
# removes directories that carry our add-on marker, never a foreign one.
set -euo pipefail

roots=("$HOME/.local/share/Anki2" "$HOME/.var/app/net.ankiweb.Anki/data/Anki2")
if [ -n "${ANKI_ROOTS:-}" ]; then
    IFS=: read -ra roots <<< "$ANKI_ROOTS"
fi

for root in "${roots[@]}"; do
    dir="$root/addons21/noctalia_theme"
    [ -d "$dir" ] || continue
    if [ -f "$dir/__init__.py" ] \
            && ! grep -q "Noctalia theme for Anki" "$dir/__init__.py"; then
        echo "Warning: $dir/__init__.py is not from this template; left in place." >&2
        continue
    fi
    rm -rf "$dir"
done
exit 0
