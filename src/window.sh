#!/usr/bin/env sh
# Window list formats, index styles and flags.

lain_window_apply() {
	lain_getv @lain_separator _sep
	_idx="$(_lain_window_index)"

	lain_set window-status-separator ""

	lain_setw window-status-format \
		"#[fg=${c_fg_dim}] ${_idx}#W$(_lain_flags bar "${c_fg_dim}") "

	if [ "$_sep" = "none" ]; then
		lain_setw window-status-current-format \
			"#[fg=${c_fg_content},bold] ${_idx}#W$(_lain_flags bar "${c_fg_content}") "
	else
		lain_setw window-status-current-format \
			"#[fg=${c_fg_on_active},bg=${c_bg_active},bold] ${_idx}#W$(_lain_flags fill "${c_fg_on_active}") #[default]"
	fi

	lain_setw window-status-bell-style "default"
	lain_setw window-status-activity-style "default"
}

_lain_window_index() {
	lain_getv @lain_window_index _wi
	case "$_wi" in
	layer) printf '%s' 'LAYER:#{?#{e|<:#I,10},0,}#I ' ;;
	*) printf '%s' '#I:' ;;
	esac
}

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
