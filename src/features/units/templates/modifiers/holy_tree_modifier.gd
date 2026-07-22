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
	var heal_buff: int = get_heal_value(unit.level)
	for idx: int in TargetResolver.get_target_indices(source_idx, get_target(unit.level), team_obj.has_magnetic_core, team_obj.has_focusing_lens):
		team_obj.buff_unit_heal_power(idx, heal_buff, true)

func get_description(p_level: int = 1) -> String:
	var target_str: String = "[color=%s]ALL[/color] allies" % GameColors.DESC_TARGET
	var heal_buff: int = get_heal_value(p_level)
	return "%s\nGrant %s [color=%s]+%d Heal[/color] stat permanently." % [get_trigger_name(Trigger.ON_CAST), target_str, GameColors.DESC_HEAL, heal_buff]