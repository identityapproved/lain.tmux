#!/usr/bin/env sh
# The one process allowed to fork.

set -eu

LAIN_DIR="${1:-}"
MY_ID="${2:-}"
[ -n "$LAIN_DIR" ] && [ -n "$MY_ID" ] || exit 1

# shellcheck source=src/options.sh
. "$LAIN_DIR/src/options.sh"
# shellcheck source=src/registry.sh
. "$LAIN_DIR/src/registry.sh"
# shellcheck source=src/cache.sh
. "$LAIN_DIR/src/cache.sh"
lain_modules_load

shape=""

# A session is not what says the server is alive. tmux sources its config
# before the first one exists, and with exit-empty off the server outlives them
# all, so gating on has-session ends the daemon at boot on exactly the setups
# that keep a server running without a session. The published id is the real
# liveness test: show fails on a dead server, which reads as a mismatch and
# ends the loop the same way being superseded does.
while :; do
	[ "$(tmux show -gqv @lain_daemon_id 2>/dev/null)" = "$MY_ID" ] || exit 0

	# A plugin manager rewrites these files whenever it likes, including in the
	# seconds after this process started. Re-reading them each pass costs no
	# forks and means updated module code takes effect on the next tick instead
	# of at the next server restart.
	. "$LAIN_DIR/src/registry.sh"
	lain_modules_load

	now=""
	for _m in $(tmux show -gqv @lain_daemon_modules); do
		command -v "lain_poll_$_m" >/dev/null 2>&1 || continue
		_v="$("lain_poll_$_m" 2>/dev/null | lain_sanitize || true)"
		tmux set -g "@lain_cache_$_m" "$_v"
		[ -n "$_v" ] && now="${now}${_m} "
	done

	tmux set -g @lain_daemon_beat "$(date +%s)"

	if [ "$now" != "$shape" ]; then
		shape="$now"
		tmux run-shell "$LAIN_DIR/lain.tmux" 2>/dev/null || true
	fi

	sleep "$(tmux show -gqv @lain_poll_interval)"
done
