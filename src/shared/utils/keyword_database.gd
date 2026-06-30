class_name KeywordDatabase
extends RefCounted

const KEYWORD_MAP: Dictionary = {
	# Stats
	"shield": { "title": "KEYWORD_SHIELD_TITLE", "desc": "KEYWORD_SHIELD_DESC" },
	"heal": { "title": "KEYWORD_HEAL_TITLE", "desc": "KEYWORD_HEAL_DESC" },
	"poison": { "title": "KEYWORD_POISON_TITLE", "desc": "KEYWORD_POISON_DESC" },
	"burn": { "title": "KEYWORD_BURN_TITLE", "desc": "KEYWORD_BURN_DESC" },
	"electrocute": { "title": "KEYWORD_ELECTRO_TITLE", "desc": "KEYWORD_ELECTRO_DESC" },
	"cast_speed": { "title": "KEYWORD_CAST_SPEED_TITLE", "desc": "KEYWORD_CAST_SPEED_DESC" },
	"gold": { "title": "KEYWORD_GOLD_TITLE", "desc": "KEYWORD_GOLD_DESC" },

	# Target Types
	"target_self": { "title": "KEYWORD_TARGET_SELF_TITLE", "desc": "KEYWORD_TARGET_SELF_DESC" },
	"target_horizontal": { "title": "KEYWORD_TARGET_HORIZONTAL_TITLE", "desc": "KEYWORD_TARGET_HORIZONTAL_DESC" },
	"target_vertical": { "title": "KEYWORD_TARGET_VERTICAL_TITLE", "desc": "KEYWORD_TARGET_VERTICAL_DESC" },
	"target_adjacent": { "title": "KEYWORD_TARGET_ADJACENT_TITLE", "desc": "KEYWORD_TARGET_ADJACENT_DESC" },
	"target_up": { "title": "KEYWORD_TARGET_UP_TITLE", "desc": "KEYWORD_TARGET_UP_DESC" },
	"target_down": { "title": "KEYWORD_TARGET_DOWN_TITLE", "desc": "KEYWORD_TARGET_DOWN_DESC" },
	"target_left": { "title": "KEYWORD_TARGET_LEFT_TITLE", "desc": "KEYWORD_TARGET_LEFT_DESC" },
	"target_right": { "title": "KEYWORD_TARGET_RIGHT_TITLE", "desc": "KEYWORD_TARGET_RIGHT_DESC" },
	"target_left_plus": { "title": "KEYWORD_TARGET_LEFT_PLUS_TITLE", "desc": "KEYWORD_TARGET_LEFT_PLUS_DESC" },
	"target_right_plus": { "title": "KEYWORD_TARGET_RIGHT_PLUS_TITLE", "desc": "KEYWORD_TARGET_RIGHT_PLUS_DESC" },
	"target_horizontal_plus": { "title": "KEYWORD_TARGET_HORIZONTAL_PLUS_TITLE", "desc": "KEYWORD_TARGET_HORIZONTAL_PLUS_DESC" },
	"target_all": { "title": "KEYWORD_TARGET_ALL_TITLE", "desc": "KEYWORD_TARGET_ALL_DESC" },

	# Triggers
	"trigger_battle_start": { "title": "KEYWORD_TRIGGER_BATTLE_START_TITLE", "desc": "KEYWORD_TRIGGER_BATTLE_START_DESC" },
	"trigger_cast": { "title": "KEYWORD_TRIGGER_CAST_TITLE", "desc": "KEYWORD_TRIGGER_CAST_DESC" },
	"trigger_take_damage": { "title": "KEYWORD_TRIGGER_TAKE_DAMAGE_TITLE", "desc": "KEYWORD_TRIGGER_TAKE_DAMAGE_DESC" },

	# Durations
	"duration_permanent": { "title": "KEYWORD_DURATION_PERMANENT_TITLE", "desc": "KEYWORD_DURATION_PERMANENT_DESC" },
	"duration_battle": { "title": "KEYWORD_DURATION_BATTLE_TITLE", "desc": "KEYWORD_DURATION_BATTLE_DESC" },
}

static func get_keywords_for_unit(unit: UnitInstance, lvl: int) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if not unit:
		return list

	# 1. Combat stats / status effects (Heal excluded as it is self-explanatory)
	if unit.shield > 0:
		list.append(_get_keyword_entry("shield"))
	if unit.poison > 0:
		list.append(_get_keyword_entry("poison"))
	if unit.burn > 0:
		list.append(_get_keyword_entry("burn"))
	if unit.electrocute > 0:
		list.append(_get_keyword_entry("electrocute"))

	# 2. Modifiers
	if unit.data and unit.data.modifier:
		var unit_modifier: UnitModifier = unit.data.modifier
		
		# Trigger
		match unit_modifier.trigger:
			UnitModifier.Trigger.ON_BATTLE_START:
				list.append(_get_keyword_entry("trigger_battle_start"))
			UnitModifier.Trigger.ON_CAST:
				list.append(_get_keyword_entry("trigger_cast"))
			UnitModifier.Trigger.ON_TAKE_DAMAGE:
				list.append(_get_keyword_entry("trigger_take_damage"))
				
		# Target Type (resolved dynamically via get_target(lvl), SELF is bypassed to reduce clutter)
		var target_type: UnitModifier.TargetType = unit_modifier.get_target(lvl)
		match target_type:
			UnitModifier.TargetType.HORIZONTAL:
				list.append(_get_keyword_entry("target_horizontal"))
			UnitModifier.TargetType.VERTICAL:
				list.append(_get_keyword_entry("target_vertical"))
			UnitModifier.TargetType.ADJACENT:
				list.append(_get_keyword_entry("target_adjacent"))
			UnitModifier.TargetType.UP:
				list.append(_get_keyword_entry("target_up"))
			UnitModifier.TargetType.DOWN:
				list.append(_get_keyword_entry("target_down"))
			UnitModifier.TargetType.LEFT:
				list.append(_get_keyword_entry("target_left"))
			UnitModifier.TargetType.RIGHT:
				list.append(_get_keyword_entry("target_right"))
			UnitModifier.TargetType.LEFT_PLUS:
				list.append(_get_keyword_entry("target_left_plus"))
			UnitModifier.TargetType.RIGHT_PLUS:
				list.append(_get_keyword_entry("target_right_plus"))
			UnitModifier.TargetType.HORIZONTAL_PLUS:
				list.append(_get_keyword_entry("target_horizontal_plus"))
			UnitModifier.TargetType.ALL:
				list.append(_get_keyword_entry("target_all"))

		# 3. Dynamic keywords declared by the modifier script itself
		if unit_modifier.has_method("get_implied_keywords"):
			var implied: Array[String] = unit_modifier.call("get_implied_keywords")
			for kw_key: String in implied:
				var str_key: String = str(kw_key)
				if not _has_keyword(list, str_key):
					list.append(_get_keyword_entry(str_key))

	return list

static func _get_keyword_entry(key: String) -> Dictionary:
	var entry: Dictionary = KEYWORD_MAP[key]
	return {
		"title": TranslationServer.translate(str(entry["title"])),
		"desc": TranslationServer.translate(str(entry["desc"]))
	}

static func _has_keyword(list: Array[Dictionary], key: String) -> bool:
	var entry: Dictionary = KEYWORD_MAP[key]
	var title_to_check: String = TranslationServer.translate(str(entry["title"]))
	for item: Dictionary in list:
		if item["title"] == title_to_check:
			return true
	return false
