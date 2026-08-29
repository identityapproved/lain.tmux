#!/usr/bin/env sh
# Headless load: options apply, formats expand, version gate holds.

set -eu

cd "$(dirname "$0")/.."
PLUGIN_DIR="$(pwd)"
SOCKET="lain-smoke-$$"

t() { tmux -L "$SOCKET" "$@"; }
SHIMDIR="${TMPDIR:-/tmp}/lain-shim-$$"
cleanup() {
	t kill-server 2>/dev/null || true
	rm -f "/tmp/tmux-$(id -u)/$SOCKET"
	rm -rf "$SHIMDIR"
}
trap cleanup EXIT INT TERM

fail=0
assert_set() {
	value="$(t show -gqv "$1")"
	if [ -z "$value" ]; then
		printf 'FAIL  %s is empty\n' "$1"
		fail=1
	else
		printf 'ok    %-32s %s\n' "$1" "$value"
	fi
}

t -f /dev/null new-session -d -x 200 -y 50
t run-shell "$PLUGIN_DIR/lain.tmux"

echo "-- options applied"
for opt in status-style status-left status-right \
	window-status-format window-status-current-format \
	pane-active-border-style mode-style copy-mode-current-match-style \
	menu-selected-style popup-border-style clock-mode-colour \
	@lain_c_accent @lain_c_fg_dim; do
	assert_set "$opt"
done

echo
echo "-- formats expand"
expands() {
	out="$(t display-message -p "#{E:$1}")"
	case "$out" in
	*'#{'*)
		printf 'FAIL  %s left an unexpanded #{}: %s\n' "$1" "$out"
		fail=1
		;;
	*) printf 'ok    %-32s %s\n' "$1" "$out" ;;
	esac
}
for opt in status-left status-right window-status-format window-status-current-format; do
	expands "$opt"
done

echo
echo "-- @lain_window_index layer"
t set -g @lain_window_index layer
t run-shell "$PLUGIN_DIR/lain.tmux"
expands window-status-format
expands window-status-current-format
t set -g @lain_window_index plain

echo
echo "-- non-default option paths"
try_opts() {
	label="$1"
	probe="$2"
	shift 2
	for kv in "$@"; do
		t set -g "${kv%%=*}" "${kv#*=}"
	done
	if t run-shell "$PLUGIN_DIR/lain.tmux" 2>/dev/null; then
		printf 'ok    %-22s %-20s %s\n' "$label" "$probe" "$(t display-message -p "#{E:$probe}")"
	else
		printf 'FAIL  %s did not apply\n' "$label"
		fail=1
	fi
	for kv in "$@"; do
		t set -gu "${kv%%=*}"
	done
	t run-shell "$PLUGIN_DIR/lain.tmux"
}
try_opts "separator none" status-left "@lain_separator=none"
try_opts "separator wire" status-left "@lain_separator=wire" "@lain_modules_left=layer node"
try_opts "separator powerline" status-left "@lain_separator=powerline" "@lain_modules_left=layer node"
try_opts "glyphs unicode" status-left "@lain_glyphs=unicode"
try_opts "glyphs nerd" status-left "@lain_glyphs=nerd"
try_opts "knights module" status-left "@lain_modules_left=layer knights"
try_opts "unknown module" status-left "@lain_modules_left=layer nosuchmodule"
try_opts "empty module list" status-left "@lain_modules_left="
try_opts "transparent on" status-style "@lain_transparent=on"
try_opts "show_prefix off" status-left "@lain_show_prefix=off"
try_opts "path module" status-right "@lain_modules_right=wired_path present_day"
try_opts "show_date off" status-right "@lain_show_date=off"
try_opts "status top" status-position "@lain_status_position=top"
try_opts "custom clock" status-right "@lain_clock_format=%H:%M:%S"
try_opts "pane border on" pane-border-status "@lain_pane_border_status=top"

echo
echo "-- no temp files left behind"
leaked="$(find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'lain-tmux.*.conf' 2>/dev/null | wc -l)"
if [ "$leaked" -eq 0 ]; then
	printf 'ok    %s\n' "TMPDIR clean"
else
	printf 'FAIL  %s conf file(s) left in TMPDIR\n' "$leaked"
	fail=1
fi

echo
echo "-- version gate"
shimdir="$SHIMDIR"
mkdir -p "$shimdir"
realtmux="$(command -v tmux)"
cat >"$shimdir/tmux" <<SHIM
if [ "\$1" = "-V" ]; then printf 'tmux %s\n' "\$LAIN_FAKE_VERSION"; exit 0; fi
exec "$realtmux" "\$@"
SHIM
chmod +x "$shimdir/tmux"

t run-shell "env | grep '^TMUX=' > $SHIMDIR/env"
TMUX="$(cut -d= -f2- "$SHIMDIR/env")"
[ -n "$TMUX" ] || {
	echo "FAIL  could not resolve the test socket; refusing to run core.sh"
	exit 1
}
export TMUX

gate() {
	if LAIN_FAKE_VERSION="$1" PATH="$shimdir:$PATH" \
		"$PLUGIN_DIR/src/core.sh" "$PLUGIN_DIR" >/dev/null 2>&1; then
		got=0
	else
		got=$?
	fi
	if [ "$got" -eq 0 ] && [ "$2" = "accept" ]; then
		printf 'ok    %-32s accepted\n' "$1"
	elif [ "$got" -ne 0 ] && [ "$2" = "refuse" ]; then
		printf 'ok    %-32s refused\n' "$1"
	else
		printf 'FAIL  %s: wanted %s, exit was %s\n' "$1" "$2" "$got"
		fail=1
	fi
}

gate "3.5a" accept
gate "3.4" accept
gate "4.0" accept
gate "next-3.6" accept
gate "3.3a" refuse
gate "3.0" refuse
gate "2.9a" refuse
gate "master" accept

if [ "$fail" -ne 0 ]; then
	echo
	echo "smoke test failed"
	exit 1
fi
echo
echo "smoke test passed"
