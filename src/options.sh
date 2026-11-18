#!/usr/bin/env sh
# Options: parsed once into shell variables, applied once as one sourced conf.

LAIN_US=$(printf '\037')

_LAIN_DEFAULTS='@lain_status_position bottom
@lain_status_interval 5
@lain_status_justify left
@lain_separator square
@lain_transparent off
@lain_window_index plain
@lain_glyphs ascii
@lain_modules_left layer
@lain_modules_right present_day
@lain_show_prefix on
@lain_show_date on
@lain_prefix_text PREFIX
@lain_node_long off
@lain_path_full off
@lain_date_format %Y-%m-%d
@lain_clock_format %H:%M
@lain_status_left_length 40
@lain_status_right_length 60
@lain_status_right_extra
@lain_poll_interval 15
@lain_coolant_low 20
@lain_pane_border_status off
@lain_debug off'

lain_defaults() { printf '%s\n' "$_LAIN_DEFAULTS"; }

_lain_out=""

lain_opts_init() {
	while IFS="$LAIN_US" read -r _oi_k _oi_v; do
		[ -n "$_oi_k" ] || continue
		eval "_lo_${_oi_k}=\$_oi_v"
	done <<EOF
$(
		{
			printf '%s\n' "$_LAIN_DEFAULTS"
			tmux show -gq 2>/dev/null || true
		} |
			awk -v us="$LAIN_US" '\
			$1 ~ /^@lain_/ {
				k = $1; sub(/^@lain_/, "", k)
				$1 = ""; sub(/^ /, "")
				q = substr($0, 1, 1)
				if (length($0) > 1 && (q == "\"" || q == "\047") && substr($0, length($0)) == q)
					$0 = substr($0, 2, length($0) - 2)
				print k us $0
			}'
	)
EOF
}

lain_get() {
	eval "printf '%s' \"\${_lo_${1#@lain_}-}\""
}

lain_getv() {
	eval "$2=\${_lo_${1#@lain_}-}"
}

lain_is_on() {
	eval "_li_v=\${_lo_${1#@lain_}-}"
	case "$_li_v" in
	on | true | yes | 1) return 0 ;;
	*) return 1 ;;
	esac
}

lain_out_init() {
	_lain_out=""
}

lain_set() {
	_lain_out="${_lain_out}set -g $1 \"$(lain_escape "$2")\"
"
}

lain_setw() {
	_lain_out="${_lain_out}setw -g $1 \"$(lain_escape "$2")\"
"
}

lain_escape() {
	case "$1" in
	*[\"\\]*) printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' ;;
	*) printf '%s' "$1" ;;
	esac
}

lain_esc_comma() {
	_ec_in="$1"
	_ec_out=""
	while :; do
		_ec_head="${_ec_in%%,*}"
		if [ "$_ec_head" = "$_ec_in" ]; then
			printf '%s%s' "$_ec_out" "$_ec_in"
			return 0
		fi
		_ec_out="${_ec_out}${_ec_head}#,"
		_ec_in="${_ec_in#*,}"
	done
}

lain_flush() {
	[ -n "$_lain_out" ] || return 0
	if lain_is_on @lain_debug; then
		_lf_file="${TMPDIR:-/tmp}/lain-tmux.$$.conf"
		printf '%s' "$_lain_out" >"$_lf_file"
		tmux source-file "$_lf_file"
		tmux display-message "lain.tmux: kept $_lf_file"
	else
		printf '%s' "$_lain_out" | tmux source-file -
	fi
}
