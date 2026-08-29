#!/usr/bin/env sh
# WCAG contrast check over every foreground/background pair the theme renders.
#
# The lain ramps are low contrast by design - that is the look - so this is the
# guard that keeps faithfulness from crossing into unreadable. Pure awk, no
# dependencies, exits non-zero on any failure.
#
# Floors: 4.5:1 for text, 3.0:1 for non-text UI (borders, indicators).
set -eu

cd "$(dirname "$0")/.."
# shellcheck source=palettes/lain.sh
. ./palettes/lain.sh
# shellcheck source=src/palette.sh
. ./src/palette.sh
lain_palette_init

fail=0

# check <label> <fg> <bg> <floor>
check() {
	ratio="$(
		awk -v fg="$2" -v bg="$3" '
		# strtonum() is a gawk extension; mawk and the macOS awk lack it,
		# so parse the hex pair by hand and stay portable.
		function hexval(d,   p) {
			p = index("0123456789abcdef", tolower(d))
			return p - 1
		}
		function chan(h,   c) {
			c = (hexval(substr(h, 1, 1)) * 16 + hexval(substr(h, 2, 1))) / 255
			return (c <= 0.04045) ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4
		}
		function lum(hex) {
			sub(/^#/, "", hex)
			return 0.2126 * chan(substr(hex, 1, 2)) \
			     + 0.7152 * chan(substr(hex, 3, 2)) \
			     + 0.0722 * chan(substr(hex, 5, 2))
		}
		BEGIN {
			a = lum(fg); b = lum(bg)
			if (a < b) { t = a; a = b; b = t }
			printf "%.2f", (a + 0.05) / (b + 0.05)
		}'
	)"
	if awk -v r="$ratio" -v f="$4" 'BEGIN { exit !(r + 0 < f + 0) }'; then
		printf 'FAIL  %-34s %s on %s  %5s < %s\n' "$1" "$2" "$3" "$ratio" "$4"
		fail=1
	else
		printf 'ok    %-34s %s on %s  %5s\n' "$1" "$2" "$3" "$ratio"
	fi
}

echo "-- text, 4.5:1 floor"
check "bar text" "$c_fg_primary" "$c_bg_bar" 4.5
check "bar dim text" "$c_fg_dim" "$c_bg_bar" 4.5
check "session name" "$c_fg_content" "$c_bg_bar" 4.5
check "active window" "$c_fg_on_active" "$c_bg_active" 4.5
check "message" "$c_fg_content" "$c_bg_bar" 4.5
check "message command" "$c_fg_primary" "$c_bg_bar" 4.5
check "copy-mode selection" "$c_select_fg" "$c_select" 4.5
check "copy-mode match" "$c_fg_content" "$c_bg_surface" 4.5
check "copy-mode mark" "$c_fg_on_active" "$c_accent" 4.5
check "menu" "$c_fg_primary" "$c_bg_bar" 4.5
check "menu selected" "$c_fg_on_active" "$c_bg_active" 4.5
check "popup" "$c_fg_primary" "$c_bg_bar" 4.5
check "flag zoom on bar" "$c_flag_zoom" "$c_bg_bar" 4.5
check "flag bell on bar" "$c_flag_bell" "$c_bg_bar" 4.5
check "flag bell on fill" "$c_bell_on_fill" "$c_bg_active" 4.5
check "flag on fill" "$c_flag_on_fill" "$c_bg_active" 4.5
check "alert text" "$c_alert_fg" "$c_alert" 4.5
check "prefix active" "$c_fg_on_active" "$c_accent" 4.5

# Module fills. Each module that paints a background is a fg/bg pair of its
# own, and they have to stay distinct from each other as well as legible - two
# adjacent segments sharing a fill make a powerline separator invisible.
check "node fill" "$c_fg_on_active" "$c_fg_primary" 4.5
check "path fill" "$c_fg_on_active" "$c_fg_dim" 4.5

echo "-- non-text UI, 3.0:1 floor"
# The thin powerline separator is drawn in the bar colour against whichever
# fill it divides, so it has to read against every fill the modules use.
check "thin sep on ochre" "$c_bg_bar" "$c_bg_active" 3.0
check "thin sep on rose" "$c_bg_bar" "$c_fg_primary" 3.0
check "thin sep on dim" "$c_bg_bar" "$c_fg_dim" 3.0
check "wire separator" "$c_rule" "$c_bg_bar" 3.0
check "active pane border" "$c_border_active" "$c_bg_bar" 3.0
check "display-panes" "$c_fg_dim" "$c_bg_bar" 3.0

if [ "$fail" -ne 0 ]; then
	echo
	echo "contrast check failed"
	exit 1
fi
echo
echo "all pairs pass"
