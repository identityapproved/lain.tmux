#!/usr/bin/env sh
# Semantic tokens.
#
# Nothing downstream references a ramp step directly. Every format string reads
# a role - bg_bar, fg_dim, border_active - and this file is the single place a
# role is bound to a hex. That indirection is what lets the ramps change, or a
# variant be added later, without touching a format string.
#
# Contrast is checked in tests/contrast.sh. Every pair the theme actually
# renders clears WCAG AA at 4.5:1.

lain_palette_init() {
	# Surfaces
	c_bg_bar="$lain_back_2"     # #1A1A1A raised surface, statusbar
	c_bg_active="$lain_high_1"  # #C1B48E selection background
	c_bg_surface="$lain_back_3" # #2A2A2A second raised surface, popup

	# Text
	c_fg_primary="$lain_fore_1"   # #CE7688 body text, UI chrome
	c_fg_on_active="$lain_back_1" # #000000 selection foreground
	c_fg_content="$lain_high_1"   # #C1B48E body text, long-form

	# Dimmed text.
	#
	# The obvious picks are fore_6 #804654 (the palette's "disabled" step) and
	# high_8 #5A5341. Against bg_bar those are 2.41:1 and 2.27:1 - both under
	# the 3.0 large-text floor, let alone 4.5, which makes inactive window
	# names effectively unreadable. high_4 is the first step up that ramp which
	# clears AA, at 5.18:1.
	c_fg_dim="$lain_high_4" # #968C6E

	# States
	c_accent="$lain_accent"       # #FFB1C3 urgent focus, prefix active
	c_alert="$lain_error_bg"      # #930006 alert fill
	c_alert_fg="$lain_success_fg" # #FFDCB9 text on the alert fill

	# The wire separator's rule.
	#
	# Not c_border: #2A2A2A against the bar is 1.21:1, which is a separator you
	# cannot see. high_6 is the first step down the ochre ramp that clears the
	# 3.0 UI floor against bg_bar, at 3.58:1 - subdued, which is the point, but
	# actually present.
	c_rule="$lain_high_6" # #7A7158

	# Borders
	c_border="$lain_back_3"        # #2A2A2A inactive border
	c_border_active="$lain_fore_1" # #CE7688 active border / focus ring

	# Selection and search
	c_select="$lain_high_1"    # #C1B48E selection, search match
	c_select_fg="$lain_back_1" # #000000 on the ochre fill

	# Window flags.
	#
	# Two sets, because a flag can land on the dark bar or on the ochre fill of
	# the active window, and the pairing rule forbids rose on ochre. On the bar
	# a bell is `accent`; on the fill it drops to the error colour.
	#
	# error_fg #680003 would give more headroom on ochre (6.41 against 4.54),
	# but it is a fill colour and is not used as text anywhere. 4.54 is a thin
	# pass: recheck it before touching either the High ramp or this value.
	#
	# tmux's own window-status-bell-style cannot do this job. An explicit
	# `#[fg=]` in window-status-format overrides it outright - verified by
	# rendering a real bell - which is why it is set to `default` in window.sh
	# and the flag carries the signal instead.
	c_flag_zoom="$lain_high_1"      # #C1B48E on the bar
	c_flag_bell="$lain_accent"      # #FFB1C3 on the bar
	c_flag_mark="$lain_accent"      # #FFB1C3 on the bar
	c_flag_on_fill="$lain_back_1"   # #000000 on the ochre fill
	c_bell_on_fill="$lain_error_bg" # #930006 on the ochre fill
}

# Publish every token as a tmux user option.
#
# The plugin itself substitutes these shell-side, which is simpler and has no
# version caveats. These options exist for the escape hatch: a user composing
# their own status-left writes `#[fg=#{E:@lain_c_accent}]` and stays on palette
# without hardcoding a hex that a ramp change would strand.
lain_palette_apply() {
	lain_set @lain_c_bg_bar "$c_bg_bar"
	lain_set @lain_c_bg_active "$c_bg_active"
	lain_set @lain_c_bg_surface "$c_bg_surface"
	lain_set @lain_c_fg_primary "$c_fg_primary"
	lain_set @lain_c_fg_on_active "$c_fg_on_active"
	lain_set @lain_c_fg_content "$c_fg_content"
	lain_set @lain_c_fg_dim "$c_fg_dim"
	lain_set @lain_c_accent "$c_accent"
	lain_set @lain_c_alert "$c_alert"
	lain_set @lain_c_alert_fg "$c_alert_fg"
	lain_set @lain_c_rule "$c_rule"
	lain_set @lain_c_border "$c_border"
	lain_set @lain_c_border_active "$c_border_active"
	lain_set @lain_c_select "$c_select"
	lain_set @lain_c_select_fg "$c_select_fg"
}
