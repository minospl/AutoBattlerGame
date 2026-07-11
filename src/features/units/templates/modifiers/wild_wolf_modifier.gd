class_name WildWolfModifier
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

func apply_modifier(source_idx: int, team_obj: BattleTeam) -> void:
	var unit: UnitInstance = team_obj.units[source_idx]
	var current_level: int = unit.level if unit else 1
	var buff: int = int(get_modifier_value(current_level))
	
	var current_target: TargetType = get_target(current_level)
	for idx: int in TargetResolver.get_target_indices(source_idx, current_target, team_obj.has_magnetic_core):
		team_obj.buff_unit_attack(idx, buff, false)

func get_description(p_level: int = 1) -> String:
	var target_str: String = "[color=%s]ADJACENT[/color] allies" % GameColors.DESC_TARGET
	var buff: int = int(get_modifier_value(p_level))
	return "%s\nGive %s [color=%s]+%d Attack[/color] for this battle" % [get_trigger_name(), target_str, GameColors.DESC_ATTACK, buff]
