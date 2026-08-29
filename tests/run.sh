#!/usr/bin/env sh
# Everything, in the order a failure is cheapest to diagnose: static checks,
# then colour maths, then a real tmux server.
set -eu
cd "$(dirname "$0")"
./lint.sh
echo
../docs/gen-options.sh --check
echo
./palette.sh
echo
./contrast.sh
echo
./daemon.sh
echo
./smoke.sh
