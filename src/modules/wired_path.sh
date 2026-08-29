#!/usr/bin/env sh
# Current directory of the active pane.
#
# Basename only by default. The full path is available via `@lain_path_full`,
# but it is the one segment that can grow without bound, so the status length
# budget is what actually protects the bar.
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
