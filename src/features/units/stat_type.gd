class_name StatType
extends Object

enum Type {
	HP,
	ATK,
	HEAL,
	SHIELD,
	POISON,
	BURN,
	ELECTROCUTE
}

static func get_stat_name(p_type: Type) -> String:
	match p_type:
		Type.HP: return "HP"
		Type.ATK: return "ATK"
		Type.HEAL: return "HEAL"
		Type.SHIELD: return "SHIELD"
		Type.POISON: return "POISON"
		Type.BURN: return "BURN"
		Type.ELECTROCUTE: return "ELECTROCUTE"
	return ""

static func get_stat_color(p_type: Type) -> Color:
	match p_type:
		Type.HP: return Color(GameColors.DESC_HEALTH)
		Type.ATK: return Color(GameColors.DESC_ATTACK)
		Type.HEAL: return Color(GameColors.DESC_HEAL)
		Type.SHIELD: return Color(GameColors.DESC_SHIELD)
		Type.POISON: return Color(GameColors.DESC_POISON)
		Type.BURN: return Color(GameColors.DESC_BURN)
		Type.ELECTROCUTE: return Color(GameColors.DESC_ELECTROCUTE)
	return Color.WHITE

static func get_color_hex(p_type: Type) -> String:
	match p_type:
		Type.HP: return GameColors.DESC_HEALTH
		Type.ATK: return GameColors.DESC_ATTACK
		Type.HEAL: return GameColors.DESC_HEAL
		Type.SHIELD: return GameColors.DESC_SHIELD
		Type.POISON: return GameColors.DESC_POISON
		Type.BURN: return GameColors.DESC_BURN
		Type.ELECTROCUTE: return GameColors.DESC_ELECTROCUTE
	return "#ffffff"
