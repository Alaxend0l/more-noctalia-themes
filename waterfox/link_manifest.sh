#!/usr/bin/env bash
# post_hook for the colors.json (Pywalfox) entry: copy the Noctalia-owned
# native-messaging manifest from ~/.mozilla (written by the firefox-theme
# post_action) into Waterfox's own native-messaging-hosts directory, which is
# where Waterfox - not Firefox - looks for hosts.
#
# Only meaningful for a NATIVE (non-Flatpak) Waterfox: a Flatpak sandbox
# cannot exec the host binary through the manifest path. If only a Flatpak
# install is detected we fail with a Warning shown in Noctalia Settings.
set -euo pipefail

manifest="pywalfox.json"
mozilla_dir="$HOME/.mozilla/native-messaging-hosts"
waterfox_host_dir="$HOME/.waterfox/native-messaging-hosts"

if [ ! -d "$HOME/.waterfox" ]; then
    if [ -d "$HOME/.var/app/net.waterfox.waterfox" ]; then
        echo "Warning: Waterfox is a Flatpak; the live Pywalfox route cannot reach the Noctalia host binary inside the sandbox. Disable this entry and use the userchrome entries instead (see waterfox/README.md)." >&2
    else
        echo "Warning: no native Waterfox installation found at ~/.waterfox; native-messaging manifest not copied." >&2
    fi
    exit 1
fi

# The firefox-theme post_action writes the manifest on first theme application;
# if it is not there yet, ask Noctalia to install it now.
if [ ! -f "$mozilla_dir/$manifest" ]; then
    noctalia firefox-theme install
fi
if [ ! -f "$mozilla_dir/$manifest" ]; then
    echo "Warning: Noctalia did not write $mozilla_dir/$manifest; re-apply the theme after the Pywalfox extension is installed." >&2
    exit 1
fi

# Never clobber a manifest owned by a different Pywalfox host.
if [ -f "$waterfox_host_dir/$manifest" ] \
        && ! grep -q '"path"[[:space:]]*:[[:space:]]*"[^"]*noctalia' "$waterfox_host_dir/$manifest"; then
    echo "Warning: $waterfox_host_dir/$manifest belongs to another host; not overwriting. Remove it manually to use Noctalia as the Pywalfox host." >&2
    exit 1
fi

mkdir -p "$waterfox_host_dir"
tmp="$waterfox_host_dir/$manifest.tmp.$$"
cp "$mozilla_dir/$manifest" "$tmp"
mv "$tmp" "$waterfox_host_dir/$manifest"
