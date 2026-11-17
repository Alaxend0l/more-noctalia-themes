# Kdenlive

Brings the parts of [Kdenlive](https://kdenlive.org) that ignore the desktop
palette into the active Noctalia theme: timeline clip tints, audio waveforms,
monitor overlay guides, the GL monitor backdrop, and Kdenlive's own color-scheme
override.

## What gets themed, and what deliberately doesn't

Themed (Kdenlive's own `Color` config entries, group/key as written to
`kdenliverc`):

| Key | Surface |
| --- | --- |
| `[unmanaged] videoColor/audioColor/titleColor/imageColor/slideshowColor` | timeline clip tints (semi-transparent `#AARRGGBB` tints over the track background, Kdenlive's own alpha convention) |
| `[unmanaged] thumbColor1/thumbColor2` | even/odd audio waveform channels |
| `[unmanaged] colorclipcolor` | preselected color in the "Add Color Clip" dialog |
| `[unmanaged] overlayColor` | monitor overlay guides |
| `[sdl] window_background` | backdrop around the frame in the monitors |
| `[UiSettings] ColorScheme` | pins the app's color scheme to the built-in `noctalia` KColorScheme (otherwise a stale value like `BreezeDark` wins over the global scheme) |

Deliberately left alone: guide categories and bin tag colors (user data that
happens to be colored, like terminal ANSI colors elsewhere), the clip monitor's
black backdrop and safe-zone colors (video-critical references), playhead and
track backgrounds (already KColorScheme-driven).

## Prerequisite: the built-in KColorScheme template

Kdenlive's widget chrome and the rest of its timeline (rulers, track heads,
playhead, panels) follow KColorScheme. Enable **Settings → Templates →
KColorScheme** (built-in) so `~/.local/share/color-schemes/noctalia.colors`
exists; this template then points Kdenlive's `[UiSettings] ColorScheme` at it
and warns (in Settings) if it is missing.

## Entries

| Entry | What it does |
| --- | --- |
| `kdenlive` | Native install. Renders the color spec to `~/.cache/noctalia/kdenlive/colors.conf` and pushes it into `~/.config/kdenliverc`. |
| `kdenlive-flatpak` | Same, gated on `~/.var/app/org.kde.kdenlive/config/kdenliverc` existing. `apply.sh` detects both installs and writes each one, so enabling both is harmless. |

## Hook side effects

- `apply.sh` writes **only** the table-listed keys into each `kdenliverc`, via
  KDE's own `kwriteconfig6 --notify` — the same path the Configure Kdenlive
  dialogs use internally. No injection: no add-on, no watcher, nothing else on
  disk beyond the render spec in `~/.cache/noctalia/`.
- The rest of `kdenliverc` (window layout, recents, paths) is never rewritten,
  which is why `kdenliverc` cannot be an `output_path`.
- `undo.sh` deletes exactly those keys (so Kdenlive reverts to its own
  palette-derived defaults) and removes the cache bookkeeping. To restore a
  hand-picked scheme, re-select it under Configure Kdenlive → Appearance.
- Keep the `keys=()` list in `undo.sh` in sync with `noctalia-colors.conf`.

## Caveats

- **Apply while Kdenlive is closed.** A running Kdenlive rewrites
  `kdenliverc` on exit and drops what was written in the meantime; the next
  theme change re-applies it. `--notify` live-reloads the parts it can.
- **Existing projects keep their own clip colors.** Color rows saved inside a
  `.kdenlive` file override these global defaults; retint such a project via
  Project Settings → Color Rows, or start a new one.
- The scheme pin is skipped (with a Settings warning) while the built-in
  KColorScheme template is off; clip/overlay colors still apply.

## Testing locally

Append to `~/.config/noctalia/config.toml` (user entries have no `undo_hook`;
clean up with `bash kdenlive/undo.sh`):

```toml
[theme.templates.user.kdenlive]
input_path    = "/path/to/more-noctalia-themes/kdenlive/noctalia-colors.conf"
output_path   = "$XDG_CACHE_HOME/noctalia/kdenlive/colors.conf"
post_hook     = "bash /path/to/more-noctalia-themes/kdenlive/apply.sh"
hook_async    = false
```

Then re-apply the theme (Settings → Media & UI → Theme) and check with
`noctalia theme --list-templates` and `kreadconfig6 --file kdenliverc --group
unmanaged --key videoColor`.

## Tested against

- Noctalia v5.5.0
- Kdenlive 26.08.3 (native)
