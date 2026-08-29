#!/usr/bin/env sh
# Current directory of the active pane.

lain_mod_wired_path() {
	mod_icon="path"
	if lain_is_on @lain_path_full; then
		mod_text='#{pane_current_path}'
	else
		mod_text='#{b:pane_current_path}'
	fi
	mod_fg="$c_fg_on_active"
	mod_bg="$c_fg_dim"
}
