class_name ModifierEngine
extends Object

## Triggers modifiers of a unit at source_idx in the team matching a specific trigger type.
## Returns a dictionary of { modifier: Array[int] } mapping each modifier to its affected target indices.
static func trigger_unit_modifiers(source_idx: int, team_obj: BattleTeam, trigger_type: UnitModifier.Trigger) -> Dictionary:
	var results: Dictionary[UnitModifier, Array] = {}
	var unit = team_obj.units[source_idx]
	if not unit or not unit.data or not unit.data.modifiers:
		return results
		
	for modifier in unit.data.modifiers:
		if modifier.trigger == trigger_type:
			var affected = apply_modifier(source_idx, modifier, team_obj)
			results[modifier] = affected
			
	return results

## Applies a single modifier originating from source_idx on a BattleTeam.
## Returns an array of target indices that were actually affected.
static func apply_modifier(source_idx: int, modifier: UnitModifier, team_obj: BattleTeam) -> Array[int]:
	var affected_indices: Array[int] = []
	if not modifier:
		return affected_indices
		
	var target_indices = TargetResolver.get_target_indices(source_idx, modifier.target)
	
	for t_idx in target_indices:
		if t_idx < 0 or t_idx >= team_obj.units.size():
			continue
		var target_unit = team_obj.units[t_idx]
		if not target_unit:
			continue
			
		apply_effect(t_idx, modifier, team_obj)
		affected_indices.append(t_idx)
		
	return affected_indices

## Applies the modifier's effect directly to the target at index t_idx in the team.
static func apply_effect(t_idx: int, modifier: UnitModifier, team_obj: BattleTeam) -> void:
	var target_unit = team_obj.units[t_idx]
	if not target_unit:
		return
		
	if modifier.effect == UnitModifier.EffectType.TRIGGER_MODIFIERS:
		trigger_unit_modifiers(t_idx, team_obj, modifier.target_trigger)
	else:
		team_obj.apply_modifier_effect(t_idx, modifier.effect, modifier.value, modifier.duration)
