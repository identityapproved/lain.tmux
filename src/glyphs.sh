#!/usr/bin/env sh
# Glyph sets.
#
# Three tiers, selected by `@lain_glyphs`. `ascii` is the default: it is the
# only tier guaranteed to render in every terminal and font, and a theme whose
# default install shows tofu is a broken theme. `nerd` looks best and is what
# the screenshots use.
#
# Font presence cannot be detected from inside tmux, so this is a declaration
# by the user, never a guess.

# lain_glyph <key> - the glyph for the active tier, or empty if that tier has
# none. An empty glyph is legitimate: the ascii tier deliberately omits
# decorative icons rather than substituting punctuation that reads as noise.
lain_glyph() {
	case "$_lain_glyphset:$1" in
	nerd:session) printf '\356\202\245' ;;        # nf-oct-server
	nerd:prefix) printf '\356\254\230' ;;         # nf-oct-key
	nerd:node) printf '\357\210\250' ;;           # nf-fa-hdd
	nerd:path) printf '\357\204\225' ;;           # nf-fa-folder
	nerd:clock) printf '\357\200\227' ;;          # nf-fa-clock
	nerd:cpu) printf '\357\222\274' ;;            # nf-oct-cpu
	nerd:battery) printf '\357\211\200' ;;        # nf-fa-battery
	nerd:branch) printf '\356\234\245' ;;         # nf-dev-git-branch
	nerd:sep_right) printf '\356\202\260' ;;      # powerline right
	nerd:sep_left) printf '\356\202\262' ;;       # powerline left
	nerd:sep_right_thin) printf '\356\202\261' ;; # powerline right, thin
	nerd:sep_left_thin) printf '\356\202\263' ;;  # powerline left, thin
	nerd:wire) printf '\342\224\200' ;;

	unicode:session) printf '\342\227\206' ;; # black diamond
	unicode:prefix) printf '\342\227\211' ;;  # fisheye
	unicode:node) printf '\342\226\252' ;;    # black small square
	unicode:path) printf '\342\226\270' ;;    # black right pointer
	unicode:clock) printf '\342\227\213' ;;   # white circle
	unicode:cpu) printf '\342\226\244' ;;     # square with horizontal fill
	unicode:battery) printf '\342\226\256' ;; # black vertical rectangle
	unicode:branch) printf '\342\221\202' ;;  # ocr fork
	unicode:sep_right) printf '\342\226\266' ;;
	unicode:sep_left) printf '\342\227\200' ;;
	unicode:sep_right_thin) printf '\342\224\202' ;;
	unicode:sep_left_thin) printf '\342\224\202' ;;
	unicode:wire) printf '\342\224\200' ;;

	ascii:sep_right) printf '>' ;;
	ascii:sep_left) printf '<' ;;
	ascii:sep_right_thin) printf '|' ;;
	ascii:sep_left_thin) printf '|' ;;
	ascii:wire) printf '-' ;;
	ascii:*) printf '' ;;

	*) printf '' ;;
	esac
}

lain_glyphs_init() {
	_lain_glyphset="$(lain_get @lain_glyphs)"
	case "$_lain_glyphset" in
	nerd | unicode | ascii) ;;
	*) _lain_glyphset="ascii" ;;
	esac
}

# lain_icon <key> - the glyph plus its trailing space, or nothing at all when
# the tier has no glyph. Callers concatenate this directly, so the spacing has
# to live here; otherwise the ascii tier renders a stray leading space in every
# segment.
lain_icon() {
	_li_g="$(lain_glyph "$1")"
	[ -n "$_li_g" ] && printf '%s ' "$_li_g"
}
