# Anki template

Themes **Anki** (23.10+ new-generation UI; native or Flatpak `net.ankiweb.Anki`)
with the active Noctalia palette.

## What gets themed

- All web views — deck picker, card browser, reviewer chrome, editor,
  overview/stats, add-on config — through Anki's own CSS custom-property set
  (`--canvas`, `--fg`, `--button-*`, `--flag-*`, `--state-*`, …). Anki
  generates every web surface from these variables, so no element-level
  overrides are needed and future Anki releases keep working as long as the
  variable set survives.
- Qt window chrome — menus, tooltips, dialogs, native scrollbars, status bar.
- No white flash on startup: web views get their background pre-painted with
  the canvas color.
- Not covered: the styling of the cards themselves (that belongs to each
  note type's Styling tab; deliberate — AnkiWeb syncs card CSS and a shell
  template must not rewrite users' decks).

## Entries

| Entry | What it does |
| --- | --- |
| `webcss` | Renders `noctalia-web.css` (the `:root` variable block) into the add-on dir. |
| `qtqss` | Renders `noctalia-qt.qss` (Qt chrome) into the add-on dir. |

## The companion add-on

Anki has **no built-in user stylesheet mechanism** — every theming path for
its web views requires code. This template therefore ships one deliberately
minimal add-on (`addon/__init__.py`, ~50 lines):

- reads `noctalia.qss` once at startup (`QApplication.setStyleSheet`)
- injects `noctalia.css` into each web view at content-set time
- **no timers, no file watching, no live reload** — after startup it runs
  nothing until the next web view is created

## How changes take effect

The template regenerates both files on every palette/theme change; Anki
picks them up **at its next start** (same lifecycle as the Firefox/Waterfox
userChrome templates). Disable the entries to remove the files; the
`undo_hook` also deletes the add-on.

## Prerequisites / setup

1. Anki installed and started at least once (the `Anki2` data dir must exist).
2. Nothing else. The add-on is enabled by Anki automatically (fresh
   `addons21` entries default to enabled). It can be turned off in
   Tools → Add-ons & Anki safe mode (Shift at launch) as usual.
3. Anki's own night mode is irrelevant: the variable block overrides both
   its light and dark declarations (`!important` + late injection).

## Generated / installed files

Per Anki data root (`~/.local/share/Anki2`,
`~/.var/app/net.ankiweb.Anki/data/Anki2`; override with `ANKI_ROOTS="d1:d2"`):

- `addons21/noctalia_theme/__init__.py` + `manifest.json` — copied by
  `install_addon.sh` (post_hook, idempotent; refuses to overwrite a foreign
  add-on with the same folder name)
- `addons21/noctalia_theme/noctalia.css` + `noctalia.qss` — rendered by the
  two entries

## Hook side effects

- `find_anki_dirs.sh` creates `addons21/noctalia_theme/` in detected data
  roots. Warns (`Warning:` banner in Settings) if Anki was never started.
- `install_addon.sh` only touches that one directory.
- `uninstall_addon.sh` (undo) removes the directory, but only after
  verifying its `__init__.py` carries the template marker.

## Tested against

- Noctalia v5.5.0
- Anki 26.09.4 (Flatpak, flathub)
