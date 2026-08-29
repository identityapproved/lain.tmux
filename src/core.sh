#!/usr/bin/env sh
# Bootstrap. Gate the tmux version, load the layers, apply once.
set -eu

LAIN_DIR="${1:-}"
if [ -z "$LAIN_DIR" ] || [ ! -d "$LAIN_DIR" ]; then
	printf 'lain.tmux: plugin directory not passed or not readable\n' >&2
	exit 1
fi

# 3.4 is the floor. Below it the menu, popup and copy-mode style options this
# theme sets do not all exist, and half-applying would leave a session with
# tmux's defaults showing through in exactly the places a theme is meant to
# cover. Fail loudly instead.
lain_require_tmux() {
	if ! tmux -V 2>/dev/null | awk '
		{ gsub(/^tmux |^next-/, ""); split($0, v, "."); }
		{ exit !(v[1] + 0 > 3 || (v[1] + 0 == 3 && v[2] + 0 >= 4)) }
	'; then
		tmux display-message "lain.tmux: needs tmux 3.4 or newer (found $(tmux -V))"
		return 1
	fi
	return 0
}

# Field delimiter for the segment accumulator in status.sh. US (0x1f) because
# it is not IFS whitespace, so an empty leading field survives `read`.
LAIN_US="$(printf '\037')"

lain_require_tmux || exit 1

# shellcheck source=src/options.sh
. "$LAIN_DIR/src/options.sh"
# shellcheck source=palettes/lain.sh
. "$LAIN_DIR/palettes/lain.sh"
# shellcheck source=src/palette.sh
. "$LAIN_DIR/src/palette.sh"
# shellcheck source=src/glyphs.sh
. "$LAIN_DIR/src/glyphs.sh"
# shellcheck source=src/registry.sh
. "$LAIN_DIR/src/registry.sh"
# shellcheck source=src/cache.sh
. "$LAIN_DIR/src/cache.sh"
# shellcheck source=src/status.sh
. "$LAIN_DIR/src/status.sh"
# shellcheck source=src/window.sh
. "$LAIN_DIR/src/window.sh"
# shellcheck source=src/surfaces.sh
. "$LAIN_DIR/src/surfaces.sh"

lain_opts_init
lain_out_init
lain_palette_init
lain_glyphs_init
lain_modules_load

lain_palette_apply
lain_status_apply
lain_window_apply
lain_surfaces_apply
lain_daemon_start

lain_flush

# After the flush, so the daemon finds @lain_daemon_id and its plan already
# set. Launching before would race the options it reads on its first tick.
lain_daemon_launch
