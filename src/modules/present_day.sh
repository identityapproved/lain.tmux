#!/usr/bin/env sh
# Date and clock.
#
# status-left and status-right are passed through strftime, so the formats go
# in verbatim and no subprocess is involved. Date is dim and clock is chrome
# rose: of the two, the clock is the one being read at a glance.
lain_mod_present_day() {
	mod_icon="clock"
	if lain_is_on @lain_show_date; then
		lain_getv @lain_date_format _pd_d
		lain_getv @lain_clock_format _pd_c
		mod_text="#[fg=${c_fg_dim}]${_pd_d} #[fg=${c_fg_primary}]${_pd_c}"
	else
		lain_getv @lain_clock_format mod_text
	fi
	mod_fg="$c_fg_primary"
	mod_bg=""
}
