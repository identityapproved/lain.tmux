#!/usr/bin/env bash
# Plugin entry point: resolve the plugin directory, hand it to the core.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$CURRENT_DIR/src/core.sh" "$CURRENT_DIR"
