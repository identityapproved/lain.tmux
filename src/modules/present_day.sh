#!/usr/bin/env sh
# Date and clock.

lain_mod_present_day() {
	mod_icon="clock"
	if lain_is_on @lain_show_date; then
		lain_getv @lain_date_format _pd_d
		lain_getv @lain_clock_format _pd_c
		mod_text="${_pd_d} ${_pd_c}"
	else
		lain_getv @lain_clock_format mod_text
	fi
	mod_fg="$c_fg_on_active"
	mod_bg="$c_fg_primary"
	mod_attr="bold"
}
