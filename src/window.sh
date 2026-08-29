#!/usr/bin/env sh
# Window list.
#
# The active window is an ochre fill with black text, the palette's selection
# pairing, which reads at 10.19:1. Inactive windows stay flat
# on the bar. Flags never rely on bold alone - mono fonts vary too much for
# weight to be a reliable signal - so each gets a colour and a glyph.

lain_window_apply() {
	_sep="$(lain_get @lain_separator)"
	_idx="$(_lain_window_index)"

	lain_set window-status-separator ""

	# Inactive: dim on the bar. Flags take bar-safe colours.
	lain_setw window-status-format \
		"#[fg=${c_fg_dim}] ${_idx}#W$(_lain_flags bar "${c_fg_dim}") "

	# Active: ochre fill. Flags drop to the on-fill set, because rose on ochre
	# is the one pairing the palette forbids outright.
	if [ "$_sep" = "none" ]; then
		lain_setw window-status-current-format \
			"#[fg=${c_fg_content},bold] ${_idx}#W$(_lain_flags bar "${c_fg_content}") "
	else
		lain_setw window-status-current-format \
			"#[fg=${c_fg_on_active},bg=${c_bg_active},bold] ${_idx}#W$(_lain_flags fill "${c_fg_on_active}") #[default]"
	fi

	# Bell and activity are surfaced by the flags above, so the default
	# reverse-video window-status-bell-style would double up and fight the fill.
	lain_setw window-status-bell-style "default"
	lain_setw window-status-activity-style "default"
}

# The index and its separator together, because the two styles want different
# separators: `plain` is the terse `1:name`, while `layer` borrows the show's
# own numbering and reads better with a space than a second colon.
_lain_window_index() {
	case "$(lain_get @lain_window_index)" in
	layer) printf '%s' 'LAYER:#{?#{e|<:#I,10},0,}#I ' ;;
	*) printf '%s' '#I:' ;;
	esac
}

# _lain_flags <bar|fill> <base-fg>
#
# Each flag sets its own colour then restores the segment's base, so a flag
# never bleeds into the text that follows it.
_lain_flags() {
	_ff_where="$1"
	_ff_base="$2"

	if [ "$_ff_where" = "fill" ]; then
		_ff_zoom="$c_flag_on_fill"
		_ff_bell="$c_bell_on_fill"
		_ff_mark="$c_flag_on_fill"
	else
		_ff_zoom="$c_flag_zoom"
		_ff_bell="$c_flag_bell"
		_ff_mark="$c_flag_mark"
	fi

	printf '%s%s%s%s' \
		"#{?window_zoomed_flag, #[fg=${_ff_zoom}]Z#[fg=${_ff_base}],}" \
		"#{?window_bell_flag, #[fg=${_ff_bell}]!#[fg=${_ff_base}],}" \
		"#{?window_activity_flag, #[fg=${_ff_base}]~,}" \
		"#{?window_marked_flag, #[fg=${_ff_mark}]M#[fg=${_ff_base}],}"
}
