#!/usr/bin/env sh
# Bootstrap: gate the tmux version, load the layers, apply once.

set -eu

LAIN_DIR="${1:-}"
if [ -z "$LAIN_DIR" ] || [ ! -d "$LAIN_DIR" ]; then
	printf 'lain.tmux: plugin directory not passed or not readable\n' >&2
	exit 1
fi

lain_require_tmux() {
	_rt_v="$(tmux -V 2>/dev/null)"
	_rt_v="${_rt_v#tmux }"
	_rt_v="${_rt_v#next-}"
	_rt_major="${_rt_v%%.*}"
	_rt_rest="${_rt_v#*.}"

	_rt_minor=""
	while [ -n "$_rt_rest" ]; do
		case "$_rt_rest" in
		[0-9]*)
			_rt_minor="${_rt_minor}${_rt_rest%"${_rt_rest#?}"}"
			_rt_rest="${_rt_rest#?}"
			;;
		*) break ;;
		esac
	done

	case "$_rt_major" in
	'' | *[!0-9]*) return 0 ;;
	esac
	[ -n "$_rt_minor" ] || _rt_minor=0

	if [ "$_rt_major" -gt 3 ] ||
		{ [ "$_rt_major" -eq 3 ] && [ "$_rt_minor" -ge 4 ]; }; then
		return 0
	fi

	tmux display-message "lain.tmux: needs tmux 3.4 or newer (found $(tmux -V))"
	return 1
}

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

lain_daemon_launch
