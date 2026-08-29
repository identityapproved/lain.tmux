#!/usr/bin/env sh
# Status line: compile the module lists, then join them.

lain_status_apply() {
	lain_getv @lain_separator _sep
	case "$_sep" in
	square | powerline) _filled="yes" ;;
	*) _filled="no" ;;
	esac

	if lain_is_on @lain_transparent; then
		_bar_bg="default"
	else
		_bar_bg="$c_bg_bar"
	fi

	lain_set status "on"
	lain_getv @lain_status_position _sp
	lain_getv @lain_status_interval _si
	lain_getv @lain_status_justify _sj
	lain_getv @lain_status_left_length _sll
	lain_getv @lain_status_right_length _srl
	lain_set status-position "$_sp"
	lain_set status-interval "$_si"
	lain_set status-justify "$_sj"
	lain_set status-left-length "$_sll"
	lain_set status-right-length "$_srl"
	lain_set status-style "bg=${_bar_bg},fg=${c_fg_primary}"

	lain_getv @lain_modules_left _ml
	lain_getv @lain_modules_right _mr
	lain_set status-left "$(_lain_side left "$_ml")"
	lain_set status-right "$(_lain_side right "$_mr")"
}

_lain_side() {
	_ls_side="$1"
	_ls_list="$2"
	_ls_acc=""

	for _ls_m in $_ls_list; do
		lain_module_known "$_ls_m" || continue
		lain_compile "$_ls_m" "$_filled" || continue
		_ls_acc="${_ls_acc}${seg_bg}${LAIN_US}${seg_gate}${LAIN_US}${seg_text}
"
	done

	[ -n "$_ls_acc" ] || return 0
	_lain_join "$_ls_side" "$_ls_acc"
}

_lain_join() {
	_lj_side="$1"
	_lj_acc="$2"
	_lj_prev=""
	_lj_first="yes"

	_lj_wire="#[fg=${c_rule},nobold] $(lain_glyph wire) "

	printf '%s' "$_lj_acc" | while IFS="$LAIN_US" read -r _lj_bg _lj_gate _lj_text; do
		[ -n "$_lj_text" ] || continue
		: "${_lj_bg:=$_bar_bg}"
		_lj_open=""
		_lj_close=""

		case "$_sep" in
		wire)
			[ "$_lj_first" = "yes" ] && [ -z "$_lj_gate" ] || _lj_open="$_lj_wire"
			;;
		powerline)
			if [ "$_lj_side" = "left" ]; then
				[ "$_lj_first" = "yes" ] ||
					_lj_open="$(_lain_pl right "${_lj_prev:-$_bar_bg}" "$_lj_bg")"
				[ -n "$_lj_gate" ] &&
					_lj_close="$(_lain_pl right "$_lj_bg" "${_lj_prev:-$_bar_bg}")"
			else
				_lj_open="$(_lain_pl left "$_lj_bg" "${_lj_prev:-$_bar_bg}")"
				[ -n "$_lj_gate" ] &&
					_lj_close="$(_lain_pl left "${_lj_prev:-$_bar_bg}" "$_lj_bg")"
			fi
			;;
		esac

		_lj_unit="${_lj_open}${_lj_text}${_lj_close}"

		if [ -n "$_lj_gate" ]; then
			printf '#{?%s,%s,}' "$_lj_gate" "$(lain_esc_comma "$_lj_unit")"
		else
			printf '%s' "$_lj_unit"
			_lj_prev="$_lj_bg"
			_lj_first="no"
		fi
	done

	if [ "$_sep" = "powerline" ] && [ "$_lj_side" = "left" ]; then
		_lj_last="$(printf '%s' "$_lj_acc" | awk -F"$LAIN_US" '$2 == "" && $1 != "" { b = $1 } END { print b }')"
		[ -n "$_lj_last" ] || _lj_last="$_bar_bg"
		_lain_pl right "$_lj_last" "$_bar_bg"
	fi
	printf '#[default]'
}

_lain_pl() {
	if [ "$2" = "$3" ]; then
		printf '#[fg=%s,bg=%s,nobold]%s' "$c_bg_bar" "$3" "$(lain_glyph "sep_$1_thin")"
	else
		printf '#[fg=%s,bg=%s,nobold]%s' "$2" "$3" "$(lain_glyph "sep_$1")"
	fi
}
