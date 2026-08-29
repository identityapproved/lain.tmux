#!/usr/bin/env sh
# Golden-file snapshots of the drawn status line.
#
# Everything else checks structure - that a format expands, that a colour pair
# clears AA. This checks what is actually painted, escape by escape, which is
# the only thing that catches a colour landing one ramp step off or a separator
# losing its background.
#
# `capture-pane` cannot see a status line, and a headless server has no client
# to draw one. So the session under test is attached inside a pane of a second
# server, and the outer one is captured: the inner status line is the last row.
#
#   tests/snapshot.sh            check against tests/golden/
#   tests/snapshot.sh --update   regenerate them
set -eu

cd "$(dirname "$0")/.."
PLUGIN_DIR="$(pwd)"
GOLDEN="tests/golden"
UPDATE="${1:-}"
WIDTH=100
HEIGHT=12

fail=0
updated=0

# Anything that varies by machine or by minute is excluded rather than filtered:
# the clock and date are set to literal words, `node` is left out because the
# hostname differs everywhere, window names are pinned, and the working
# directory is fixed so the path basename is stable. A snapshot that needs
# scrubbing is a snapshot that will rot.
snap() {
	name="$1"
	shift

	inner="lain-snap-i-$$"
	outer="lain-snap-o-$$"
	tmux -L "$inner" -f /dev/null new-session -d -s wired -n main \
		-x "$WIDTH" -y "$HEIGHT" -c /tmp
	tmux -L "$inner" set -as terminal-features "*:RGB"
	# Without this the window name follows whatever the shell is running at the
	# moment of capture - `zsh` or `tmux` depending on timing - and the
	# snapshots flap.
	tmux -L "$inner" set -g automatic-rename off
	tmux -L "$inner" set -g @lain_clock_format "CLOCK"
	tmux -L "$inner" set -g @lain_date_format "DATE"
	for kv in "$@"; do
		tmux -L "$inner" set -g "${kv%%=*}" "${kv#*=}"
	done
	[ "$name" = "windows" ] && _snap_windows "$inner"
	tmux -L "$inner" run-shell "$PLUGIN_DIR/lain.tmux"

	tmux -L "$outer" -f /dev/null new-session -d -x "$WIDTH" -y "$((HEIGHT + 2))" \
		"tmux -L $inner attach -t wired"
	sleep 1
	got="$(tmux -L "$outer" capture-pane -p -e -S -1 | tail -1 | sed 's/\033/\\e/g')"

	tmux -L "$inner" kill-server 2>/dev/null || true
	tmux -L "$outer" kill-server 2>/dev/null || true
	rm -f "/tmp/tmux-$(id -u)/$inner" "/tmp/tmux-$(id -u)/$outer"

	file="$GOLDEN/$name.ansi"
	if [ "$UPDATE" = "--update" ]; then
		printf '%s\n' "$got" >"$file"
		printf 'updated  %s\n' "$name"
		updated=$((updated + 1))
		return 0
	fi

	if [ ! -f "$file" ]; then
		printf 'FAIL     %s has no golden file; run tests/snapshot.sh --update\n' "$name"
		fail=1
		return 0
	fi
	if [ "$got" = "$(cat "$file")" ]; then
		printf 'ok       %s\n' "$name"
	else
		printf 'FAIL     %s\n' "$name"
		printf '  want:  %s\n' "$(cat "$file")"
		printf '  got:   %s\n' "$got"
		fail=1
	fi
}

# A second window and a zoomed pane, so the window formats and the zoom flag
# are covered rather than just the two end segments.
_snap_windows() {
	tmux -L "$1" new-window -n navi
	tmux -L "$1" new-window -n cyberia
	tmux -L "$1" split-window -t cyberia
	tmux -L "$1" resize-pane -t cyberia -Z
	tmux -L "$1" select-window -t 2
}

snap default \
	"@lain_separator=square" "@lain_glyphs=ascii"
snap flat \
	"@lain_separator=none" "@lain_glyphs=ascii"
snap powerline \
	"@lain_separator=powerline" "@lain_glyphs=unicode" \
	"@lain_modules_left=layer" "@lain_modules_right=wired_path present_day"
snap wire \
	"@lain_separator=wire" "@lain_glyphs=unicode" \
	"@lain_modules_left=layer" "@lain_modules_right=wired_path present_day"
snap transparent \
	"@lain_separator=square" "@lain_transparent=on"
snap windows \
	"@lain_separator=square" "@lain_glyphs=ascii" "@lain_window_index=layer"

if [ "$UPDATE" = "--update" ]; then
	echo
	printf '%s snapshot(s) written to %s\n' "$updated" "$GOLDEN"
	exit 0
fi

[ "$fail" -eq 0 ] || {
	echo
	echo "snapshots differ"
	exit 1
}
echo
echo "snapshots match"
