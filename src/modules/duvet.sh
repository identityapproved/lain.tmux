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
		_dv_raw="$(playerctl -a metadata --format '{{status}}|{{artist}} - {{title}}' 2>/dev/null)" || return 0
		[ -n "$_dv_raw" ] || return 0
		_lain_duvet_pick "$_dv_raw"
	elif command -v nowplaying-cli >/dev/null 2>&1; then
		_dv_a="$(nowplaying-cli get artist 2>/dev/null)"
		_dv_t="$(nowplaying-cli get title 2>/dev/null)"
		[ "$_dv_a" = "null" ] && _dv_a=""
		[ "$_dv_t" = "null" ] && _dv_t=""
		_lain_duvet_trim "$_dv_a - $_dv_t"
	fi
}

# A browser and a music daemon are both MPRIS players, and the one playerctl
# answers for by default is as often as not the idle one. Ask every player and
# take whatever is actually playing, falling back to a paused player so the
# segment does not blink out mid-track. Anything Stopped is ignored.
_lain_duvet_pick() {
	_dp_play=""
	_dp_pause=""
	while IFS= read -r _dp_line; do
		_dp_track="${_dp_line#*|}"
		case "$_dp_track" in
		'' | ' - ' | "$_dp_line") continue ;;
		esac
		case "$_dp_line" in
		Playing\|*) [ -n "$_dp_play" ] || _dp_play="$_dp_track" ;;
		Paused\|*) [ -n "$_dp_pause" ] || _dp_pause="$_dp_track" ;;
		esac
	done <<EOF
$1
EOF
	[ -n "$_dp_play" ] || _dp_play="$_dp_pause"
	[ -n "$_dp_play" ] || return 0
	_lain_duvet_trim "$_dp_play"
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
