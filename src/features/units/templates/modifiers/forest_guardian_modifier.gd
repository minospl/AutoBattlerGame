class_name ForestGuardianModifier
extends UnitModifier

@export var shield_value_1: int = 5
@export var shield_value_2: int = 5
@export var shield_value_3: int = 10

@export var hp_value_1: int = 0
@export var hp_value_2: int = 5
@export var hp_value_3: int = 10

func get_target(_p_level: int = 1) -> TargetType:
	return TargetType.HORIZONTAL

func get_shield_value(p_level: int = 1) -> int:
	match p_level:
		1: return shield_value_1
		2: return shield_value_2
		3: return shield_value_3
	return shield_value_1

func get_hp_value(p_level: int = 1) -> int:
	match p_level:
		1: return hp_value_1
		2: return hp_value_2
		3: return hp_value_3
	return hp_value_1

func apply_modifier(source_idx: int, team_obj: BattleTeamModel) -> void:
	var unit: UnitInstance = team_obj.units[source_idx]
	var current_level: int = unit.level if unit else 1
	var current_target: TargetType = get_target(current_level)
	var shield_buff: int = get_shield_value(current_level)
	var hp_buff: int = get_hp_value(current_level)
	
	for idx: int in TargetResolver.get_target_indices(source_idx, current_target, team_obj.has_magnetic_core, team_obj.has_focusing_lens):
		if shield_buff > 0:
			team_obj.buff_unit_shield(idx, shield_buff, true)
		if hp_buff > 0:
			team_obj.buff_unit_max_health(idx, hp_buff, true)

func get_description(p_level: int = 1) -> String:
	var shield_buff: int = get_shield_value(p_level)
	var hp_buff: int = get_hp_value(p_level)

	var hp_buff_string: String = ""
	if hp_buff > 0:
		hp_buff_string = "and [color=%s]+%d HP[/color]" % [GameColors.DESC_HEALTH, hp_buff]
	
	return "%s\nGive [color=%s]HORIZONTAL[/color] allies [color=%s]+%d SHIELD[/color] %s permanently." % [get_trigger_name(), GameColors.DESC_TARGET, GameColors.DESC_SHIELD, shield_buff, hp_buff_string]
