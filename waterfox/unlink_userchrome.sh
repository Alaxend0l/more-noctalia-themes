#!/usr/bin/env bash
# undo_hook: revert exactly what link_userchrome.sh added.
# - removes the two Noctalia @import lines from userChrome.css/userContent.css
# - deletes files we generated (empty leftover files are removed too)
# - deletes the generated noctalia-*.css files
# No-op when there is nothing to revert.
set -euo pipefail

roots=("$HOME/.waterfox" "$HOME/.var/app/net.waterfox.waterfox/.waterfox")
if [ -n "${WATERFOX_PROFILE_ROOTS:-}" ]; then
    IFS=: read -ra roots <<< "$WATERFOX_PROFILE_ROOTS"
fi

strip_imports() {
    local file="$1"
    [ -f "$file" ] || return 0
    local tmp
    tmp="$(mktemp "${file}.tmp.XXXXXX")"
    grep -vF -e '@import url("noctalia-userchrome.css");' \
             -e '@import url("noctalia-usercontent.css");' \
             -e '/* Managed by Noctalia: removes cleanly when the template is disabled. */' \
             "$file" >"$tmp" || true
    # if nothing but blank lines is left, the file was ours: drop it
    if [ -z "$(tr -d '[:space:]' <"$tmp")" ]; then
        rm -f "$file"
    else
        mv "$tmp" "$file"
        return 0
    fi
    rm -f "$tmp"
}

for root in "${roots[@]}"; do
    [ -d "$root" ] || continue
    shopt -s nullglob
    for profile in "$root"/*/ "$root"/profiles/*/; do
        [ -f "${profile}prefs.js" ] || continue
        rm -f "${profile}chrome/noctalia-userchrome.css" \
              "${profile}chrome/noctalia-usercontent.css"
        strip_imports "${profile}chrome/userChrome.css"
        strip_imports "${profile}chrome/userContent.css"
    done
done
exit 0
