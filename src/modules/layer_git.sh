#!/usr/bin/env sh
# Branch of the repository the active pane is in.
#
# Follows the active pane rather than each pane separately: the cache is one
# global option, so per-pane state is not something this design can express.
# For a status bar that is the right trade - the branch you care about is the
# one in front of you.
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
