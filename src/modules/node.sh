#!/usr/bin/env sh
# Hostname.

lain_mod_node() {
	mod_icon="node"
	if lain_is_on @lain_node_long; then
		mod_text='#H'
	else
		mod_text='#h'
	fi
	mod_fg="$c_fg_on_active"
	mod_bg="$c_fg_primary"
}
