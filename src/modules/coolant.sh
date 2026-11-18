#!/usr/bin/env sh
# Battery charge. Absent where there is no battery.

lain_mod_coolant() {
	mod_icon="battery"
	mod_dynamic="coolant"
	mod_fg="$c_fg_on_active"
	mod_bg="$c_fg_dim"

	lain_getv @lain_coolant_low _co_low
	case "$_co_low" in
	'' | *[!0-9]*) _co_low=20 ;;
	esac
	[ "$_co_low" -gt 0 ] || return 0
	mod_cond="#{e|<=:#{s/%//:@lain_cache_coolant},${_co_low}}"
	mod_icon_alt="battery_low"
	mod_icon_cond="$mod_cond"
	mod_alt_attr="bold"
	mod_alt_fg="$c_alert_fg"
	mod_alt_bg="$c_alert"
	# The alert fill reads poorly as flat text on the bar; accent clears 4.5:1.
	mod_alt_flat="$c_accent"
}

lain_poll_coolant() {
	for _bat in /sys/class/power_supply/BAT*/capacity; do
		if [ -r "$_bat" ]; then
			printf '%s%%' "$(cat "$_bat")"
			return 0
		fi
	done
	if command -v pmset >/dev/null 2>&1; then
		pmset -g batt | sed -n 's/.*[^0-9]\([0-9]\{1,3\}\)%.*/\1%/p' | head -1
	fi
}
