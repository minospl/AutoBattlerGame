class_name GameColors
extends Node

# Card and Slot borders
const BORDER_OUTER_DEFAULT = Color(0.57, 0.58, 0.65, 1) # Grey-blue
const BORDER_INNER_DEFAULT = Color(0.88, 0.89, 0.91, 1) # Light grey
const PANEL_BORDER_DEFAULT = Color(0.29, 0.251, 0.255, 1.0)
const GOLDEN_BORDER = Color(0.95, 0.72, 0.15, 1.0) # Golden yellow

# Hover interaction borders
const SLOT_HOVER_OUTER_BORDER = Color(0.259, 0.614, 0.282, 1) # Green
const SLOT_HOVER_INNER_BORDER = Color(0.718, 0.99, 0.721, 1) # Light green

# Card background and corners
const WHITE_COLOR = Color(1, 1, 1, 1.0) # Solid off-white
const TRANSPARENT = Color(0, 0, 0, 0.0) # Transparent

# Statistics panel backgrounds
const STAT_ATTACK_BG = Color(0.92, 0.22, 0.38, 1) # Pink-red
const STAT_POISON_BG = Color(0.55, 0.27, 0.77, 1) # Violet-purple

# Section Header Banners
const BENCH_HEADER_BG = Color(0.95, 0.72, 0.18, 1) # Yellow (#f1b82d)
const TEAM_HEADER_BG = Color(0.89, 0.31, 0.44, 1) # Pink (#e24f70)
const LABEL_OUTLINE = Color(0.1, 0.1, 0.1, 1) # Black outline

# Control Panel Buttons
const BTN_GREEN_NORMAL = Color(0.15, 0.50, 0.30, 1) # Flat emerald green
const BTN_GREEN_HOVER = Color(0.18, 0.60, 0.36, 1) # Brighter green on hover
const BTN_GREEN_PRESSED = Color(0.12, 0.40, 0.24, 1)
const BTN_DARK_NORMAL = Color(0.10, 0.11, 0.13, 1) # Sleek dark
const BTN_RED_HOVER = Color(0.15, 0.163, 0.189, 1.0) # Red tint on hover
const BTN_RED_PRESSED = Color(0.173, 0.188, 0.217, 1.0)

# Card portrait fallback text color
const PORTRAIT_FALLBACK_TEXT = Color(0.2, 0.2, 0.2, 0.75)

# Tooltip Description Formatting Colors (Hex Strings)
const DESC_TRIGGER = "#f2b726"  # Standardized bright gold for all triggers
const DESC_TARGET = "#ffffff"   # Standardized bright blue for all targets/directions
const DESC_ATTACK = "#27ae60"   # Standardized green for Attack buffs
const DESC_HEALTH = "#c0392b"   # Standardized dark red for Health buffs
const DESC_SHIELD = "#2980b9"   # Standardized blue for Shield buffs
const DESC_HEAL = "#27ae60"     # Standardized green for heals
const DESC_POISON = "#8e44ad"   # Standardized purple for poison