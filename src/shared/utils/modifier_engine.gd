class_name ModifierEngine
extends Object

## Triggers modifier of a unit at source_idx in the team matching a specific trigger type.
static func trigger_unit_modifier(source_idx: int, team_obj: BattleTeam, trigger_type: UnitModifier.Trigger) -> void:
	var unit: UnitInstance = team_obj.units[source_idx]

	if not unit or not unit.data or not unit.data.modifier:
		return

	var modifier: UnitModifier = unit.data.modifier
	if modifier.trigger == trigger_type:
		modifier._apply_modifier(source_idx, team_obj)
