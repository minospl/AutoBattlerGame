class_name RiverCrabModifier
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

func apply_modifier(source_idx: int, team_obj: BattleTeamModel) -> void:
	var unit: UnitInstance = team_obj.units[source_idx]
	var current_level: int = unit.level if unit else 1
	team_obj.buff_unit_attack(source_idx, int(get_modifier_value(current_level)))

func get_description(p_level: int = 1) -> String:
	return "%s\nGain [color=%s]+%d ATK[/color] for this battle" % [get_trigger_name(), GameColors.DESC_ATTACK, int(get_modifier_value(p_level))]
