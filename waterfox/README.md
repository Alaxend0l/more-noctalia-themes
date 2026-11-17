# Waterfox template

Themes **Waterfox** (G6+ and Waterfox 6.x, native or Flatpak) with the active
Noctalia palette.

## What gets themed

- Browser chrome: window, toolbars, tabs, urlbar/searchbar, panels (app menu,
  downloads, autocomplete), sidebar, in-content form controls.
- Content pages: `about:newtab`, `about:home`, `about:privatebrowsing`
  (through their theme variables).
- Not covered: `about:preferences` / `about:addons` content areas (privileged
  pages that ignore userContent; they mostly follow the chrome variables
  already overridden in `noctalia-userchrome.css`).

## Entries

| Entry | What it does |
| --- | --- |
| `userchrome` | Renders `noctalia-userchrome.css` into every profile's `chrome/` dir and `@import`s it from `userChrome.css`. |
| `usercontent` | Same for `noctalia-usercontent.css` / `userContent.css`. |
| `colors` | Writes pywal-compatible `$XDG_CACHE_HOME/wal/colors.json` and uses Noctalia as the Pywalfox native-messaging host (live updates). **Native Waterfox only** — see below. |

## Prerequisites / setup

1. Waterfox installed and started at least once (a profile must exist).
2. In Waterfox, open `about:config` and set
   `toolkit.legacyUserProfileCustomizations.stylesheets` → `true`, then
   restart Waterfox. Until this is set the hook reports a `Warning:` in
   Noctalia Settings.
3. **Live route only:** install the
   [Pywalfox](https://addons.mozilla.org/en-US/firefox/addon/pywalfox/)
   extension and disable the `userchrome`/`usercontent` entries (enabling
   both is harmless but redundant).

## Flatpak note

For a **Flatpak** Waterfox (`net.waterfox.waterfox`) only the static route
works: the Pywalfox native-messaging host binary lives outside the sandbox,
so the `colors` entry deliberately bails with a `Warning:`. Profiles are still
found at `~/.var/app/net.waterfox.waterfox/.waterfox/*/chrome/`.

## Generated files

- `~/.waterfox/<profile>/chrome/noctalia-userchrome.css` (and the Flatpak
  equivalent)
- `~/.waterfox/<profile>/chrome/noctalia-usercontent.css`
- `~/.waterfox/<profile>/chrome/userChrome.css` / `userContent.css` — created
  if missing, otherwise one `@import` line each is appended (idempotent)
- `$XDG_CACHE_HOME/wal/colors.json` (colors entry; same path the community
  `pywalfox` template writes — enable only one of the two per machine)
- `~/.waterfox/native-messaging-hosts/pywalfox.json` (colors entry; copied
  from the Noctalia-owned `~/.mozilla` manifest)

## How changes take effect

The template re-renders on every palette/theme change. userChrome/userContent
are read **at browser start**, so restart Waterfox to see new colors. The
`colors` entry pushes updates live through the Pywalfox extension (native
Waterfox only; restart Firefox/Waterfox once after the manifest first appears).

## Hook side effects

- `find_profiles.sh` only creates `chrome/` directories inside detected
  profiles. Profile roots: `~/.waterfox` and
  `~/.var/app/net.waterfox.waterfox/.waterfox`; override with
  `WATERFOX_PROFILE_ROOTS="dir1:dir2"`.
- `link_userchrome.sh` appends at most one `@import` line per generated file
  per profile; it never rewrites the rest of your `userChrome.css`.
- `unlink_userchrome.sh` (undo) removes the `@import` lines and the generated
  `noctalia-*.css` files; it also removes a `userChrome.css`/`userContent.css`
  only when it contained nothing but the Noctalia import.
- `link_manifest.sh` runs `noctalia firefox-theme install` if noctalia's
  `~/.mozilla` manifest is missing, then copies it into Waterfox's host dir.
  It refuses to overwrite a manifest owned by another Pywalfox host.

## Tested against

- Noctalia v5.5.0
- Waterfox 6.7.8 (Flatpak, flathub)
