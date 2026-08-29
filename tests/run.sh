#!/usr/bin/env sh
# Everything, ordered so a failure is cheapest to diagnose: static checks
# first, then the ones that reason about colour, then the ones that need a real
# tmux server, then the slow ones.
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
echo
./snapshot.sh
echo
./bench.sh
