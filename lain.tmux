#!/usr/bin/env bash
# Plugin entry point.
#
#   set -g @plugin 'identityapproved/lain.tmux'
#
# A plugin manager sources every *.tmux file at the plugin root, so this stays a
# shim: work out where the plugin lives and hand that to the POSIX sh core.
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$CURRENT_DIR/src/core.sh" "$CURRENT_DIR"
