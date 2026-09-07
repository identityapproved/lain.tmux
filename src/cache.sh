#!/usr/bin/env sh
# The cache and the daemon that fills it.

lain_cache_plan() {
	_cp_want=""
	lain_getv @lain_modules_left _cp_l
	lain_getv @lain_modules_right _cp_r
	for _cp_m in $_cp_l $_cp_r; do
		lain_module_known "$_cp_m" || continue
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

lain_daemon_start() {
	_ds_plan="$(lain_cache_plan)"
	if [ -z "$_ds_plan" ]; then
		lain_set @lain_daemon_modules ""
		return 0
	fi

	lain_getv @lain_poll_interval _ds_interval
	lain_getv @lain_daemon_modules _ds_running
	lain_set @lain_daemon_modules "$_ds_plan"
	lain_set @lain_poll_interval "$_ds_interval"

	# A live daemon keeps its job. It only loses it when the plan it was handed
	# no longer matches the one the config now asks for - otherwise a module
	# added to @lain_modules_* would wait for the server to die. The comparison
	# is against the published plan, not the new one, so a reload that changes
	# nothing publishes no id and the daemon is left alone.
	_ds_now="$(date +%s)"
	lain_getv @lain_daemon_beat _ds_beat
	if [ "$_ds_plan" = "$_ds_running" ] && [ -n "$_ds_beat" ] &&
		[ "$((_ds_now - _ds_beat))" -lt "$((_ds_interval * 3))" ]; then
		return 0
	fi

	_LAIN_LAUNCH_ID="${_ds_now}.$$"
	lain_set @lain_daemon_id "$_LAIN_LAUNCH_ID"
}

lain_daemon_launch() {
	[ -n "${_LAIN_LAUNCH_ID:-}" ] || return 0
	tmux run-shell -b "$LAIN_DIR/src/daemon/poll.sh '$LAIN_DIR' '$_LAIN_LAUNCH_ID'"
}

lain_sanitize() {
	tr -d '\n\r' | cut -c1-40 | sed 's/#/##/g'
}
