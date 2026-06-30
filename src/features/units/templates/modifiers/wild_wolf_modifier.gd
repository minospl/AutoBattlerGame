class_name WildWolfModifier
extends UnitModifier

@export var attack_buff: int = 2

func apply_modifier(source_idx: int, team_obj: BattleTeam) -> void:
	for idx: int in TargetResolver.get_target_indices(source_idx, TargetType.ADJACENT):
		team_obj.buff_unit_attack(idx, attack_buff, false)

func get_description() -> String:
	var target_str: String = "[color=%s]ADJACENT[/color] allies" % GameColors.DESC_TARGET
	return "%s\nGive %s [color=%s]+%d Attack[/color] for this battle" % [get_trigger_name(), target_str, GameColors.DESC_ATTACK, attack_buff]
