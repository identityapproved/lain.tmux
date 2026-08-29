#!/usr/bin/env sh
# Startup cost.
#
# The bar forks nothing per redraw, which is the design's headline claim. The
# matching risk is that startup quietly becomes expensive instead, since it runs
# on every session create and every reload. This guards that.
#
# Two assertions. Wall time is what a user feels, but it varies by an order of
# magnitude across machines, so its threshold is loose and exists only to catch
# a collapse. The process count is the real invariant: it does not move with the
# hardware, and every regression so far has shown up there first.
set -eu

cd "$(dirname "$0")/.."
PLUGIN_DIR="$(pwd)"
SOCKET="lain-bench-$$"
RUNS=10
# Wall time is hardware-dependent, so CI runners get to loosen it. The process
# ceiling is not overridable: that number should be the same everywhere.
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

# One warm run first: the first load pays for page cache and tmux's own lazy
# setup, which is not what is being measured.
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
	# run-shell hands the child a $TMUX pointing at this socket, so borrowing it
	# lets core.sh be traced directly instead of inside the tmux server.
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
