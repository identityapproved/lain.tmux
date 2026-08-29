#!/usr/bin/env sh
# Glyph tiers, selected by @lain_glyphs. ascii is the safe default.

lain_glyph() {
	case "$_lain_glyphset:$1" in
	nerd:session) printf '\356\202\245' ;;
	nerd:prefix) printf '\356\254\230' ;;
	nerd:node) printf '\357\210\250' ;;
	nerd:path) printf '\357\204\225' ;;
	nerd:clock) printf '\357\200\227' ;;
	nerd:cpu) printf '\357\222\274' ;;
	nerd:battery) printf '\357\211\200' ;;
	nerd:branch) printf '\356\234\245' ;;
	nerd:sep_right) printf '\356\202\260' ;;
	nerd:sep_left) printf '\356\202\262' ;;
	nerd:sep_right_thin) printf '\356\202\261' ;;
	nerd:sep_left_thin) printf '\356\202\263' ;;
	nerd:wire) printf '\342\224\200' ;;

	unicode:session) printf '\342\227\206' ;;
	unicode:prefix) printf '\342\227\211' ;;
	unicode:node) printf '\342\226\252' ;;
	unicode:path) printf '\342\226\270' ;;
	unicode:clock) printf '\342\227\213' ;;
	unicode:cpu) printf '\342\226\244' ;;
	unicode:battery) printf '\342\226\256' ;;
	unicode:branch) printf '\342\221\202' ;;
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

lain_icon() {
	_li_g="$(lain_glyph "$1")"
	[ -n "$_li_g" ] && printf '%s ' "$_li_g"
}
