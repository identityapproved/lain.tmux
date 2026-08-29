#!/usr/bin/env sh
# Load the plugin into a headless tmux and assert it actually applied.
#
# Runs on its own socket with an empty config, so it can neither read the
# user's tmux.conf nor touch a running session.
set -eu

cd "$(dirname "$0")/.."
PLUGIN_DIR="$(pwd)"
SOCKET="lain-smoke-$$"

t() { tmux -L "$SOCKET" "$@"; }
cleanup() {
	t kill-server 2>/dev/null || true
	# kill-server leaves the socket file behind; a test that litters the
	# user's socket directory once per run is its own kind of bug.
	rm -f "/tmp/tmux-$(id -u)/$SOCKET"
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

# A conditional tmux cannot parse survives expansion as a literal `#{...}`,
# which is the failure a mis-escaped comma produces. `#[...]` style directives
# are expected to survive - they are consumed at draw time, not here - so only
# a residual `#{` is a fault.
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

# The layer index nests `#{e|<:...}` inside a `#{?...}`, so its comma belongs to
# the inner brace. Worth its own case: it is the one format where the parser
# has to get nesting right.
echo
echo "-- @lain_window_index layer"
t set -g @lain_window_index layer
t run-shell "$PLUGIN_DIR/lain.tmux"
expands window-status-format
expands window-status-current-format
t set -g @lain_window_index plain

# Each option gets its own pass, because a default-only run exercises exactly
# one branch of every conditional in status.sh and window.sh.
echo
echo "-- non-default option paths"
# try_opts <label> <probe-option> <name=value>...
#
# Sets the options, reapplies, then reports the expansion of the one option the
# change is supposed to affect - a case that reported status-left every time
# would pass whether or not the setting did anything.
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

# lain_flush removes its generated conf unless @lain_debug is on. A leak here
# would litter TMPDIR once per session start.
echo
echo "-- no temp files left behind"
leaked="$(find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'lain-tmux.*.conf' 2>/dev/null | wc -l)"
if [ "$leaked" -eq 0 ]; then
	printf 'ok    %s\n' "TMPDIR clean"
else
	printf 'FAIL  %s conf file(s) left in TMPDIR\n' "$leaked"
	fail=1
fi

if [ "$fail" -ne 0 ]; then
	echo
	echo "smoke test failed"
	exit 1
fi
echo
echo "smoke test passed"
