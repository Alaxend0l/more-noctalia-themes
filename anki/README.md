# Anki template

Themes **Anki** (23.10+ new-generation UI; native or Flatpak `net.ankiweb.Anki`)
with the active Noctalia palette.

## What gets themed

Anki keeps **three independent colour layers**, and the template feeds all
of them:

1. **Anki's own colour roles** (`aqt.colors.*`, `{light, dark}` dicts).
   Anki generates its Qt application stylesheet, its QPalette, its themed
   toolbar icons and the custom-painted Cards/Notes switch from this table.
   `noctalia-colors.json` maps the Noctalia palette onto ~50 roles and the
   add-on copies the values in, so the *native Qt* parts (card browser
   table, sidebar tree, dialogs, menus) follow the palette.
2. **CSS custom properties for the web views** — deck picker, card browser
   chrome, reviewer chrome, editor, overview/stats, add-on config. Anki's
   bundled CSS defines its `--canvas`/`--fg`/`--button-*`/`--flag-*`/
   `--state-*` set and pages built on Bootstrap additionally read a
   `--bs-*` set; `noctalia-web.css` redefines both at `:root` with
   `!important`, so no element-level overrides are needed and future Anki
   releases keep working as long as the variable sets survive.
3. **Extra QSS** appended after Anki's own application stylesheet for the
   remaining Qt chrome (menus, tooltips, native scrollbars, item views).

- No white flash on startup: web views get their background pre-painted
  with the canvas color.
- Not covered (deliberate): the *content* of cards (that belongs to each
  note type's Styling tab; AnkiWeb syncs card CSS and a shell template must
  not rewrite users' decks). Anki itself appends its `.card` rule after the
  note type CSS, and that rule resolves to `--canvas`, so card backgrounds
  do follow the palette.
- Known limitation: a handful of Anki's toolbar icons are pre-rendered SVG
  assets inside the package (`_aqt/data/qt/icons/*-dark.svg`) with stock
  greys; they cannot follow an external palette.

## Entries

| Entry | What it does |
| --- | --- |
| `colorjson` | Renders `noctalia-colors.json` (Anki colour roles ← palette) into the add-on dir. |
| `webcss` | Renders `noctalia-web.css` (the `:root` variable block) into the add-on dir. |
| `qtqss` | Renders `noctalia-qt.qss` (Qt chrome) into the add-on dir. |

## The companion add-on

Anki has **no built-in user stylesheet mechanism** — every theming path for
its web views requires code. This template therefore ships one deliberately
minimal add-on (`addon/__init__.py`):

- copies the rendered colour roles into `aqt.colors` at import time and
  forces one style re-apply (see notes below)
- appends `noctalia.qss` to the application stylesheet and mirrors the
  palette into the QPalette
- injects `noctalia.css` into every web view (both web pipelines, see below)
- **no timers, no file watching, no live reload** — after startup it runs
  nothing until the next web view is created

## Implementation notes (verified against Anki 26.09.4)

- `aqt/main.py` calls `setupUI()` (whose `setupStyle()` does the first
  `apply_style()`) **before** `setupAddons()`, so add-on code is imported
  only after Anki has already built its stylesheet and palette. Patching
  the colour roles is not enough on its own; one extra `apply_style()` is
  needed. `apply_style()` returns early unless it thinks something changed,
  so the add-on sets `theme_manager._current_widget_style = None` (guarded
  with `hasattr`) before calling it.
- `gui_hooks.style_did_init` (filter) is where the QSS gets appended: Anki
  re-checks its theme every 300 s and rebuilds the stylesheet from scratch,
  so appending there (instead of only at startup) keeps the colors in
  effect across rebuilds. The QSS is appended, not substituted, so Anki's
  own widget styling (gradients, subcontrols) survives; its own generated
  styles also disappear once the roles are patched, because Anki generates
  them *from* the patched table.
- Anki has **two web content pipelines** and both must be covered:
  - legacy views (deck picker, toolbars, bottom bars, browser editor when
    the Svelte editor experiment is off) render via `stdHtml`. Hook
    `webview_will_set_content(web_content, context)` and prepend a `<style>`
    to `web_content.body`. The second hook argument is the *owning UI
    object* (`TopToolbar`, `DeckBrowser`, `Editor`, …), never a web view —
    calling `evalOnLoad` on it crashes Anki at startup with
    `AttributeError`.
  - new-style views (stats/graphs, preferences, deck options, card info,
    add/edit note) are served by Anki's internal media server and only
    expose `webview_did_inject_style_into_page`, which hands over the web
    view itself — a one-shot `eval()` injects the same `<style id="noctalia-css">`.
- The Bootstrap layer matters: Anki's bundled CSS paints `body` with
  `background-color: var(--bs-body-bg)` and sets dark values under
  `[data-bs-theme=dark]`; overriding only `--canvas` leaves stats/editor
  pages grey. `noctalia-web.css` overrides the `--bs-*` set too.
- The card browser table and sidebar are **native Qt** (`QTableView`), not
  a web view: they follow the patched colour roles via the generated QSS
  and the QPalette mirror. Our QSS repeats Anki's exact selectors
  (`QMenuBar{border-bottom}`, `QHeaderView::section:*`,
  `QTableView QTableCornerButton::section`) because it is appended later
  at equal specificity.
- `mw.app.themeManager` does not exist — use `from aqt.theme import
  theme_manager`.
- Pixel-verified in both Noctalia modes: app stylesheet contains the
  palette canvas and zero stock `#2c2c2c`/`#363636`/`#f5f5f5` declarations;
  Cards/Notes switch renders in the palette accent; deck picker, browser,
  stats and the card Previewer window (compositor window captures) render
  with palette colors only, apart from the pre-rendered icon SVGs above.

## How changes take effect

The template regenerates all three files on every palette/theme change; Anki
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
- `addons21/noctalia_theme/noctalia_colors.json` + `noctalia.css` +
  `noctalia.qss` — rendered by the three entries

## Hook side effects

- `find_anki_dirs.sh` creates `addons21/noctalia_theme/` in detected data
  roots. Warns (`Warning:` banner in Settings) if Anki was never started.
- `install_addon.sh` only touches that one directory.
- `uninstall_addon.sh` (undo) removes the directory, but only after
  verifying its `__init__.py` carries the template marker.

## Tested against

- Noctalia v5.5.0
- Anki 26.09.4 (Flatpak, flathub; ao / c06370ff, Python 3.13.16,
  Qt 6.11.3) — deck picker, card browser (sidebar + native Qt table),
  statistics window and the card Previewer window verified with compositor
  window captures in **both** dark and light Noctalia palettes: app
  stylesheet and QPalette contain only palette colors (0 stock
  `#2c2c2c`/`#363636`/`#f5f5f5` left), the Cards/Notes switch renders in
  the palette accent, flags/card-state icons use the terminal palette.
  Add-on loads with zero errors and injects into every web view of both
  pipelines.
