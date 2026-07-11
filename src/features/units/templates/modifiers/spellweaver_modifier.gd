class_name SpellweaverModifier
extends UnitModifier

func get_target(p_level: int = 1) -> TargetType:
	if p_level >= 3:
		return TargetType.ADJACENT
	if p_level >= 2:
		return TargetType.HORIZONTAL
	return TargetType.LEFT

func apply_modifier(source_idx: int, team_obj: BattleTeam) -> void:
	var unit: UnitInstance = team_obj.units[source_idx]
	var current_level: int = unit.level if unit else 1
	var current_target: TargetType = get_target(current_level)
	for idx: int in TargetResolver.get_target_indices(source_idx, current_target, team_obj.has_magnetic_core):
		if idx >= 0 and idx < team_obj.units.size() and team_obj.units[idx] != null:
			ModifierEngine.trigger_unit_modifier(idx, team_obj, Trigger.ON_BATTLE_START)

func get_description(p_level: int = 1) -> String:
	var current_target: TargetType = get_target(p_level)
	var target_possession: String = ""
	match current_target:
		TargetType.ADJACENT:
			target_possession = "[color=%s]ADJACENT[/color] allies'" % GameColors.DESC_TARGET
		TargetType.HORIZONTAL:
			target_possession = "[color=%s]HORIZONTAL[/color] allies'" % GameColors.DESC_TARGET
		_:
			target_possession = "the ally to the [color=%s]LEFT[/color]'" % GameColors.DESC_TARGET
			
	return "%s\nTrigger %s %s effect" % [get_trigger_name(), target_possession, get_trigger_name(Trigger.ON_BATTLE_START)]

func get_implied_keywords() -> Array[String]:
	return ["trigger_battle_start"]
