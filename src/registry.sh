#!/usr/bin/env sh
# Module registry.
#
# A module is a shell function that describes one segment; it never emits a
# format string itself. The registry compiles that description into tmux
# format, which is what keeps the separator logic in one place instead of
# duplicated across every module.
#
# Contract - `lain_mod_<name>` sets these and returns 0, or returns 1 to opt
# out (disabled by an option, or unavailable):
#
#   mod_icon    glyph key, or empty for no icon
#   mod_text    tmux format for the body
#   mod_fg      foreground when filled segments are off, or the text colour
#   mod_bg      background, or empty for a flat segment
#   mod_attr    style attributes; defaults to nobold, see below
#   mod_cond    tmux condition selecting the alternate style, or empty
#   mod_alt_fg  foreground while mod_cond holds
#   mod_alt_bg  background while mod_cond holds
#   mod_gate    tmux condition; the whole segment collapses to nothing when it
#               is false, so the module costs no width at rest
#   mod_deps    binaries the module needs; it opts out if any is missing
#   mod_dynamic cache key. The module reads `@lain_cache_<key>`, which the
#               daemon fills, and opts out entirely while that option is empty.
#               A dynamic module also defines `lain_poll_<name>`, which prints
#               the value and is the only thing in the plugin permitted to
#               fork.
#
#               Opting out rather than gating is deliberate. A gated segment
#               has to open from its neighbour and close back to it so the
#               separator chain stays correct whether or not it fired, which
#               shows up as a doubled separator - tolerable for `knights`,
#               which is off almost always, and wrong for polled modules, which
#               are the normal case. Instead the daemon re-applies the theme
#               when a value appears or disappears, so the compiled format is
#               always static and correctly chained. The value itself updates
#               live through the option and needs no recompile.
#
# mod_attr defaults to `nobold` rather than empty on purpose. tmux style
# attributes are sticky within a format string, so a segment that sets `bold`
# leaves every following segment bold until something clears it. Declaring the
# attribute on every segment is what stops one module's weight leaking into its
# neighbours.
#
# Every module in v0.2 is static: it compiles to a native tmux format and
# forks nothing. A module that needs a subprocess belongs behind the cache, not
# here.

LAIN_MODULES="layer knights node wired_path present_day psyche coolant layer_git"

lain_modules_load() {
	for _lm_m in $LAIN_MODULES; do
		# shellcheck source=/dev/null
		. "$LAIN_DIR/src/modules/$_lm_m.sh"
	done
}

lain_mod_reset() {
	mod_icon=""
	mod_text=""
	mod_fg="$c_fg_primary"
	mod_bg=""
	mod_attr="nobold"
	mod_cond=""
	mod_alt_fg=""
	mod_alt_bg=""
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

# lain_compile <name> <filled>
#
# Sets seg_text, seg_bg and seg_gate, or returns 1 if the module opted out. `filled` is
# whether the current separator style paints backgrounds; a flat style drops
# every bg and uses the module's fg directly, which is why a module declares
# both rather than a single style string.
lain_compile() {
	_lc_name="$1"
	_lc_filled="$2"

	lain_mod_reset
	"lain_mod_$_lc_name" || return 1

	# A gate and a conditional restyle cannot coexist. The gate wraps the whole
	# segment in a conditional and escapes every comma inside it, which would
	# break the commas belonging to an inner `#{?...}`. Restyling a segment
	# that may not exist is not a meaningful thing to ask for anyway.
	if [ -n "$mod_gate" ] && [ -n "$mod_cond" ]; then
		tmux display-message "lain.tmux: module $_lc_name sets both mod_gate and mod_cond"
		return 1
	fi

	for _lc_d in $mod_deps; do
		command -v "$_lc_d" >/dev/null 2>&1 || return 1
	done

	if [ -n "$mod_dynamic" ]; then
		# Nothing cached yet, or nothing to cache: leave the bar alone. A
		# battery module on a desktop never comes back, and a permanently
		# empty coloured block is worse than an absent segment.
		[ -n "$(tmux show -gqv "@lain_cache_${mod_dynamic}")" ] || return 1
		# Plain `#{@...}`, never `#{E:@...}`. The cache holds data, not format:
		# double expansion would evaluate whatever it contains, so a branch
		# named `#{session_name}` would render as the session name. The daemon
		# escapes `#` on the way in, since the drawn line is parsed for styles.
		mod_text="#{@lain_cache_${mod_dynamic}}"
	fi

	_lc_body="$(lain_icon "$mod_icon")$mod_text"

	if [ "$_lc_filled" = "yes" ] && [ -n "$mod_bg" ]; then
		seg_bg="$mod_bg"
		_lc_base="fg=${mod_fg}#,bg=${mod_bg}"
		_lc_alt="fg=${mod_alt_fg:-$mod_fg}#,bg=${mod_alt_bg:-$mod_bg}"
	else
		seg_bg=""
		# A flat segment reads as the fill colour, since that is the colour the
		# module actually identifies with. `layer` is ochre text flat, black on
		# ochre filled - same identity, different rendering.
		_lc_base="fg=${mod_bg:-$mod_fg}"
		_lc_alt="fg=${mod_alt_bg:-${mod_alt_fg:-${mod_bg:-$mod_fg}}}"
	fi

	[ -n "$mod_attr" ] && _lc_base="${_lc_base}#,${mod_attr}"
	[ -n "$mod_attr" ] && _lc_alt="${_lc_alt}#,${mod_attr}"

	seg_gate="$mod_gate"

	if [ -n "$mod_cond" ]; then
		seg_text="#{?${mod_cond},#[${_lc_alt}],#[${_lc_base}]} ${_lc_body} "
	else
		# Commas are unescaped here. Gating re-escapes the whole unit, which is
		# why that has to happen in the joiner, after separators are attached.
		seg_text="#[$(printf '%s' "$_lc_base" | sed 's/#,/,/g')] ${_lc_body} "
	fi
	return 0
}
