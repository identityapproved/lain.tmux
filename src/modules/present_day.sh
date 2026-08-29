#!/usr/bin/env sh
# Date and clock.
#
# status-left and status-right are passed through strftime, so the formats go
# in verbatim and no subprocess is involved. Date is dim and clock is chrome
# rose: of the two, the clock is the one being read at a glance.
lain_mod_present_day() {
	mod_icon="clock"
	if lain_is_on @lain_show_date; then
		mod_text="#[fg=${c_fg_dim}]$(lain_get @lain_date_format) #[fg=${c_fg_primary}]$(lain_get @lain_clock_format)"
	else
		mod_text="$(lain_get @lain_clock_format)"
	fi
	mod_fg="$c_fg_primary"
	mod_bg=""
}
