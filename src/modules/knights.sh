#!/usr/bin/env sh
# Standalone prefix indicator. Absent at rest.

lain_mod_knights() {
	mod_icon="prefix"
	lain_getv @lain_prefix_text mod_text
	mod_fg="$c_fg_on_active"
	mod_bg="$c_accent"
	mod_attr="bold"
	mod_gate="client_prefix"
}
