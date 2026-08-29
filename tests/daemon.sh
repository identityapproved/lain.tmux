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
running="$(pgrep -f "$PLUGIN_DIR/src/daemon/poll.sh" 2>/dev/null | wc -l)"
if [ "$id_before" = "$id_after" ] && [ "$running" -eq 1 ]; then
	printf 'ok    %-28s 1 process across 4 loads\n' "no duplicate daemons"
else
	printf 'FAIL  id %s -> %s, %s processes running\n' "$id_before" "$id_after" "$running"
	fail=1
fi

t kill-server 2>/dev/null || true
sleep 4
left="$(pgrep -f "$PLUGIN_DIR/src/daemon/poll.sh" 2>/dev/null | wc -l)"
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
