#!/usr/bin/env sh
# The one process allowed to fork.
#
# Started detached by core.sh via `tmux run-shell -b`. Writes each enabled
# dynamic module's value into `@lain_cache_<name>` once per interval; the bar
# only ever reads those options.
#
# Exits on its own when the server goes away, or when a newer daemon has taken
# the generation token. There is no separate kill path to get wrong.
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

# Which modules currently have a value. A dynamic module opts out of the bar
# while its cache is empty, so this set is what the compiled status line was
# built from: when it changes, the bar has to be rebuilt. The values themselves
# change constantly and need no rebuild - the bar reads them through the
# option.
shape=""

while tmux has-session 2>/dev/null; do
	[ "$(tmux show -gqv @lain_daemon_id)" = "$MY_ID" ] || exit 0

	now=""
	for _m in $(tmux show -gqv @lain_daemon_modules); do
		command -v "lain_poll_$_m" >/dev/null 2>&1 || continue
		# One `tmux set` per module per interval. Batching would save a fork
		# every fifteen seconds and cost a layer of quoting - the redraw path
		# is what matters, and it does not fork at all.
		_v="$("lain_poll_$_m" 2>/dev/null | lain_sanitize || true)"
		tmux set -g "@lain_cache_$_m" "$_v"
		[ -n "$_v" ] && now="${now}${_m} "
	done

	tmux set -g @lain_daemon_beat "$(date +%s)"

	if [ "$now" != "$shape" ]; then
		shape="$now"
		# Re-applying is safe to do from here: the heartbeat above is fresh, so
		# the run this triggers will not start a second daemon.
		tmux run-shell "$LAIN_DIR/lain.tmux" 2>/dev/null || true
	fi

	sleep "$(tmux show -gqv @lain_poll_interval)"
done
