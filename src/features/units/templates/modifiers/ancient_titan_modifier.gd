class_name AncientTitanModifier
extends UnitModifier

@export var health_buff: int = 5

func apply_modifier(source_idx: int, team_obj: BattleTeam) -> void:
	team_obj.buff_unit_max_health(source_idx, health_buff, true)

func get_description() -> String:
	return "%s\nGain [color=%s]+%d Health[/color] permanently" % [get_trigger_name(), GameColors.DESC_HEALTH, health_buff]
