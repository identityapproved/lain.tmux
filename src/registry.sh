#!/usr/bin/env sh
# Module registry: modules describe a segment, this compiles it.

LAIN_MODULES="layer knights node wired_path present_day psyche coolant layer_git duvet accela"

lain_modules_load() {
	for _lm_m in $LAIN_MODULES; do
		# shellcheck source=/dev/null
		. "$LAIN_DIR/src/modules/$_lm_m.sh"
	done
}

lain_mod_reset() {
	mod_icon=""
	mod_icon_alt=""
	mod_icon_cond=""
	mod_text=""
	mod_fg="$c_fg_primary"
	mod_bg=""
	mod_attr="nobold"
	mod_cond=""
	mod_alt_fg=""
	mod_alt_bg=""
	mod_alt_attr=""
	mod_alt_flat=""
	mod_gate=""
	mod_deps=""
	mod_dynamic=""
}

lain_module_known() {
	for _mk_m in $LAIN_MODULES; do
		[ "$_mk_m" = "$1" ] && return 0
	done
	return 1
}

lain_compile() {
	_lc_name="$1"
	_lc_filled="$2"

	lain_mod_reset
	"lain_mod_$_lc_name" || return 1

	if [ -n "$mod_gate" ] && [ -n "$mod_cond" ]; then
		tmux display-message "lain.tmux: module $_lc_name sets both mod_gate and mod_cond"
		return 1
	fi

	for _lc_d in $mod_deps; do
		command -v "$_lc_d" >/dev/null 2>&1 || return 1
	done

	if [ -n "$mod_dynamic" ]; then
		lain_getv "@lain_cache_${mod_dynamic}" _lc_cached
		[ -n "$_lc_cached" ] || return 1
		mod_text="#{@lain_cache_${mod_dynamic}}"
	fi

	_lc_icon="$(lain_icon "$mod_icon")"
	if [ -n "$mod_icon_cond" ]; then
		_lc_icon_alt="$(lain_icon "$mod_icon_alt")"
		[ -n "$_lc_icon_alt" ] && [ "$_lc_icon_alt" != "$_lc_icon" ] &&
			_lc_icon="#{?${mod_icon_cond},${_lc_icon_alt},${_lc_icon}}"
	fi
	_lc_body="${_lc_icon}$mod_text"

	if [ "$_lc_filled" = "yes" ] && [ -n "$mod_bg" ]; then
		seg_bg="$mod_bg"
		_lc_base="fg=${mod_fg},bg=${mod_bg}"
		_lc_alt="fg=${mod_alt_fg:-$mod_fg},bg=${mod_alt_bg:-$mod_bg}"
	else
		seg_bg=""
		_lc_base="fg=${mod_bg:-$mod_fg}"
		_lc_alt="fg=${mod_alt_flat:-${mod_alt_bg:-${mod_alt_fg:-${mod_bg:-$mod_fg}}}}"
	fi

	[ -n "$mod_attr" ] && _lc_base="${_lc_base},${mod_attr}"
	_lc_aa="${mod_alt_attr:-$mod_attr}"
	[ -n "$_lc_aa" ] && _lc_alt="${_lc_alt},${_lc_aa}"

	seg_gate="$mod_gate"
	seg_cond="$mod_cond"
	seg_alt_bg=""
	[ -n "$seg_bg" ] && [ -n "$mod_cond" ] && seg_alt_bg="${mod_alt_bg:-$mod_bg}"

	if [ -n "$mod_cond" ]; then
		seg_text="#{?${mod_cond},#[$(lain_esc_comma "$_lc_alt")],#[$(lain_esc_comma "$_lc_base")]} ${_lc_body} "
	else
		seg_text="#[${_lc_base}] ${_lc_body} "
	fi
	return 0
}
