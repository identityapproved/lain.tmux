#!/usr/bin/env sh
# Network throughput, down over up.

lain_mod_accela() {
	mod_icon="net"
	mod_dynamic="accela"
	mod_fg="$c_fg_on_active"
	mod_bg="$c_fg_dim"
}

# A rate needs two samples. Taking both inside one poll, a second apart, keeps
# the reading instantaneous and the poller stateless - carrying the previous
# sample in a variable would not survive the command substitution the daemon
# calls this from.
lain_poll_accela() {
	[ -r /proc/net/dev ] || return 0
	_ac_a="$(_lain_accela_bytes)"
	sleep 1
	_ac_b="$(_lain_accela_bytes)"
	printf '%s/%s' \
		"$(_lain_accela_rate "$((${_ac_b%% *} - ${_ac_a%% *}))")" \
		"$(_lain_accela_rate "$((${_ac_b##* } - ${_ac_a##* }))")"
}

# Received and transmitted bytes across every interface but the loopback.
_lain_accela_bytes() {
	awk 'NR > 2 {
		gsub(/:/, " ")
		if ($1 != "lo") { rx += $2; tx += $10 }
	} END { printf "%d %d", rx, tx }' /proc/net/dev
}

# An interface going down resets its counters, so a negative delta reads as idle
# rather than as a huge number.
_lain_accela_rate() {
	_ar_v="$1"
	[ "$_ar_v" -gt 0 ] || _ar_v=0
	if [ "$_ar_v" -lt 1024 ]; then
		printf '%dB' "$_ar_v"
	elif [ "$_ar_v" -lt 1048576 ]; then
		printf '%dK' "$((_ar_v / 1024))"
	else
		printf '%dM' "$((_ar_v / 1048576))"
	fi
}
