#!/usr/bin/env sh
# Option layer: one `tmux show` for every option, one accumulated conf file for
# every write.
#
# Reading each option with its own `tmux show` costs a fork per option. Writing
# each with its own `tmux set` costs another. Both are batched here: the whole
# user-option namespace arrives in a single dump, and every style the plugin
# sets is appended to a conf file that tmux sources once at the end.

_lain_dump=""
_lain_out=""

# Every option the plugin understands, with its default. This table is the only
# place a default is written, so the README table cannot drift from behaviour.
lain_defaults() {
	cat <<'EOF'
@lain_status_position bottom
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
@lain_poll_interval 15
@lain_pane_border_status off
@lain_debug off
EOF
}

# Pull every @lain_* option in one call. `show -gq` is quiet about unset
# options, so an untouched config yields an empty dump and every lookup falls
# through to the defaults table.
lain_opts_init() {
	_lain_dump="$(tmux show -gq 2>/dev/null | grep '^@lain_' || true)"
}

# lain_get <option-name>
#
# User value if set, else the default. Surrounding double quotes are stripped:
# tmux quotes any value containing a space when it echoes it back.
lain_get() {
	_lg_v="$(
		printf '%s\n' "$_lain_dump" |
			awk -v k="$1" '$1 == k { $1 = ""; sub(/^ /, ""); print; exit }'
	)"
	if [ -z "$_lg_v" ]; then
		_lg_v="$(lain_defaults | awk -v k="$1" '$1 == k { $1 = ""; sub(/^ /, ""); print; exit }')"
	fi
	case "$_lg_v" in
	\"*\")
		_lg_v="${_lg_v#\"}"
		_lg_v="${_lg_v%\"}"
		;;
	esac
	printf '%s' "$_lg_v"
}

# lain_is_on <option-name> - true for on/true/yes/1.
lain_is_on() {
	case "$(lain_get "$1")" in
	on | true | yes | 1) return 0 ;;
	*) return 1 ;;
	esac
}

lain_out_init() {
	_lain_out="${TMPDIR:-/tmp}/lain-tmux.$$.conf"
	: >"$_lain_out"
}

# lain_set <option> <value> - queue a global set.
#
# The value is emitted inside double quotes, so a literal double quote in a
# user-supplied format has to be escaped or it would end the string early.
lain_set() {
	printf 'set -g %s "%s"\n' "$1" "$(lain_escape "$2")" >>"$_lain_out"
}

# lain_setw <option> <value> - queue a global window set.
lain_setw() {
	printf 'setw -g %s "%s"\n' "$1" "$(lain_escape "$2")" >>"$_lain_out"
}

lain_escape() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Apply everything queued so far in a single tmux invocation.
lain_flush() {
	[ -s "$_lain_out" ] || return 0
	tmux source-file "$_lain_out"
	if lain_is_on @lain_debug; then
		tmux display-message "lain.tmux: kept $_lain_out"
	else
		rm -f "$_lain_out"
	fi
}
