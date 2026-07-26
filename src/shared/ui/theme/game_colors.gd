class_name GameColors
extends Node

# Card and Slot borders
const BORDER_OUTER_DEFAULT: Color = Color(0.57, 0.58, 0.65, 1) # Grey-blue
const BORDER_INNER_DEFAULT: Color = Color(0.88, 0.89, 0.91, 1) # Light grey
const PANEL_BORDER_DEFAULT: Color = Color(0.3, 0.25, 0.25, 1.0)
const GOLDEN_BORDER: Color = Color(0.95, 0.72, 0.15, 1.0) # Golden yellow

# Hover interaction borders
const SLOT_HOVER_OUTER_BORDER: Color = Color(0.259, 0.614, 0.282, 1) # Green
const SLOT_HOVER_INNER_BORDER: Color = Color(0.718, 0.99, 0.721, 1) # Light green

# Card background and corners
const WHITE_COLOR: Color = Color(1, 1, 1, 1.0) # Solid off-white
const TRANSPARENT: Color = Color(0, 0, 0, 0.0) # Transparent

# Card portrait fallback text color
const PORTRAIT_FALLBACK_TEXT: Color = Color(0.2, 0.2, 0.2, 0.75)

# Tooltip Description Formatting Colors (Hex Strings)
const DESC_TRIGGER: String = "#f2b726" # Standardized bright gold for all triggers
const DESC_TARGET: String = "#f2b726" # Standardized bright blue for all targets/directions
const DESC_ATTACK: String = "#c0392b" # Standardized green for Attack buffs
const DESC_HEALTH: String = "#27ae60" # Standardized dark red for Health buffs
const DESC_HEAL: String = "#1e88e5" # Standardized blue for heals
const DESC_SHIELD: String = "#b3b3b3" # Standardized blue for Shield buffs
const DESC_POISON: String = "#8e44ad" # Standardized purple for poison
const DESC_BURN: String = "#e67e22" # Standardized Orange for burn
const DESC_ELECTROCUTE: String = "#f1c40f" # Standardized Yellow for electrocute
const DESC_GOLD: String = "#ffd700" # Gold color
const DESC_ITEM: String = "#2e73b8" # Sleek blue matching BADGE_COLOR_ITEM
const DESC_CAST_SPEED: String = "#ffffff" # White/default text color for cast speed / cd reduction

# Rarity Description Formatting Colors (Hex Strings)
const DESC_COMMON: String = "#708094" # Grey for common rarity
const DESC_UNCOMMON: String = "#33bf59" # Green for uncommon rarity
const DESC_RARE: String = "#3082cf" # Blue for rare rarity
const DESC_EPIC: String = "#8059d6" # Purple for epic rarity
const DESC_LEGENDARY: String = "#d69e2e" # Gold for legendary rarity
const DESC_UNIQUE: String = "#e61a33" # Ruby-red for unique rarity

# Unit Type Description Formatting Colors (Hex Strings)
const DESC_TYPE_EARTH: String = "#78350f" # Earth brown
const DESC_TYPE_PLANT: String = "#2ecc71" # Plant green
const DESC_TYPE_WATER: String = "#1e88e5" # Water blue
const DESC_TYPE_DRAGON: String = "#e61a33" # Dragon red
const DESC_TYPE_BEAST: String = "#d35400" # Beast orange
const DESC_TYPE_TOXIC: String = "#8e44ad" # Toxic purple
const DESC_TYPE_ELECTRIC: String = "#f1c40f" # Electric yellow
const DESC_TYPE_FIRE: String = "#e67e22" # Fire orange-red
const DESC_TYPE_SLIME: String = "#949eab" # Slime grey

# Compendium Tab Buttons
const TAB_ACTIVE_NORMAL: Color = Color(0.12, 0.45, 0.22, 1.0) # Green
const TAB_ACTIVE_HOVER: Color = Color(0.15, 0.55, 0.27, 1.0)
const TAB_ACTIVE_PRESSED: Color = Color(0.18, 0.65, 0.32, 1.0)

const TAB_INACTIVE_NORMAL: Color = Color(0.18, 0.24, 0.35, 1.0) # Blue
const TAB_INACTIVE_HOVER: Color = Color(0.23, 0.31, 0.45, 1.0)
const TAB_INACTIVE_PRESSED: Color = Color(0.13, 0.18, 0.27, 1.0)
