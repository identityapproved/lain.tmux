#!/usr/bin/env sh
# Static checks: shellcheck, shfmt, sh -n.

set -eu

cd "$(dirname "$0")/.."
fail=0

if command -v shellcheck >/dev/null 2>&1; then
	if shellcheck src/core.sh src/daemon/poll.sh tests/contrast.sh tests/smoke.sh \
		tests/lint.sh tests/daemon.sh tests/snapshot.sh tests/bench.sh; then
		echo "ok    shellcheck (sh)"
	else
		fail=1
	fi
	if shellcheck -s bash lain.tmux; then
		echo "ok    shellcheck (bash entry point)"
	else
		fail=1
	fi
	if shellcheck -e SC2154 src/modules/*.sh; then
		echo "ok    shellcheck (modules)"
	else
		fail=1
	fi
else
	echo "skip  shellcheck not installed"
fi

for f in src/*.sh src/modules/*.sh src/daemon/*.sh palettes/*.sh tests/*.sh docs/*.sh; do
	if sh -n "$f"; then
		printf 'ok    sh -n %s\n' "$f"
	else
		printf 'FAIL  sh -n %s\n' "$f"
		fail=1
	fi
done

if command -v shfmt >/dev/null 2>&1; then
	if shfmt -d -ln posix -i 0 src/*.sh src/modules/*.sh src/daemon/*.sh palettes/*.sh tests/*.sh docs/*.sh; then
		echo "ok    shfmt"
	else
		echo "FAIL  shfmt: run tests/lint.sh --fix"
		fail=1
	fi
	if [ "${1:-}" = "--fix" ]; then
		shfmt -w -ln posix -i 0 src/*.sh src/modules/*.sh src/daemon/*.sh palettes/*.sh tests/*.sh docs/*.sh
		echo "ok    shfmt rewrote files"
		fail=0
	fi
else
	echo "skip  shfmt not installed"
fi

[ "$fail" -eq 0 ] || {
	echo
	echo "lint failed"
	exit 1
}
echo
echo "lint passed"
