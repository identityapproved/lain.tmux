#!/usr/bin/env sh
# Everything that is not the status bar.
#
# A theme that only styles status-left and status-right looks half-finished the
# first time you open copy mode or a popup and get tmux's default green. These
# are the surfaces a session actually shows.

lain_surfaces_apply() {
	# Panes. Copper-equivalent here is the rose ramp: active border is the focus
	# ring role, inactive drops to a neutral grey so the two never compete.
	lain_set pane-border-style "fg=${c_border}"
	lain_set pane-active-border-style "fg=${c_border_active}"
	lain_set pane-border-status "$(lain_get @lain_pane_border_status)"
	lain_set pane-border-format " #P #{pane_current_command} "
	lain_set display-panes-colour "$c_fg_dim"
	lain_set display-panes-active-colour "$c_border_active"

	# Messages and the command prompt.
	lain_set message-style "bg=${c_bg_bar},fg=${c_fg_content}"
	lain_set message-command-style "bg=${c_bg_bar},fg=${c_fg_primary}"

	# Copy mode. The selection uses the palette's selection pairing, black on
	# ochre, rather than tmux's default reverse video.
	lain_set mode-style "bg=${c_select},fg=${c_select_fg}"
	lain_set copy-mode-match-style "bg=${c_bg_surface},fg=${c_fg_content}"
	lain_set copy-mode-current-match-style "bg=${c_select},fg=${c_select_fg}"
	lain_set copy-mode-mark-style "bg=${c_accent},fg=${c_fg_on_active}"

	# Menus and popups, both of which default to something outside the palette.
	lain_set menu-style "bg=${c_bg_bar},fg=${c_fg_primary}"
	lain_set menu-selected-style "bg=${c_bg_active},fg=${c_fg_on_active},bold"
	lain_set menu-border-style "fg=${c_border}"
	lain_set popup-style "bg=${c_bg_bar},fg=${c_fg_primary}"
	lain_set popup-border-style "fg=${c_border_active}"

	# The clock, which is otherwise tmux blue.
	lain_set clock-mode-colour "$c_fg_content"
	lain_set clock-mode-style 24
}
