class_name FireSlimeModifier
extends UnitModifier

@export var value_1: int = 2
@export var value_2: int = 4
@export var value_3: int = 8

func get_modifier_value(p_level: int = 1) -> float:
	match p_level:
		1: return float(value_1)
		2: return float(value_2)
		3: return float(value_3)
	return float(value_1)

func apply_shop_modifier(source_idx: int, team_units: Array) -> void:
	var target_unit: UnitInstance = team_units[source_idx]
	target_unit.buff_burn(int(get_modifier_value(target_unit.level)))

func get_description(p_level: int = 1) -> String:
	return "%s\nGain [color=%s]+%d BURN[/color]" % [get_trigger_name(trigger), GameColors.DESC_BURN, int(get_modifier_value(p_level))]
