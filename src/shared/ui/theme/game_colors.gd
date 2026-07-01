class_name GameColors
extends Node

# Card and Slot borders
const BORDER_OUTER_DEFAULT : Color = Color(0.57, 0.58, 0.65, 1) # Grey-blue
const BORDER_INNER_DEFAULT : Color= Color(0.88, 0.89, 0.91, 1) # Light grey
const PANEL_BORDER_DEFAULT : Color= Color(0.29, 0.251, 0.255, 1.0)
const GOLDEN_BORDER : Color = Color(0.95, 0.72, 0.15, 1.0) # Golden yellow

# Hover interaction borders
const SLOT_HOVER_OUTER_BORDER : Color = Color(0.259, 0.614, 0.282, 1) # Green
const SLOT_HOVER_INNER_BORDER : Color = Color(0.718, 0.99, 0.721, 1) # Light green

# Card background and corners
const WHITE_COLOR : Color = Color(1, 1, 1, 1.0) # Solid off-white
const TRANSPARENT : Color = Color(0, 0, 0, 0.0) # Transparent

# Card portrait fallback text color
const PORTRAIT_FALLBACK_TEXT : Color = Color(0.2, 0.2, 0.2, 0.75)

# Tooltip Description Formatting Colors (Hex Strings)
const DESC_TRIGGER : String = "#f2b726"  # Standardized bright gold for all triggers
const DESC_TARGET : String = "#ffffff"   # Standardized bright blue for all targets/directions
const DESC_ATTACK : String = "#c0392b"   # Standardized green for Attack buffs
const DESC_HEALTH : String = "#27ae60"   # Standardized dark red for Health buffs
const DESC_HEAL : String = "#27ae60"     # Standardized green for heals
const DESC_SHIELD : String = "#b3b3b3"   # Standardized blue for Shield buffs 
const DESC_POISON : String = "#8e44ad"   # Standardized purple for poison
const DESC_BURN : String = "#e67e22"     # Standardized Orange for burn
const DESC_ELECTROCUTE : String = "#f1c40f" # Standardized Yellow for electrocute
const DESC_GOLD : String = "#ffd700"         # Gold color
const DESC_CAST_SPEED : String = "#54a0ff"   # Light blue for cast speed / cd reduction
