#!/usr/bin/env sh
# Semantic tokens. Nothing downstream names a colour directly.

lain_palette_init() {
	c_bg_bar="$lain_back_2"
	c_bg_active="$lain_high_1"
	c_bg_surface="$lain_back_3"

	c_fg_primary="$lain_fore_1"
	c_fg_on_active="$lain_back_1"
	c_fg_content="$lain_high_1"

	c_fg_dim="$lain_high_4"

	c_accent="$lain_accent"
	c_alert="$lain_error_bg"
	c_alert_fg="$lain_success_fg"

	c_rule="$lain_high_6"

	c_border="$lain_back_3"
	c_border_active="$lain_fore_1"

	c_select="$lain_high_1"
	c_select_fg="$lain_back_1"

	c_flag_zoom="$lain_high_1"
	c_flag_bell="$lain_accent"
	c_flag_mark="$lain_accent"
	c_flag_on_fill="$lain_back_1"
	c_bell_on_fill="$lain_error_bg"
}

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
