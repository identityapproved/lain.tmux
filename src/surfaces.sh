#!/usr/bin/env sh
# Everything that is not the status bar.

lain_surfaces_apply() {
	lain_set pane-border-style "fg=${c_border}"
	lain_set pane-active-border-style "fg=${c_border_active}"
	lain_getv @lain_pane_border_status _pbs
	lain_set pane-border-status "$_pbs"
	lain_set pane-border-format " #P #{pane_current_command} "
	lain_set display-panes-colour "$c_fg_dim"
	lain_set display-panes-active-colour "$c_border_active"

	lain_set message-style "bg=${c_bg_bar},fg=${c_fg_content}"
	lain_set message-command-style "bg=${c_bg_bar},fg=${c_fg_primary}"

	lain_set mode-style "bg=${c_select},fg=${c_select_fg}"
	lain_set copy-mode-match-style "bg=${c_bg_surface},fg=${c_fg_content}"
	lain_set copy-mode-current-match-style "bg=${c_select},fg=${c_select_fg}"
	lain_set copy-mode-mark-style "bg=${c_accent},fg=${c_fg_on_active}"

	lain_set menu-style "bg=${c_bg_bar},fg=${c_fg_primary}"
	lain_set menu-selected-style "bg=${c_bg_active},fg=${c_fg_on_active},bold"
	lain_set menu-border-style "fg=${c_border}"
	lain_set popup-style "bg=${c_bg_bar},fg=${c_fg_primary}"
	lain_set popup-border-style "fg=${c_border_active}"

	lain_set clock-mode-colour "$c_fg_content"
	lain_set clock-mode-style 24
}
