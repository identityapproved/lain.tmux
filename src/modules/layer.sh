#!/usr/bin/env sh
# Session name, and the prefix indicator.

lain_mod_layer() {
	mod_icon="session"
	mod_text='#S'
	mod_fg="$c_fg_on_active"
	mod_bg="$c_bg_active"
	mod_attr="bold"
	if lain_is_on @lain_show_prefix; then
		mod_cond="client_prefix"
		mod_alt_fg="$c_fg_on_active"
		mod_alt_bg="$c_accent"
	fi
}
