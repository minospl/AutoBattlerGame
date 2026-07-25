class_name WaterSlimeModifier
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

func apply_shop_modifier(source_idx: int, team_units: Array) -> void:
	var target_unit: UnitInstance = team_units[source_idx]
	target_unit.buff_heal(int(get_modifier_value(target_unit.level)))

func get_description(p_level: int = 1) -> String:
	return "%s\nGain [color=%s]+%d HEAL[/color]" % [get_trigger_name(trigger), GameColors.DESC_HEAL, int(get_modifier_value(p_level))]
