#!/usr/bin/env sh
# Value sanitizing and the daemon's lifecycle.

set -eu

cd "$(dirname "$0")/.."
PLUGIN_DIR="$(pwd)"
SOCKET="lain-daemon-$$"

# shellcheck source=src/cache.sh
. ./src/cache.sh

t() { tmux -L "$SOCKET" "$@"; }
cleanup() {
	t kill-server 2>/dev/null || true
	rm -f "/tmp/tmux-$(id -u)/$SOCKET"
}
trap cleanup EXIT INT TERM

fail=0

pollers() {
	_p_all=" $(pgrep -f "$PLUGIN_DIR/src/daemon/poll.sh" 2>/dev/null | tr '\n' ' ')"
	_p_n=0
	for _p_pid in $_p_all; do
		_p_par="$(ps -o ppid= -p "$_p_pid" 2>/dev/null | tr -d ' ')"
		if [ -n "$_p_par" ]; then
			case "$_p_all" in
			*" $_p_par "*) continue ;;
			esac
		fi
		_p_n=$((_p_n + 1))
	done
	printf '%s' "$_p_n"
}

san() {
	got="$(printf '%s' "$2" | lain_sanitize)"
	if [ "$got" = "$3" ]; then
		printf 'ok    %-28s %s\n' "$1" "$got"
	else
		printf 'FAIL  %-28s got [%s] want [%s]\n' "$1" "$got" "$3"
		fail=1
	fi
}

echo "-- sanitizing"
san "plain value" "main" "main"
san "style injection" 'x#[fg=red]y' 'x##[fg=red]y'
san "double hash" 'a#b#c' 'a##b##c'
san "percent left alone" '87%' '87%'
san "strftime spec left alone" '%H:%M' '%H:%M'
san "long value truncated" \
	"aaaaaaaaaabbbbbbbbbbccccccccccddddddddddeeeeeeeeee" \
	"aaaaaaaaaabbbbbbbbbbccccccccccdddddddddd"

echo
echo "-- pollers with no tmux involved"
# shellcheck source=src/modules/accela.sh
. ./src/modules/accela.sh
# shellcheck source=src/modules/duvet.sh
. ./src/modules/duvet.sh

eq() {
	if [ "$2" = "$3" ]; then
		printf 'ok    %-28s %s\n' "$1" "$2"
	else
		printf 'FAIL  %-28s got [%s] want [%s]\n' "$1" "$2" "$3"
		fail=1
	fi
}

eq "rate idle" "$(_lain_accela_rate 0)" "0B"
eq "rate counter reset" "$(_lain_accela_rate -8000)" "0B"
eq "rate bytes" "$(_lain_accela_rate 999)" "999B"
eq "rate kilobytes" "$(_lain_accela_rate 2048)" "2K"
eq "rate megabytes" "$(_lain_accela_rate 3145728)" "3M"

eq "track artist and title" "$(_lain_duvet_trim 'Boa - Duvet')" "Boa - Duvet"
eq "track without artist" "$(_lain_duvet_trim ' - Duvet')" "Duvet"
eq "track without title" "$(_lain_duvet_trim 'Boa - ')" "Boa"
eq "track with neither" "$(_lain_duvet_trim ' - ')" ""

# Two players registered, one of them idle: playerctl's default player is as
# likely to be the browser as the music daemon, so the pick has to look at all
# of them.
pick() { eq "$1" "$(_lain_duvet_pick "$2")" "$3"; }

pick "one player playing" "Playing|Boa - Duvet" "Boa - Duvet"
pick "playing beats paused" "Paused|Nobody - Elsewhere
Playing|Boa - Duvet" "Boa - Duvet"
pick "paused when none play" "Paused|Boa - Duvet
Paused|Nobody - Elsewhere" "Boa - Duvet"
pick "stopped ignored" "Stopped|Boa - Duvet" ""
pick "empty metadata skipped" "Playing| - 
Playing|Boa - Duvet" "Boa - Duvet"

if [ -r /proc/net/dev ]; then
	speed="$(lain_poll_accela)"
	case "$speed" in
	*[0-9][BKM]/*[0-9][BKM])
		printf 'ok    %-28s %s\n' "throughput sampled" "$speed"
		;;
	*)
		printf 'FAIL  %-28s got [%s]\n' "throughput sampled" "$speed"
		fail=1
		;;
	esac
else
	printf 'skip  %-28s no /proc/net/dev\n' "throughput sampled"
fi

# Whatever the platform answers, a poller returns one line or nothing - the
# daemon writes the result straight into a tmux option.
track="$(lain_poll_duvet || true)"
case "$track" in
*"
"*)
	printf 'FAIL  %-28s got [%s]\n' "track is one line" "$track"
	fail=1
	;;
*) printf 'ok    %-28s [%s]\n' "track is one line" "$track" ;;
esac

echo
echo "-- daemon lifecycle"
t -f /dev/null new-session -d -x 120 -y 30 -c "$PLUGIN_DIR"
t set -g @lain_modules_right "psyche present_day"
t set -g @lain_poll_interval 2
t run-shell "$PLUGIN_DIR/lain.tmux"

plan="$(t show -gqv @lain_daemon_modules)"
if [ "$plan" = "psyche" ]; then
	printf 'ok    %-28s %s\n' "plan lists dynamic only" "$plan"
else
	printf 'FAIL  plan was [%s], want [psyche]\n' "$plan"
	fail=1
fi

case "$(t show -gv status-right)" in
*lain_cache_psyche*)
	printf 'FAIL  module compiled in before it had any value\n'
	fail=1
	;;
*) printf 'ok    %-28s\n' "absent before first poll" ;;
esac

sleep 3
if [ -n "$(t show -gqv @lain_cache_psyche)" ]; then
	printf 'ok    %-28s %s\n' "cache filled" "$(t show -gqv @lain_cache_psyche)"
else
	printf 'FAIL  cache still empty after one interval\n'
	fail=1
fi

case "$(t show -gv status-right)" in
*lain_cache_psyche*) printf 'ok    %-28s\n' "rebuilt after first value" ;;
*)
	printf 'FAIL  status-right never picked the module up\n'
	fail=1
	;;
esac

t set -g @lain_modules_right "coolant psyche present_day"
t run-shell "$PLUGIN_DIR/lain.tmux"
sleep 3
if [ -z "$(t show -gqv @lain_cache_coolant)" ]; then
	case "$(t show -gv status-right)" in
	*lain_cache_coolant*)
		printf 'FAIL  empty module still compiled into the bar\n'
		fail=1
		;;
	*) printf 'ok    %-28s\n' "valueless module stays off" ;;
	esac
else
	printf 'skip  %-28s battery present on this host\n' "valueless module"
fi
if [ -n "$(t show -gqv @lain_daemon_beat)" ]; then
	printf 'ok    %-28s\n' "heartbeat written"
else
	printf 'FAIL  no heartbeat\n'
	fail=1
fi

id_before="$(t show -gqv @lain_daemon_id)"
i=0
while [ "$i" -lt 3 ]; do
	t run-shell "$PLUGIN_DIR/lain.tmux"
	i=$((i + 1))
done
sleep 1
id_after="$(t show -gqv @lain_daemon_id)"
running="$(pollers)"
if [ "$id_before" = "$id_after" ] && [ "$running" -eq 1 ]; then
	printf 'ok    %-28s 1 process across 4 loads\n' "no duplicate daemons"
else
	printf 'FAIL  id %s -> %s, %s processes running\n' "$id_before" "$id_after" "$running"
	pgrep -af "$PLUGIN_DIR/src/daemon/poll.sh" 2>/dev/null || true
	fail=1
fi

# A module added to or dropped from the config has to reach the running daemon:
# it sourced its modules once and polls whatever plan it was handed, so the plan
# changing under it is the one event that costs it the job.
t set -g @lain_modules_right "psyche present_day"
t run-shell "$PLUGIN_DIR/lain.tmux"
sleep 1
id_replanned="$(t show -gqv @lain_daemon_id)"
plan_replanned="$(t show -gqv @lain_daemon_modules)"
if [ "$id_replanned" != "$id_after" ] && [ "$plan_replanned" = "psyche" ]; then
	printf 'ok    %-28s %s\n' "plan change relaunches" "$plan_replanned"
else
	printf 'FAIL  id %s -> %s, plan [%s]\n' "$id_after" "$id_replanned" "$plan_replanned"
	fail=1
fi

sleep 3
running="$(pollers)"
if [ "$running" -eq 1 ]; then
	printf 'ok    %-28s\n' "superseded daemon exits"
else
	printf 'FAIL  %s pollers after the handover\n' "$running"
	pgrep -af "$PLUGIN_DIR/src/daemon/poll.sh" 2>/dev/null || true
	fail=1
fi

t kill-server 2>/dev/null || true
sleep 4
left="$(pollers)"
if [ "$left" -eq 0 ]; then
	printf 'ok    %-28s\n' "daemon exits with the server"
else
	printf 'FAIL  %s daemon(s) survived kill-server\n' "$left"
	fail=1
fi

[ "$fail" -eq 0 ] || {
	echo
	echo "daemon tests failed"
	exit 1
}
echo
echo "daemon tests passed"
