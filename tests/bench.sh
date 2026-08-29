#!/usr/bin/env sh
# Startup cost: wall time, and the process count that does not vary.

set -eu

cd "$(dirname "$0")/.."
PLUGIN_DIR="$(pwd)"
SOCKET="lain-bench-$$"
RUNS=10
MAX_MS="${LAIN_BENCH_MAX_MS:-250}"
MAX_EXECS=20

t() { tmux -L "$SOCKET" "$@"; }
cleanup() {
	t kill-server 2>/dev/null || true
	rm -f "/tmp/tmux-$(id -u)/$SOCKET"
	rm -f "${TMPDIR:-/tmp}/lain-bench-$$.trace" "${TMPDIR:-/tmp}/lain-bench-$$.env"
}
trap cleanup EXIT INT TERM

fail=0
t -f /dev/null new-session -d -x 120 -y 30

t run-shell "$PLUGIN_DIR/lain.tmux"

echo "-- wall time over $RUNS loads"
start="$(date +%s%N)"
i=0
while [ "$i" -lt "$RUNS" ]; do
	t run-shell "$PLUGIN_DIR/lain.tmux"
	i=$((i + 1))
done
end="$(date +%s%N)"
ms=$(((end - start) / RUNS / 1000000))

if [ "$ms" -le "$MAX_MS" ]; then
	printf 'ok    %-24s %s ms per load\n' "startup" "$ms"
else
	printf 'FAIL  startup took %s ms per load, over the %s ms ceiling\n' "$ms" "$MAX_MS"
	fail=1
fi

echo
echo "-- processes per load"
if command -v strace >/dev/null 2>&1; then
	envfile="${TMPDIR:-/tmp}/lain-bench-$$.env"
	trace="${TMPDIR:-/tmp}/lain-bench-$$.trace"
	t run-shell "env | grep '^TMUX=' > $envfile"
	# shellcheck disable=SC1090
	. "$envfile"
	export TMUX
	strace -f -e trace=execve -o "$trace" "$PLUGIN_DIR/src/core.sh" "$PLUGIN_DIR" \
		>/dev/null 2>&1 || true
	execs="$(grep -c 'execve(' "$trace" 2>/dev/null || echo 0)"
	if [ "$execs" -le "$MAX_EXECS" ]; then
		printf 'ok    %-24s %s (ceiling %s)\n' "execs per load" "$execs" "$MAX_EXECS"
		printf '      %s\n' "$(
			grep -o 'execve("[^"]*"' "$trace" |
				sed 's/execve("//; s/"//' |
				sed 's|.*/||' | sort | uniq -c | sort -rn | tr '\n' ' '
		)"
	else
		printf 'FAIL  %s execs per load, over the %s ceiling\n' "$execs" "$MAX_EXECS"
		printf '      %s\n' "$(
			grep -o 'execve("[^"]*"' "$trace" |
				sed 's/execve("//; s/"//' |
				sed 's|.*/||' | sort | uniq -c | sort -rn | tr '\n' ' '
		)"
		fail=1
	fi
else
	echo "skip  strace not installed; wall time only"
fi

[ "$fail" -eq 0 ] || {
	echo
	echo "benchmark failed"
	exit 1
}
echo
echo "benchmark passed"
