class_name EarthSlimeModifier
extends UnitModifier

@export var value_1: int = 5
@export var value_2: int = 10
@export var value_3: int = 20

func get_modifier_value(p_level: int = 1) -> float:
	match p_level:
		1: return float(value_1)
		2: return float(value_2)
		3: return float(value_3)
	return float(value_1)

func apply_effect(target_unit: UnitInstance, level: int) -> void:
	target_unit.buff_shield(int(get_modifier_value(level)))

func apply_shop_modifier(source_idx: int, team_units: Array) -> void:
	var target_unit: UnitInstance = team_units[source_idx]
	apply_effect(target_unit, target_unit.level)

func get_description(p_level: int = 1) -> String:
	return "%s\nGain [color=%s]+%d SHIELD[/color]" % [get_trigger_name(trigger), GameColors.DESC_SHIELD, int(get_modifier_value(p_level))]
