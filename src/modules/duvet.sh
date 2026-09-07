#!/usr/bin/env sh
# Now playing, from whichever player the platform exposes.

lain_mod_duvet() {
	mod_icon="music"
	mod_dynamic="duvet"
	mod_fg="$c_fg_on_active"
	mod_bg="$c_fg_content"
}

lain_poll_duvet() {
	if command -v playerctl >/dev/null 2>&1; then
		_dv_raw="$(playerctl metadata --format '{{status}}|{{artist}} - {{title}}' 2>/dev/null)" || return 0
		case "$_dv_raw" in
		Stopped* | '' | '|') return 0 ;;
		esac
		_lain_duvet_trim "${_dv_raw#*|}"
	elif command -v nowplaying-cli >/dev/null 2>&1; then
		_dv_a="$(nowplaying-cli get artist 2>/dev/null)"
		_dv_t="$(nowplaying-cli get title 2>/dev/null)"
		[ "$_dv_a" = "null" ] && _dv_a=""
		[ "$_dv_t" = "null" ] && _dv_t=""
		_lain_duvet_trim "$_dv_a - $_dv_t"
	fi
}

# Either half can be empty - a podcast has no artist, a stream no title - and
# the separator would otherwise dangle off one end.
_lain_duvet_trim() {
	_dt_s="$1"
	case "$_dt_s" in
	' - '*) _dt_s="${_dt_s# - }" ;;
	esac
	case "$_dt_s" in
	*' - ') _dt_s="${_dt_s% - }" ;;
	esac
	printf '%s' "$_dt_s"
}
