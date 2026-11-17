#!/usr/bin/env bash
# post_hook: push the rendered color spec into every Kdenlive config found.
#
# The spec was just written by Noctalia to
# ${XDG_CACHE_HOME:-~/.cache}/noctalia/kdenlive/colors.conf; each line is
# "<group> <key> <value>" ('#' lines are comments). Every entry is applied
# in place with KDE's own kwriteconfig6 --notify, which is exactly what the
# Configure Kdenlive dialogs do internally: the rest of kdenliverc (window
# layout, recent files, ...) is never touched, and --notify asks a running
# Kdenlive to reload what it can.
#
# Nothing is injected into Kdenlive and nothing persistent is written
# outside kdenliverc itself. Idempotent: re-running just rewrites the same
# keys.
set -euo pipefail

SPEC="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/kdenlive/colors.conf"

KWRITE="$(command -v kwriteconfig6 || command -v kwriteconfig5 || true)"
if [ -z "$KWRITE" ]; then
    echo "Warning: kwriteconfig6/kwriteconfig5 not found; cannot edit kdenliverc." >&2
    exit 1
fi
if [ ! -f "$SPEC" ]; then
    echo "Warning: rendered spec missing at $SPEC; nothing applied." >&2
    exit 1
fi

targets=()
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/kdenliverc" ]; then
    targets+=("${XDG_CONFIG_HOME:-$HOME/.config}/kdenliverc")
fi
if [ -f "$HOME/.var/app/org.kde.kdenlive/config/kdenliverc" ]; then
    targets+=("$HOME/.var/app/org.kde.kdenlive/config/kdenliverc")
fi
if [ "${#targets[@]}" -eq 0 ]; then
    echo "Warning: no kdenliverc found (checked native and Flatpak config dirs);" \
         "start Kdenlive once, then re-apply the theme." >&2
    exit 1
fi

# [UiSettings] ColorScheme=noctalia only makes sense while the built-in
# KColorScheme template's scheme exists; skip the pin (with a Settings
# warning) instead of leaving kdenlive pointed at a missing scheme.
scheme_file="${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes/noctalia.colors"

while read -r group key value _; do
    case "$group" in ''|'#'*) continue ;; esac
    if [ "$group" = 'UiSettings' ] && [ "$key" = 'ColorScheme' ] && [ ! -f "$scheme_file" ]; then
        echo "Warning: $scheme_file missing; skipped the [UiSettings]" \
             "ColorScheme pin. Enable Noctalia's built-in KColorScheme" \
             "template to theme Kdenlive's widget chrome." >&2
        continue
    fi
    for target in "${targets[@]}"; do
        "$KWRITE" --file "$target" --group "$group" --key "$key" --notify "$value"
    done
done < "$SPEC"
