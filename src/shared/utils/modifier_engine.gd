class_name ModifierEngine
extends Object

## Triggers modifier of a unit at source_idx in the team matching a specific trigger type.
## Returns a dictionary of { modifier: Array[int] } mapping each modifier to its affected target indices.
static func trigger_unit_modifier(source_idx: int, team_obj: BattleTeam, trigger_type: UnitModifier.Trigger) -> void:
	var unit: UnitInstance = team_obj.units[source_idx]

	if not unit or not unit.data or not unit.data.modifier:
		return

	var modifier: UnitModifier = unit.data.modifier
	if modifier.trigger == trigger_type:
		apply_modifier(source_idx, modifier, team_obj)
			

## Applies a single modifier originating from source_idx on a BattleTeam.
static func apply_modifier(source_idx: int, modifier: UnitModifier, team_obj: BattleTeam) -> void:
	for t_idx: int in TargetResolver.get_target_indices(source_idx, modifier.target):
		if t_idx < 0 or t_idx >= team_obj.units.size():
			continue
			
		apply_effect(t_idx, modifier, team_obj)

## Applies the modifier's effect directly to the target at index t_idx in the team.
static func apply_effect(t_idx: int, modifier: UnitModifier, team_obj: BattleTeam) -> void:
	if modifier.effect == UnitModifier.EffectType.TRIGGER_MODIFIERS:
		trigger_unit_modifier(t_idx, team_obj, modifier.target_trigger)
	else:
		team_obj.apply_modifier_effect(t_idx, modifier.effect, modifier.value, modifier.duration)
