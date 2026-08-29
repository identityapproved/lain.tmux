#!/usr/bin/env sh
# One-minute load average.

lain_mod_psyche() {
	mod_icon="cpu"
	mod_dynamic="psyche"
	mod_fg="$c_fg_on_active"
	mod_bg="$c_fg_content"
}

lain_poll_psyche() {
	if [ -r /proc/loadavg ]; then
		cut -d' ' -f1 /proc/loadavg
	else
		uptime | sed 's/.*load averages*:[[:space:]]*//; s/[,[:space:]].*//'
	fi
}
