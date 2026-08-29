#!/usr/bin/env sh
# Session name. The identity segment, so it carries the fill colour.
#
# Doubles as the prefix indicator when `@lain_show_prefix` is on: the segment
# flips to `accent` while the prefix is pending. Colour rather than a glyph, so
# it survives a terminal with no icon font and costs no width. Use the
# `knights` module instead to put the indicator in its own segment.
lain_mod_layer() {
	mod_icon="session"
	mod_text='#S'
	mod_fg="$c_fg_on_active"
	mod_bg="$c_bg_active"
	mod_attr="bold"
	if lain_is_on @lain_show_prefix; then
		mod_cond="client_prefix"
		mod_alt_fg="$c_fg_on_active"
		mod_alt_bg="$c_accent"
	fi
}
