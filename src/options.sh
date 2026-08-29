#!/usr/bin/env sh
# Option layer: one `tmux show` in, one conf file out, and no forking to read.
#
# Reading an option by re-parsing a table costs a process per lookup, and there
# are around thirty lookups per load. So the whole namespace is parsed once into
# shell variables and every later read is a parameter expansion. Writes are
# appended to a conf file that tmux sources once at the end, rather than a
# `tmux set` apiece.

# Field delimiter for the parsed table and for the segment accumulator in
# status.sh. US (0x1f) because it is not IFS whitespace: a tab would let `read`
# swallow an empty leading field.
LAIN_US=$(printf '\037')

# Every option the plugin understands, with its default. This is the only place
# a default is written, so the README table cannot drift from behaviour.
#
# A here-doc would be read with `cat`, which is a process per call. A plain
# variable is free.
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
@lain_poll_interval 15
@lain_pane_border_status off
@lain_debug off'

lain_defaults() { printf '%s\n' "$_LAIN_DEFAULTS"; }

_lain_out=""

# Parse defaults, then the user's settings over the top, into `_lo_<name>`
# variables. Later lines win, so the loop order is the precedence.
#
# The loop body has to run in this shell for the assignments to survive, which
# is why the input arrives by here-doc rather than through a pipe.
lain_opts_init() {
	while IFS="$LAIN_US" read -r _oi_k _oi_v; do
		[ -n "$_oi_k" ] || continue
		# Assigning through a variable reference sidesteps quoting entirely:
		# the value is never re-parsed by the shell.
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
				gsub(/^"|"$/, "")
				print k us $0
			}'
	)
EOF
}

# lain_get <option-name> - the user value if set, else the default.
#
# Every call site wraps this in `$(...)`, which forks a subshell - about a
# millisecond each, and there are enough lookups per load for that to be the
# single largest cost. Prefer lain_getv where the value lands in a variable.
lain_get() {
	eval "printf '%s' \"\${_lo_${1#@lain_}-}\""
}

# lain_getv <option-name> <variable> - lain_get without the subshell.
lain_getv() {
	eval "$2=\${_lo_${1#@lain_}-}"
}

# lain_is_on <option-name> - true for on/true/yes/1.
lain_is_on() {
	eval "_li_v=\${_lo_${1#@lain_}-}"
	case "$_li_v" in
	on | true | yes | 1) return 0 ;;
	*) return 1 ;;
	esac
}

lain_out_init() {
	_lain_out="${TMPDIR:-/tmp}/lain-tmux.$$.conf"
	: >"$_lain_out"
}

# lain_set <option> <value> - queue a global set.
lain_set() {
	printf 'set -g %s "%s"\n' "$1" "$(lain_escape "$2")" >>"$_lain_out"
}

# lain_setw <option> <value> - queue a global window set.
lain_setw() {
	printf 'setw -g %s "%s"\n' "$1" "$(lain_escape "$2")" >>"$_lain_out"
}

# The value is emitted inside double quotes, so a literal quote or backslash
# would end the string early. Neither appears in anything the plugin generates,
# so the common path avoids the process entirely and only a user-supplied
# format pays for one.
lain_escape() {
	case "$1" in
	*[\"\\]*) printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' ;;
	*) printf '%s' "$1" ;;
	esac
}

# lain_esc_comma <style> - escape commas for use inside a `#{?...}`.
#
# Pure expansion rather than sed: this runs per module, and the strings are
# short enough that a loop beats a process.
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
