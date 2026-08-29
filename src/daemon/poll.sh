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

while tmux has-session 2>/dev/null; do
	[ "$(tmux show -gqv @lain_daemon_id)" = "$MY_ID" ] || exit 0

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
