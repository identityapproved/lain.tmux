#!/usr/bin/env sh
# The lain palette: three ramps, Back / Fore / High.
#
# This file is the whole colour vocabulary. Nothing else in the plugin names a
# hex; roles are bound to steps in src/palette.sh and everything downstream
# reads a role. Add a colour here, or not at all.
#
# Pairing rule: rose on black for chrome, ochre on black for content, black on
# ochre for selection. Never rose text on an ochre fill or the reverse - the
# two ramps sit close in luminance and the pairing goes muddy.
#
# The trailing comment on each line is the nearest xterm-256 index. tmux needs
#
#     set -as terminal-features "*:RGB"
#
# to take these hex values directly. Without it the ochre and rose ramps
# quantise onto the same xterm pink band and stop being distinct.

# Back - neutral greys. Surfaces, panels, layering. Runs dark to light.
lain_back_1="#000000"  # 16
lain_back_2="#1A1A1A"  # 234
lain_back_3="#2A2A2A"  # 235
lain_back_4="#3A3A3A"  # 237
lain_back_5="#4A4A4A"  # 239
lain_back_6="#5A5A5A"  # 240
lain_back_7="#6A6A6A"  # 242
lain_back_8="#7A7A7A"  # 243
lain_back_9="#8A8A8A"  # 245
lain_back_10="#9A9A9A" # 247
lain_back_11="#AAAAAA" # 248
lain_back_12="#BABABA" # 250

# Fore - rose. Primary text, borders, focus, identity. Bright to dark.
lain_fore_1="#CE7688"  # 174
lain_fore_2="#BA6A7B"  # 132
lain_fore_3="#A05969"  # 131
lain_fore_4="#965363"  # 95
lain_fore_5="#8E4E5D"  # 95
lain_fore_6="#804654"  # 95
lain_fore_7="#6F3D49"  # 239
lain_fore_8="#5D333C"  # 238
lain_fore_9="#49272F"  # 236
lain_fore_10="#381E24" # 235
lain_fore_11="#2A171B" # 234
lain_fore_12="#1D0F12" # 233

# High - ochre. Accents, selection, emphasis, metadata. Bright to dark.
lain_high_1="#C1B48E"  # 144
lain_high_2="#B5A985"  # 144
lain_high_3="#A49978"  # 138
lain_high_4="#968C6E"  # 101
lain_high_5="#897F63"  # 101
lain_high_6="#7A7158"  # 95
lain_high_7="#69614C"  # 59
lain_high_8="#5A5341"  # 239
lain_high_9="#4E4838"  # 238
lain_high_10="#403C2E" # 237
lain_high_11="#332F24" # 236
lain_high_12="#221F18" # 234

# Semantic and status colours. Off-ramp; use only for the meanings named.
lain_accent="#FFB1C3"     # 217  brightest rose, urgent focus
lain_success_fg="#FFDCB9" # 223  positive text
lain_error_bg="#930006"   # 88   error and destructive fill
lain_error_fg="#680003"   # 52   deep red, fill only, never text on black
