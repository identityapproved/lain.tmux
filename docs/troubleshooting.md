# Troubleshooting

## The colors look washed out, pink, or all the same

The palette is three close ramps, and without 24-bit color the ochre and rose
steps quantise onto the same xterm band: `#A49978` lands on a rose, and
`#C1B48E` and `#B5A985` collapse onto one index. Distinct roles stop being
distinct.

Put this above the plugin line in `tmux.conf`:

```tmux
set -g default-terminal "tmux-256color"
set -as terminal-features "*:RGB"
```

Check it took, from a pane inside tmux (it reports the attached client, so it
is empty when run against a detached session):

```sh
tmux display-message -p '#{client_termfeatures}'
```

`RGB` should appear in the list. If it does not, the outer terminal may not be
advertising truecolor either - check `$COLORTERM` is `truecolor` or `24bit`.

## Boxes, blank gaps, or question marks instead of icons

`@lain_glyphs` is set to `nerd` or `unicode` and the font cannot render those
codepoints. Font presence cannot be detected from inside tmux, so the plugin
believes what you tell it.

```tmux
set -g @lain_glyphs "ascii"
```

`ascii` is the default and draws no icons at all. `unicode` needs only common
geometric shapes. `nerd` needs a patched font.

`powerline` separators are the same story: outside the `nerd` set they fall
back to `>` and `<`, which is legible but not what the screenshots show.

## The plugin does not load

```sh
tmux display-message -p '#{version}'
```

Below 3.4 it refuses on purpose and says so. A theme that half-applies leaves
tmux's defaults showing through in exactly the places a theme exists to cover,
which is worse than not loading.

Otherwise, run it by hand and read the error:

```sh
tmux run-shell ~/.tmux/plugins/lain.tmux/lain.tmux
```

## Nothing changed after editing an option

Options are read once, at load. Reload with `prefix + I` under TPM, or:

```sh
tmux source-file ~/.tmux.conf
```

Set options *before* the plugin loads. A `set -g @lain_*` line placed after the
`run-shell` line has no effect until the next reload.

## A module is missing from the bar

In order of likelihood:

- It is not in `@lain_modules_left` or `@lain_modules_right`. Adding a module
  to one list does not remove it from the defaults; write the whole list.
- The name is misspelled. Unknown names are skipped rather than breaking the
  bar, which is deliberate but does hide typos.
- Its dependency is missing - `layer_git` needs `git`.
- It is polled and has no value yet, or never will. `coolant` on a machine with
  no battery never appears. See below.

## A polled module never appears

Polled modules remove themselves while their cache is empty, so nothing shows
until the first successful poll - up to `@lain_poll_interval` seconds.

Check the daemon is alive and writing:

```sh
tmux show -g | grep @lain_daemon
tmux show -g | grep @lain_cache
```

`@lain_daemon_beat` is a unix timestamp from the last poll. If it is stale by
more than three intervals, the next plugin load starts a fresh daemon; there is
no PID to clear.

Run the poller by hand to see its error:

```sh
LAIN_DIR=~/.tmux/plugins/lain.tmux sh -c '
  . "$LAIN_DIR/src/registry.sh"; lain_modules_load; lain_poll_layer_git'
```

`lain_modules_load` reads `$LAIN_DIR`, so it has to be set.

## The status bar feels slow

It should not: no segment forks a shell, so `status-interval` costs nothing per
redraw regardless of pane count. If the bar is janky, something else in your
`tmux.conf` is likely running `#()`.

Startup is a different budget - it runs on every session create and reload.
`tests/bench.sh` measures it and fails over a ceiling.

## Colors are wrong after I changed the palette

`tests/contrast.sh` checks every rendered pair against WCAG AA and
`tests/snapshot.sh` diffs the drawn bar against golden files. Run both:

```sh
tests/run.sh
```

If a snapshot difference is intended, regenerate:

```sh
tests/snapshot.sh --update
```

Review that diff before committing it - it is the record of what the bar
actually looks like.

## Reporting something else

Include `tmux -V`, the terminal, and:

```sh
tmux show -g | grep @lain_
```

`set -g @lain_debug on` keeps the generated conf file and reports its path, so
you can read every style the plugin applied as one file.
