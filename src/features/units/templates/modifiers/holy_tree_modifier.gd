class_name HolyTreeModifier
extends UnitModifier

@export var value_1: int = 5
@export var value_2: int = 20
@export var value_3: int = 50
	
func get_target(_p_level: int = 1) -> TargetType:
	return TargetType.ALL

func get_heal_value(p_level: int = 1) -> int:
	match p_level:
		1: return value_1
		2: return value_2
		3: return value_3
	return value_1

func apply_modifier(source_idx: int, team_obj: BattleTeamModel) -> void:
	var unit: UnitInstance = team_obj.units[source_idx]
	var current_level: int = unit.level if unit else 1
	var heal_amount: int = get_heal_value(current_level)
	team_obj.heal(heal_amount, source_idx)

func get_description(p_level: int = 1) -> String:
	return "%s\nHeals team shared health pool for [color=%s]+%d HP[/color]." % [get_trigger_name(Trigger.ON_CAST), GameColors.DESC_HEAL, get_heal_value(p_level)]