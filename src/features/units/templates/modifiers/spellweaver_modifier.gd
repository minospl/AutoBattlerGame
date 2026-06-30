class_name SpellweaverModifier
extends UnitModifier

func apply_modifier(source_idx: int, team_obj: BattleTeam) -> void:
	for idx: int in TargetResolver.get_target_indices(source_idx, TargetType.LEFT):
		if idx >= 0 and idx < team_obj.units.size() and team_obj.units[idx] != null:
			ModifierEngine.trigger_unit_modifier(idx, team_obj, Trigger.ON_BATTLE_START)

func get_description() -> String:
	var target_possession: String = "the ally to the [color=%s]LEFT[/color]'" % GameColors.DESC_TARGET
	return "%s\nTrigger %s %s effect" % [get_trigger_name(), target_possession, get_trigger_name(Trigger.ON_BATTLE_START)]
