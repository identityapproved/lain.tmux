#!/usr/bin/env sh
# Branch of the active pane's repository.

lain_mod_layer_git() {
	mod_icon="branch"
	mod_deps="git"
	mod_dynamic="layer_git"
	mod_fg="$c_fg_on_active"
	mod_bg="$c_fg_primary"
}

lain_poll_layer_git() {
	_lg_path="$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)"
	[ -n "$_lg_path" ] || return 0
	git -C "$_lg_path" rev-parse --abbrev-ref HEAD 2>/dev/null
}
