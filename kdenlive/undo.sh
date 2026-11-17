#!/usr/bin/env bash
# undo_hook: remove exactly what apply.sh sets. Every key below is deleted
# from each kdenliverc found, so Kdenlive falls back to its own palette-based
# defaults; the [UiSettings] ColorScheme pin is removed the same way (to get
# a previous hand-picked scheme back, re-select it in Configure Kdenlive ->
# Appearance, or in the global color settings). Hardcoded on purpose: the
# list must match noctalia-colors.conf and stay reviewable, and undo must
# work even if the rendered spec is already gone.
#
# Idempotent: deleting absent keys is a no-op, so this exits 0 when there is
# nothing to undo.
set -euo pipefail

# "<group> <key>" pairs, kept in sync with noctalia-colors.conf
keys=(
    "unmanaged videoColor"
    "unmanaged audioColor"
    "unmanaged titleColor"
    "unmanaged imageColor"
    "unmanaged slideshowColor"
    "unmanaged colorclipcolor"
    "unmanaged thumbColor1"
    "unmanaged thumbColor2"
    "unmanaged overlayColor"
    "sdl window_background"
    "UiSettings ColorScheme"
)

KWRITE="$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)"

# The scheme pin is ours only while the built-in KColorScheme scheme exists
# (apply.sh skips it otherwise). No scheme file means the current
# [UiSettings] ColorScheme value is the user's own — leave it untouched.
scheme_file="${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes/noctalia.colors"

targets=()
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/kdenliverc" ]; then
    targets+=("${XDG_CONFIG_HOME:-$HOME/.config}/kdenliverc")
fi
if [ -f "$HOME/.var/app/org.kde.kdenlive/config/kdenliverc" ]; then
    targets+=("$HOME/.var/app/org.kde.kdenlive/config/kdenliverc")
fi

if [ "${#targets[@]}" -eq 0 ]; then
    exit 0    # nothing installed: nothing to revert
fi
if [ -z "$KWRITE" ]; then
    echo "Warning: kwriteconfig6/kwriteconfig5 not found; cannot clean kdenliverc." >&2
    exit 1
fi

for pair in "${keys[@]}"; do
    group="${pair%% *}"
    key="${pair#* }"
    if [ "$group" = 'UiSettings' ] && [ "$key" = 'ColorScheme' ] && [ ! -f "$scheme_file" ]; then
        continue
    fi
    for target in "${targets[@]}"; do
        "$KWRITE" --file "$target" --group "$group" --key "$key" --delete --notify
    done
done

# drop the render bookkeeping too
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/kdenlive"
exit 0
