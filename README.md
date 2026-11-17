# More Noctalia themes

Working copies of Noctalia app templates that aren't in
[`noctalia-dev/community-templates`](https://github.com/noctalia-dev/community-templates)
yet, laid out so they can be PR'd upstream unchanged.

| Dir | App | Status |
| --- | --- | --- |
| `waterfox/` | Waterfox (Firefox fork) | verified working (6.7.8 flatpak) |
| `anki/` | Anki (23.10+ UI) | first cut, pending visual verification |

## Test locally as user templates

User templates let you render straight from this working copy — no fork, no
PR. Append the blocks from [`test-user-templates.toml`](test-user-templates.toml)
to `~/.config/noctalia/config.toml` (or `~/.config/noctalia/templates.toml`),
then verify Noctalia sees them:

```sh
noctalia theme --list-templates
```

Re-apply the current theme from **Settings → Media & UI → Theme** (or change
the theme) and check the generated files + hooks.

Note: in *user* templates `{{ config_dir }}` is the Noctalia config directory,
not the template folder — the test blocks therefore use absolute paths.

## Smoke-test rendering without touching your shell config

```sh
noctalia theme ~/Pictures/some-wallpaper.png \
  -r waterfox/noctalia-userchrome.css:/tmp/opencode/out-userchrome.css \
  -r waterfox/colors.json:/tmp/opencode/out-colors.json
grep -c '{{' /tmp/opencode/out-userchrome.css   # expect 0: all tokens rendered
```

## Submitting upstream

Follow the community repo's rules: one app per PR, `template.toml` + input
files + hooks + `README.md` already match the required layout; add dark and
light screenshots and the app version tested against.
