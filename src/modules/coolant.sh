#!/usr/bin/env sh
# Battery charge.
#
# Opts out on a machine with no battery, which is what makes it safe to leave
# in a shared config: the segment is simply absent on the desktop.
lain_mod_coolant() {
	mod_icon="battery"
	mod_dynamic="coolant"
	mod_fg="$c_fg_on_active"
	mod_bg="$c_fg_dim"
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
