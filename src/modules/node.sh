#!/usr/bin/env sh
# Hostname.
#
# Off by default: it is noise on a local session and essential on a remote one.
# `#h` is the short name; `@lain_node_long` switches to the full one.
lain_mod_node() {
	mod_icon="node"
	if lain_is_on @lain_node_long; then
		mod_text='#H'
	else
		mod_text='#h'
	fi
	# Rose fill, not ochre: `layer` and `wired_path` already sit on the ochre
	# ramp, and two adjacent segments sharing a fill make a powerline separator
	# invisible.
	mod_fg="$c_fg_on_active"
	mod_bg="$c_fg_primary"
}
