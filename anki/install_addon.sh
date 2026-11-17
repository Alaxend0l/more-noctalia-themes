#!/usr/bin/env bash
# post_hook: install/refresh the minimal companion add-on files
# (addon/__init__.py + manifest.json) into every detected Anki data root.
# Idempotent. Refuses to touch an existing foreign noctalia_theme dir.
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)/addon"
[ -f "$src/__init__.py" ] || { echo "Warning: addon sources missing at $src." >&2; exit 1; }

roots=("$HOME/.local/share/Anki2" "$HOME/.var/app/net.ankiweb.Anki/data/Anki2")
if [ -n "${ANKI_ROOTS:-}" ]; then
    IFS=: read -ra roots <<< "$ANKI_ROOTS"
fi

found=0
for root in "${roots[@]}"; do
    [ -d "$root" ] || continue
    found=1
    dir="$root/addons21/noctalia_theme"
    mkdir -p "$dir"
    if [ -f "$dir/__init__.py" ] \
            && ! grep -q "Noctalia theme for Anki" "$dir/__init__.py"; then
        echo "Warning: $dir/__init__.py is not from this template; not overwriting." >&2
        continue
    fi
    cp -f "$src/__init__.py" "$src/manifest.json" "$dir/"
done

if [ "$found" -ne 1 ]; then
    echo "Warning: no Anki data directory found; add-on not installed. Start Anki once and re-apply the theme." >&2
    exit 1
fi
