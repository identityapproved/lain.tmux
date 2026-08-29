#!/usr/bin/env sh
# Print the options table straight from the defaults table in src/options.sh,
# so the README cannot document a default the code does not have.
#
#   docs/gen-options.sh          print the table
#   docs/gen-options.sh --check  fail if README.md is out of date
set -eu

cd "$(dirname "$0")/.."
# shellcheck source=src/options.sh
. ./src/options.sh

describe() {
	case "$1" in
	@lain_status_position) echo 'top or bottom' ;;
	@lain_status_interval) echo 'seconds between redraws' ;;
	@lain_status_justify) echo 'left, centre or right, for the window list' ;;
	@lain_separator) echo 'square, powerline, wire or none' ;;
	@lain_glyphs) echo 'ascii, unicode or nerd' ;;
	@lain_modules_left) echo 'modules on the left, in order' ;;
	@lain_modules_right) echo 'modules on the right, in order' ;;
	@lain_prefix_text) echo 'label for the knights module' ;;
	@lain_node_long) echo 'on for the full hostname instead of the short one' ;;
	@lain_path_full) echo 'on for the full path instead of the basename' ;;
	@lain_transparent) echo 'on drops the bar background to the terminal' ;;
	@lain_window_index) echo 'plain for 1:name, layer for LAYER:01 name' ;;
	@lain_show_prefix) echo 'flip the session segment while the prefix is pending' ;;
	@lain_show_date) echo 'show the date beside the clock' ;;
	@lain_date_format) echo 'strftime format for the date' ;;
	@lain_clock_format) echo 'strftime format for the clock' ;;
	@lain_status_left_length) echo 'character budget for the left segment' ;;
	@lain_status_right_length) echo 'character budget for the right segment' ;;
	@lain_poll_interval) echo 'seconds between background polls' ;;
	@lain_pane_border_status) echo 'off, top or bottom, for per-pane labels' ;;
	@lain_debug) echo 'keep the generated conf and report its path' ;;
	*) echo '' ;;
	esac
}

table() {
	echo '| Option | Default | Meaning |'
	echo '| --- | --- | --- |'
	lain_defaults | while read -r key value; do
		printf '| `%s` | `%s` | %s |\n' "$key" "$value" "$(describe "$key")"
	done
}

if [ "${1:-}" = "--check" ]; then
	if table | while IFS= read -r line; do
		grep -qF "$line" README.md || {
			printf 'missing from README.md: %s\n' "$line"
			exit 1
		}
	done; then
		echo "ok    README options table matches src/options.sh"
	else
		exit 1
	fi
else
	table
fi
