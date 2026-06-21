class_name ModifierEngine
extends Object

## Triggers modifiers of a unit at source_idx in the team matching a specific trigger type.
## Returns a dictionary of { modifier: Array[int] } mapping each modifier to its affected target indices.
static func trigger_unit_modifiers(source_idx: int, team: Array[UnitInstance], trigger_type: UnitModifier.Trigger) -> Dictionary:
	var results = {}
	var unit = team[source_idx]
	if not unit or not unit.data or not unit.data.modifiers:
		return results
		
	for modifier in unit.data.modifiers:
		if modifier.trigger == trigger_type:
			var affected = apply_modifier(source_idx, modifier, team)
			results[modifier] = affected
			
	return results

## Applies a single modifier originating from source_idx on a list of unit instances (size 6).
## Returns an array of target indices that were actually affected.
static func apply_modifier(source_idx: int, modifier: UnitModifier, team: Array[UnitInstance]) -> Array[int]:
	var affected_indices: Array[int] = []
	if not modifier:
		return affected_indices
		
	var target_indices = TargetResolver.get_target_indices(source_idx, modifier.target)
	
	for t_idx in target_indices:
		if t_idx < 0 or t_idx >= team.size():
			continue
		var target_unit = team[t_idx]
		if not target_unit:
			continue
			
		apply_effect(t_idx, modifier, team)
		affected_indices.append(t_idx)
		
	return affected_indices

## Applies the modifier's effect directly to the target at index t_idx in the team.
static func apply_effect(t_idx: int, modifier: UnitModifier, team: Array[UnitInstance]) -> void:
	var target_unit = team[t_idx]
	if not target_unit:
		return
		
	match modifier.effect:
		UnitModifier.EffectType.BUFF_ATTACK:
			target_unit.current_attack += modifier.value
		UnitModifier.EffectType.BUFF_HEALTH:
			target_unit.max_health_bonus += modifier.value
			target_unit.current_health += modifier.value
		UnitModifier.EffectType.BUFF_HEAL:
			target_unit.current_health = min(target_unit.current_health + modifier.value, target_unit.get_max_health())
		UnitModifier.EffectType.APPLY_POISON:
			target_unit.poison += modifier.value
		UnitModifier.EffectType.BUFF_SHIELD:
			# Visual representation not fully implemented in UI, but logged for debugging
			print("[ModifierEngine] Shield buff of %d applied to %s" % [modifier.value, target_unit.get_unit_name()])
		UnitModifier.EffectType.TRIGGER_MODIFIERS:
			print("[ModifierEngine] Triggering modifiers of type '%s' on %s (slot %d)" % [
				str(modifier.target_trigger), target_unit.get_unit_name(), t_idx
			])
			# Recursively trigger the target's modifiers matching the target_trigger condition
			trigger_unit_modifiers(t_idx, team, modifier.target_trigger)
		_:
			print("[ModifierEngine] Effect type %s not supported in engine yet" % str(modifier.effect))
