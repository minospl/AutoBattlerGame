class_name MysticSentinelModifier
extends UnitModifier

@export var value_1: int = 20
@export var value_2: int = 50
@export var value_3: int = 100

func get_target(_p_level: int = 1) -> TargetType:
	return TargetType.SELF

func get_hp_value(p_level: int = 1) -> int:
	match p_level:
		1: return value_1
		2: return value_2
		3: return value_3
	return value_1

func apply_modifier(source_idx: int, team_obj: BattleTeamModel) -> void:
	var unit: UnitInstance = team_obj.units[source_idx]
	var hp_buff: int = get_hp_value(unit.level)
	team_obj.buff_unit_max_health(source_idx, hp_buff, true)

func get_description(p_level: int = 1) -> String:
	var hp_buff: int = get_hp_value(p_level)
	return "%s\nGain [color=%s]+%d HP[/color] permanently." % [get_trigger_name(Trigger.ON_CAST), GameColors.DESC_HEALTH, hp_buff]