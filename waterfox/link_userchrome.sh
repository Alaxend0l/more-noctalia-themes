#!/usr/bin/env bash
# post_hook: wire the generated Noctalia styles into each profile's
# userChrome.css / userContent.css with @import lines. Idempotent: re-running
# never duplicates an import. Creates the two files when a profile has none.
set -euo pipefail

roots=("$HOME/.waterfox" "$HOME/.var/app/net.waterfox.waterfox/.waterfox")
if [ -n "${WATERFOX_PROFILE_ROOTS:-}" ]; then
    IFS=: read -ra roots <<< "$WATERFOX_PROFILE_ROOTS"
fi

found=0
flag_missing=0

ensure_import() {
    local file="$1" name="$2"
    if [ ! -f "$file" ]; then
        {
            echo "/* Managed by Noctalia: removes cleanly when the template is disabled. */"
            printf '@import url("%s");\n' "$name"
        } >"$file"
        return
    fi
    if ! grep -qF "@import url(\"${name}\")" "$file"; then
        # append, keeping the file newline-terminated
        [ -s "$file" ] && [ -n "$(tail -c1 "$file")" ] && echo >>"$file"
        printf '@import url("%s");\n' "$name" >>"$file"
    fi
}

for root in "${roots[@]}"; do
    [ -d "$root" ] || continue
    shopt -s nullglob
    for profile in "$root"/*/ "$root"/profiles/*/; do
        [ -f "${profile}prefs.js" ] || continue
        found=1
        ensure_import "${profile}chrome/userChrome.css" "noctalia-userchrome.css"
        ensure_import "${profile}chrome/userContent.css" "noctalia-usercontent.css"
        if ! grep -q 'toolkit.legacyUserProfileCustomizations.stylesheets.*true' \
                "${profile}prefs.js" 2>/dev/null; then
            flag_missing=1
        fi
    done
done

if [ "$found" -ne 1 ]; then
    echo "Warning: no Waterfox profile found; userChrome imports skipped." >&2
    exit 1
fi

if [ "$flag_missing" -eq 1 ]; then
    echo "Warning: Waterfox needs about:config -> toolkit.legacyUserProfileCustomizations.stylesheets = true (then restart Waterfox) before the Noctalia theme shows." >&2
    exit 1
fi
