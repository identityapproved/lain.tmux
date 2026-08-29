#!/usr/bin/env sh
# Every check, cheapest failure first.

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
