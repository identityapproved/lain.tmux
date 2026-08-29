#!/usr/bin/env sh
# Palette conformance.
#
# The rule is: resolve the role, read the hex, never invent a value. That is
# only a rule if something checks it, so this asserts the two properties that
# make it structural rather than a habit:
#
#   1. No file outside palettes/ names a raw hex. Format strings and style
#      options read semantic tokens; the tokens read ramp steps.
#   2. Every token in palette.sh binds to a `lain_*` ramp variable, never to a
#      literal. A token assigned a bare hex is an invented value wearing a
#      role's name, which is exactly how the palette drifts.
set -eu

cd "$(dirname "$0")/.."
fail=0

echo "-- no raw hex outside palettes/"
for f in src/status.sh src/window.sh src/surfaces.sh src/options.sh src/core.sh \
	src/registry.sh src/glyphs.sh src/cache.sh src/daemon/poll.sh \
	src/modules/*.sh lain.tmux; do
	# Strip comments first: the commentary quotes hexes to explain choices,
	# which is documentation, not a colour the theme emits.
	hits="$(sed 's/#[[:space:]].*$//' "$f" | grep -oE '#[0-9A-Fa-f]{6}\b' || true)"
	if [ -n "$hits" ]; then
		printf 'FAIL  %s names a raw hex: %s\n' "$f" "$(printf '%s' "$hits" | tr '\n' ' ')"
		fail=1
	else
		printf 'ok    %s\n' "$f"
	fi
done

echo
echo "-- every token binds to a ramp step"
tokens=0
while IFS= read -r line; do
	name="${line%%=*}"
	name="${name## }"
	value="${line#*=}"
	tokens=$((tokens + 1))
	case "$value" in
	'"$lain_'*) printf 'ok    %-16s -> %s\n' "$name" "${value%\"}" ;;
	*)
		printf 'FAIL  %-16s is a literal: %s\n' "$name" "$value"
		fail=1
		;;
	esac
done <<EOF
$(grep -oE '^[[:space:]]*c_[a-z_]+="[^"]*"' src/palette.sh | sed 's/^[[:space:]]*//')
EOF
printf '      %s tokens checked\n' "$tokens"

echo
echo "-- every ramp step is traceable"
# Each ramp line must carry its xterm index. A step without one was added by
# eye rather than taken from the palette, and has no 256-colour fallback.
missing="$(grep -E '^lain_[a-z_0-9]+="#[0-9A-F]{6}"' palettes/lain.sh | grep -vcE '#[[:space:]]*[0-9]+' || true)"
if [ "$missing" -eq 0 ]; then
	printf 'ok    every ramp step carries its xterm index\n'
else
	printf 'FAIL  %s ramp step(s) missing an xterm index\n' "$missing"
	fail=1
fi

[ "$fail" -eq 0 ] || {
	echo
	echo "palette conformance failed"
	exit 1
}
echo
echo "palette conformance passed"
