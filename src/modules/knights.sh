#!/usr/bin/env sh
# Standalone prefix indicator.
#
# Opt-in, and off by default because `layer` already signals the prefix by
# flipping colour. Worth adding when the session segment is not on the bar, or
# when a fixed-width indicator is easier to catch than a colour change.
#
# The segment collapses to nothing when the prefix is not pending, so it costs
# no width at rest.
lain_mod_knights() {
	mod_icon="prefix"
	mod_text="$(lain_get @lain_prefix_text)"
	mod_fg="$c_fg_on_active"
	mod_bg="$c_accent"
	mod_attr="bold"
	# Not mod_cond: the segment should not exist at all when the prefix is not
	# pending, rather than sit there restyled.
	#
	# Under `powerline` a gated segment opens from its neighbour and closes
	# back to it, so while the gate is open there is a one-cell sliver of the
	# previous fill between the two glyphs. That is the price of keeping the
	# chain correct without making every following separator conditional on
	# every preceding gate, and it is only visible while the prefix is held.
	mod_gate="client_prefix"
}
