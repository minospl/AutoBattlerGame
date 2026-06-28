class_name ForestGuardianModifier
extends UnitModifier

@export var shield_buff: int = 5

func _apply_modifier(source_idx: int, team_obj: BattleTeam) -> void:
	for idx: int in TargetResolver.get_target_indices(source_idx, TargetType.HORIZONTAL):
		team_obj.add_unit_shield(idx, shield_buff)

func get_description() -> String:
	var target_str: String = "[color=%s]HORIZONTAL[/color] allies" % GameColors.DESC_TARGET
	return "%s\nGive %s [color=%s]+%d Shield[/color] for this battle" % [get_trigger_name(), target_str, GameColors.DESC_SHIELD, shield_buff]
