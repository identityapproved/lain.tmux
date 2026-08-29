#!/usr/bin/env sh
# The cache, and the daemon that fills it.
#
# The bar must never fork. A `#()` in a format string spawns a shell every
# status-interval - on some tmux versions once per pane - which is what makes
# busy status bars janky. So anything that needs a subprocess is computed once
# per interval by a single background process and written into a `@lain_cache_*`
# option. The bar reads the option, which costs nothing.
#
# That trades N forks per redraw for one process per server, and it is the only
# place in the plugin allowed to fork at all.

# Which dynamic modules are actually on the bar. Written at init so the daemon
# does not have to re-derive it, and so a module the user removed stops being
# polled on the next reload.
lain_cache_plan() {
	_cp_want=""
	for _cp_m in $(lain_get @lain_modules_left) $(lain_get @lain_modules_right); do
		lain_module_known "$_cp_m" || continue
		# The module function is called for its declarations only. Its own
		# opt-out is about whether there is data to show right now, which is
		# exactly what polling decides - so the plan ignores it and asks only
		# whether the module is dynamic at all.
		lain_mod_reset
		"lain_mod_$_cp_m" >/dev/null 2>&1 || true
		[ -n "$mod_dynamic" ] || continue
		for _cp_d in $mod_deps; do
			command -v "$_cp_d" >/dev/null 2>&1 || continue 2
		done
		case " $_cp_want " in
		*" $_cp_m "*) ;;
		*) _cp_want="${_cp_want}${_cp_m} " ;;
		esac
	done
	printf '%s' "${_cp_want% }"
}

# Start the daemon unless a live one is already polling.
#
# Liveness is a heartbeat, not a PID. A PID can be recycled by an unrelated
# process, and after a crash a stale PID would block the restart forever. A
# heartbeat older than three intervals means nothing is writing, whatever the
# process table says, so this is self-healing.
lain_daemon_start() {
	_ds_plan="$(lain_cache_plan)"
	if [ -z "$_ds_plan" ]; then
		lain_set @lain_daemon_modules ""
		return 0
	fi

	_ds_interval="$(lain_get @lain_poll_interval)"
	lain_set @lain_daemon_modules "$_ds_plan"
	lain_set @lain_poll_interval "$_ds_interval"

	_ds_now="$(date +%s)"
	_ds_beat="$(tmux show -gqv @lain_daemon_beat 2>/dev/null)"
	if [ -n "$_ds_beat" ] &&
		[ "$((_ds_now - _ds_beat))" -lt "$((_ds_interval * 3))" ]; then
		return 0
	fi

	# A generation token, so that if two starts race the loser notices on its
	# first tick and exits rather than both polling forever.
	_LAIN_LAUNCH_ID="${_ds_now}.$$"
	lain_set @lain_daemon_id "$_LAIN_LAUNCH_ID"
}

# Detach the poller, but only if this run decided one was needed.
lain_daemon_launch() {
	[ -n "${_LAIN_LAUNCH_ID:-}" ] || return 0
	tmux run-shell -b "$LAIN_DIR/src/daemon/poll.sh '$LAIN_DIR' '$_LAIN_LAUNCH_ID'"
}

# `#` becomes `##`, and that is the whole job.
#
# The drawn status line is scanned for `#[...]` style directives after
# substitution, so a value containing one takes effect: a branch named
# `x#[fg=red]` recolours the rest of the bar. Verified by rendering it. These
# values come from branch names and song titles, which are not ours to trust.
#
# `%` is deliberately NOT escaped. strftime runs on the format string before
# variable substitution, so a `%` inside a substituted value is never a
# conversion - verified by rendering `%H%d`, which came out literal. Escaping
# it to `%%` would make a battery reading render as `87%%`.
#
# Truncation happens before escaping so it cannot split a `##` pair.
lain_sanitize() {
	tr -d '\n\r' | cut -c1-40 | sed 's/#/##/g'
}
