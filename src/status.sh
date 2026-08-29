#!/usr/bin/env sh
# The status line: compile the module lists, then join them.
#
# Every segment is a native tmux format. There is no `#()` anywhere, so the bar
# costs nothing per status-interval - no shell is forked, on any tmux version,
# for any number of panes. Keep it that way when adding modules.
#
# A literal comma inside `#[...]` has to be written `#,` whenever the style
# sits inside a `#{?...}` conditional, because the conditional splits its
# arguments on unescaped commas first.

lain_status_apply() {
	_sep="$(lain_get @lain_separator)"
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
	lain_set status-position "$(lain_get @lain_status_position)"
	lain_set status-interval "$(lain_get @lain_status_interval)"
	lain_set status-justify "$(lain_get @lain_status_justify)"
	lain_set status-left-length "$(lain_get @lain_status_left_length)"
	lain_set status-right-length "$(lain_get @lain_status_right_length)"
	lain_set status-style "bg=${_bar_bg},fg=${c_fg_primary}"

	lain_set status-left "$(_lain_side left "$(lain_get @lain_modules_left)")"
	lain_set status-right "$(_lain_side right "$(lain_get @lain_modules_right)")"
}

# _lain_side <left|right> <module list>
#
# Compiles each module, skipping any that opted out or is not a module name,
# then joins them. Segments are collected as `bg US text` lines rather than an
# array, because the shell dialect here has none.
#
# The delimiter is US (0x1f), not a tab. Tab counts as IFS whitespace, so `read`
# would swallow the leading empty field of a segment with no background and
# assign the text to the wrong variable - which silently drops every flat
# segment.
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

# _lain_join <side> <accumulated segments>
#
# `square` and `none` need no glyph between segments - the colour change is the
# boundary. `wire` draws a thin rule. `powerline` is the only style that has to
# know both neighbours, since the glyph is painted in the outgoing segment's
# background against the incoming one.
#
# Gated segments are the reason this is not a simple fold. A gated segment may
# not be there, so it must not disturb the chain: it opens from the previous
# background and closes straight back to it, and does not become the previous
# background itself. That keeps the separator after it correct whether or not
# it rendered, and works for any number of gated segments in a row.
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
			# The unit becomes one branch of a conditional, so every comma in
			# it now belongs to that conditional unless escaped.
			printf '#{?%s,%s,}' "$_lj_gate" \
				"$(printf '%s' "$_lj_unit" | sed 's/,/#,/g; s/###,/#,/g')"
		else
			printf '%s' "$_lj_unit"
			# Only an ungated segment advances the chain.
			_lj_prev="$_lj_bg"
			_lj_first="no"
		fi
	done

	# Close a left-hand powerline run back to the bar, using the last segment
	# that is actually always there. The right-hand side needs no closer: it
	# already opened against the bar.
	if [ "$_sep" = "powerline" ] && [ "$_lj_side" = "left" ]; then
		_lj_last="$(printf '%s' "$_lj_acc" | awk -F"$LAIN_US" '$2 == "" && $1 != "" { b = $1 } END { print b }')"
		[ -n "$_lj_last" ] || _lj_last="$_bar_bg"
		_lain_pl right "$_lj_last" "$_bar_bg"
	fi
	printf '#[default]'
}

# _lain_pl <right|left> <glyph fg> <glyph bg>
#
# A solid powerline glyph is invisible when the two segments it divides share a
# fill, since it is painted in one against the other. That is the case the thin
# variant exists for: same shape, drawn as a rule in the bar colour, which
# stays legible against every fill in the palette.
_lain_pl() {
	if [ "$2" = "$3" ]; then
		printf '#[fg=%s,bg=%s,nobold]%s' "$c_bg_bar" "$3" "$(lain_glyph "sep_$1_thin")"
	else
		printf '#[fg=%s,bg=%s,nobold]%s' "$2" "$3" "$(lain_glyph "sep_$1")"
	fi
}
