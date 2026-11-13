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
	lain_getv @lain_status_right_extra _sre
	# tmux expands the option itself, so its raw value never round-trips through show and the conf parser.
	[ -z "$_sre" ] || _sre='#{E:@lain_status_right_extra}'
	lain_set status-right "$(_lain_side right "$_mr")${_sre}"
}

_lain_side() {
	_ls_side="$1"
	_ls_list="$2"
	_ls_acc=""

	for _ls_m in $_ls_list; do
		lain_module_known "$_ls_m" || continue
		lain_compile "$_ls_m" "$_filled" || continue
		_ls_acc="${_ls_acc}${seg_bg}${LAIN_US}${seg_gate}${LAIN_US}${seg_cond}${LAIN_US}${seg_alt_bg}${LAIN_US}${seg_text}
"
	done

	[ -n "$_ls_acc" ] || return 0
	_lain_join "$_ls_side" "$_ls_acc"
}

_lain_join() {
	_lj_side="$1"
	_lj_acc="$2"

	_lj_wire="#[fg=${c_rule},nobold] $(lain_glyph wire) "
	if [ "$_lj_side" = "left" ]; then _lj_dir="right"; else _lj_dir="left"; fi

	printf '%s' "$_lj_acc" | {
		_lj_prev="$_bar_bg"
		_lj_prev_cond=""
		_lj_prev_alt=""
		_lj_first="yes"

		while IFS="$LAIN_US" read -r _lj_bg _lj_gate _lj_cond _lj_alt _lj_text; do
			[ -n "$_lj_text" ] || continue
			: "${_lj_bg:=$_bar_bg}"
			: "${_lj_alt:=$_lj_bg}"
			_lj_open=""
			_lj_close=""

			# Under its gate, the previous segment wears its alternate colour
			# when it switches on the same condition.
			_lj_gprev="$_lj_prev"
			[ -n "$_lj_gate" ] && [ "$_lj_prev_cond" = "$_lj_gate" ] &&
				_lj_gprev="$_lj_prev_alt"

			case "$_sep" in
			wire)
				[ "$_lj_first" = "yes" ] && [ -z "$_lj_gate" ] || _lj_open="$_lj_wire"
				;;
			powerline)
				if [ -n "$_lj_gate" ] && [ "$_lj_first" = "no" ] &&
					[ "$_lj_gprev" = "$_lj_bg" ]; then
					# Same colour as its neighbour: one block, no arrow, no pad.
					case "$_lj_text" in
					*"] "*) _lj_text="${_lj_text%%] *}]${_lj_text#*] }" ;;
					esac
				elif [ -n "$_lj_gate" ]; then
					[ "$_lj_side" = "left" ] && [ "$_lj_first" = "yes" ] ||
						_lj_open="$(_lain_pl_pair "$_lj_dir" "$_lj_gprev" "$_lj_bg")"
					_lj_close="$(_lain_pl_pair "$_lj_dir" "$_lj_bg" "$_lj_gprev")"
				elif [ "$_lj_side" = "right" ] || [ "$_lj_first" = "no" ]; then
					_lj_open="$(_lain_pl_prev "$_lj_dir" "$_lj_bg")"
				fi
				;;
			esac

			_lj_unit="${_lj_open}${_lj_text}${_lj_close}"

			if [ -n "$_lj_gate" ]; then
				printf '#{?%s,%s,}' "$_lj_gate" "$(lain_esc_comma "$_lj_unit")"
			else
				printf '%s' "$_lj_unit"
				_lj_prev="$_lj_bg"
				_lj_prev_cond="$_lj_cond"
				_lj_prev_alt="$_lj_alt"
				_lj_first="no"
			fi
		done

		if [ "$_sep" = "powerline" ] && [ "$_lj_side" = "left" ]; then
			_lain_pl_prev right "$_bar_bg"
		fi
	}
	printf '#[default]'
}

# Arrow from the previous segment into one of colour $3 (or out of $2 into $3,
# reading left to right), pointing $1.
_lain_pl_pair() {
	if [ "$1" = "right" ]; then
		_lain_pl right "$2" "$3"
	else
		_lain_pl left "$3" "$2"
	fi
}

# Arrow from the previous ungated segment into colour $2, switching with that
# segment's own condition.
_lain_pl_prev() {
	_pp_base="$(_lain_pl_pair "$1" "$_lj_prev" "$2")"
	if [ -n "$_lj_prev_cond" ] && [ "$_lj_prev_alt" != "$_lj_prev" ]; then
		_pp_alt="$(_lain_pl_pair "$1" "$_lj_prev_alt" "$2")"
		printf '#{?%s,%s,%s}' "$_lj_prev_cond" \
			"$(lain_esc_comma "$_pp_alt")" "$(lain_esc_comma "$_pp_base")"
	else
		printf '%s' "$_pp_base"
	fi
}

_lain_pl() {
	if [ "$2" = "$3" ]; then
		printf '#[fg=%s,bg=%s,nobold]%s' "$c_bg_bar" "$3" "$(lain_glyph "sep_$1_thin")"
	else
		printf '#[fg=%s,bg=%s,nobold]%s' "$2" "$3" "$(lain_glyph "sep_$1")"
	fi
}
