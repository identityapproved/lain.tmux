# lain.tmux

A tmux theme in the lain palette: black ground, rose chrome, ochre accents.

Rose carries the interface - status text, the focused pane border. Ochre
carries content and selection - the active window, a copy-mode selection, a
search match. The two ramps never touch: they sit close in luminance, and rose
text on an ochre fill goes muddy.

Requires tmux 3.4 or newer.

## Install

With [TPM](https://github.com/tmux-plugins/tpm), in `tmux.conf`:

```tmux
set -g @plugin 'identityapproved/lain.tmux'
```

then `prefix + I`.

Manually, at the end of `tmux.conf`:

```tmux
run-shell ~/path/to/lain.tmux/lain.tmux
```

Either way it works with no further configuration.

### Truecolor

The lain ramps need 24-bit color. Without it the ochre and rose steps quantise
onto the same xterm pink band and stop being distinguishable - `#A49978` lands
on a rose, and `#C1B48E` and `#B5A985` collapse onto one index. Put this above
the plugin line:

```tmux
set -g default-terminal "tmux-256color"
set -as terminal-features "*:RGB"
```

## Modules

The bar is built from a list of modules per side, in the order you write them:

```tmux
set -g @lain_modules_left  "layer knights"
set -g @lain_modules_right "wired_path node present_day"
```

| Module | Shows | Notes |
| --- | --- | --- |
| `layer` | session name | Flips to `accent` while the prefix is pending. On by default. |
| `knights` | prefix indicator | Collapses to nothing at rest, so it costs no width. |
| `node` | hostname | `@lain_node_long` for the full name. |
| `wired_path` | current directory | Basename; `@lain_path_full` for the whole path. |
| `present_day` | date and clock | On by default. |
| `psyche` | one-minute load average | Polled. |
| `coolant` | battery charge | Polled. Absent on a machine with no battery. |
| `layer_git` | branch of the active pane's repo | Polled. Needs `git`. |
| `duvet` | now playing | Polled. Needs `playerctl`, or `nowplaying-cli` on macOS. |
| `accela` | network throughput | Polled. Down over up, sampled across one second. Linux only. |

An unknown name in either list is skipped rather than breaking the bar, and a
module whose dependency is missing removes itself.

## Static and polled modules

The bar never forks. Every static module compiles to a native tmux format, so
a redraw costs nothing no matter how often it happens or how many panes are
open.

Anything that genuinely needs a subprocess - a branch name, a battery reading -
is computed by one background process, once per `@lain_poll_interval`, and
written into a `@lain_cache_*` option. The bar reads the option. That is the
difference between one process per server and one shell spawned per segment per
redraw per pane.

A polled module removes itself from the bar while it has no value, so a new
session never flashes empty segments and a battery module on a desktop simply
never appears. When a value first arrives, or stops arriving, the daemon
rebuilds the bar; the values themselves update through the option and need no
rebuild.

The daemon exits on its own when the server does, and reloading the plugin will
not stack a second one - `prefix + I` is safe to press repeatedly.

## Separators

`@lain_separator` takes four values:

| Value | Look |
| --- | --- |
| `square` | Filled blocks, no glyph between. The default. |
| `powerline` | Filled blocks joined by a pointed glyph. Needs `@lain_glyphs nerd`. |
| `wire` | Flat text joined by a thin rule. |
| `none` | Flat text, nothing between. |

`@lain_glyphs` picks the icon set: `ascii` (default, no icons - guaranteed to
render anywhere), `unicode` (geometric shapes, no special font), or `nerd`
(icon font required). Font presence cannot be detected from inside tmux, so
this is a declaration, never a guess. `powerline` separators fall back to `>`
and `<` outside the `nerd` set.

## Options

Set any of these before the plugin loads.

| Option | Default | Meaning |
| --- | --- | --- |
| `@lain_status_position` | `bottom` | top or bottom |
| `@lain_status_interval` | `5` | seconds between redraws |
| `@lain_status_justify` | `left` | left, centre or right, for the window list |
| `@lain_separator` | `square` | square, powerline, wire or none |
| `@lain_transparent` | `off` | on drops the bar background to the terminal |
| `@lain_window_index` | `plain` | plain for 1:name, layer for LAYER:01 name |
| `@lain_glyphs` | `ascii` | ascii, unicode or nerd |
| `@lain_modules_left` | `layer` | modules on the left, in order |
| `@lain_modules_right` | `present_day` | modules on the right, in order |
| `@lain_show_prefix` | `on` | flip the session segment while the prefix is pending |
| `@lain_show_date` | `on` | show the date beside the clock |
| `@lain_prefix_text` | `PREFIX` | label for the knights module |
| `@lain_node_long` | `off` | on for the full hostname instead of the short one |
| `@lain_path_full` | `off` | on for the full path instead of the basename |
| `@lain_date_format` | `%Y-%m-%d` | strftime format for the date |
| `@lain_clock_format` | `%H:%M` | strftime format for the clock |
| `@lain_status_left_length` | `40` | character budget for the left segment |
| `@lain_status_right_length` | `60` | character budget for the right segment |
| `@lain_poll_interval` | `15` | seconds between background polls |
| `@lain_pane_border_status` | `off` | off, top or bottom, for per-pane labels |
| `@lain_debug` | `off` | keep the generated conf and report its path |

Reload after a change with `prefix + I` under TPM, or by re-sourcing
`tmux.conf`.

## Palette

Colors resolve through semantic tokens, never a raw hex. Each token is also
published as a tmux user option, so a custom `status-left` can stay on palette
without hardcoding anything:

```tmux
set -g status-left "#[fg=#{E:@lain_c_accent}] #S #[default]"
```

| Token | Hex | Role |
| --- | --- | --- |
| `@lain_c_bg_bar` | `#1A1A1A` | status bar background |
| `@lain_c_bg_active` | `#A49978` | active window fill, selection |
| `@lain_c_bg_surface` | `#2A2A2A` | popup and second surface |
| `@lain_c_fg_primary` | `#CE7688` | bar text, chrome |
| `@lain_c_fg_content` | `#A49978` | content and long-form text |
| `@lain_c_fg_on_active` | `#000000` | text on the ochre fill |
| `@lain_c_fg_dim` | `#968C6E` | inactive windows, metadata |
| `@lain_c_accent` | `#FFB1C3` | prefix pending, urgent |
| `@lain_c_alert` | `#930006` | alert fill |
| `@lain_c_rule` | `#7A7158` | wire separator |
| `@lain_c_border_active` | `#CE7688` | focused pane border |

Every pair the theme renders clears WCAG AA at 4.5:1. `tests/contrast.sh`
checks this and fails the suite if a change breaks it - the lain ramps are low
contrast by design, and that check is what keeps faithfulness from crossing
into unreadable.

## What it styles

The status bar and window list, plus the surfaces a theme usually forgets: pane
borders, pane indicators, messages and the command prompt, copy-mode selection
and search matches, marks, menus, popups, and the clock.

Window flags are color and glyph, never bold alone, since mono fonts vary too
much for weight to read reliably: `Z` zoomed, `!` bell, `~` activity, `M`
marked.

## Performance

No segment forks a shell. Every value on the bar is a native tmux format, so
`status-interval` can be as low as you like without spawning a process per
redraw per pane. Startup is a single `tmux show` for the whole option
namespace, and a single `source-file` for every style the plugin sets.

## Writing a module

A module is one file in `src/modules/` defining `lain_mod_<name>`, which
describes a segment and never emits format itself:

```sh
lain_mod_uptime() {
    mod_icon="clock"          # glyph key, or empty
    mod_text='#{host}'        # tmux format for the body
    mod_fg="$c_fg_on_active"  # text colour when filled
    mod_bg="$c_fg_content"    # fill colour, empty for a flat segment
    mod_attr="bold"           # defaults to nobold
    mod_gate=""               # condition; segment vanishes when false
}
```

Add the name to `LAIN_MODULES` in `src/registry.sh`. Return 1 to opt out.
Read colors as tokens, never as hex - `tests/palette.sh` enforces it.

A module that needs a subprocess sets `mod_dynamic` and defines a poller, and
must not fork anywhere else:

```sh
lain_mod_uptime() {
    mod_icon="clock"
    mod_deps="uptime"      # module removes itself if missing
    mod_dynamic="uptime"   # reads @lain_cache_uptime, absent while empty
    mod_fg="$c_fg_on_active"
    mod_bg="$c_fg_content"
}

lain_poll_uptime() { uptime | sed 's/.*up //; s/,.*//'; }
```

The daemon escapes `#` in whatever a poller prints, since a value containing
`#[fg=red]` would otherwise restyle the rest of the bar. Values are read with
`#{@lain_cache_x}` and never `#{E:...}`, so a branch named `#{session_name}`
stays text instead of being evaluated.

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) - washed-out colors,
missing glyphs, a module that never appears, and what to include when
reporting something else.

## Tests

```sh
tests/run.sh
```

`lint.sh` runs shellcheck and shfmt, `palette.sh` checks that no file outside
`palettes/` names a raw color, `contrast.sh` checks every rendered pair against
WCAG AA, `daemon.sh` covers value escaping and the poller's lifecycle, and
`smoke.sh` loads the plugin into a headless tmux on its own socket and asserts
the formats expand.

## Notes

Unofficial fan project. Not affiliated with, endorsed by, or connected to the
rights holders of Serial Experiments Lain. The code is MIT; no artwork, frames,
or logos are included or redistributed.
