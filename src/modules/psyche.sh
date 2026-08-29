#!/usr/bin/env sh
# One-minute load average.
#
# Load rather than a CPU percentage: a percentage needs two samples and a delta,
# which means state in the daemon, and it is the less useful number anyway.
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
		# BSD and macOS. `uptime` output varies ("load average:" vs "load
		# averages:"), so match both and take the first figure.
		uptime | sed 's/.*load averages*:[[:space:]]*//; s/[,[:space:]].*//'
	fi
}
