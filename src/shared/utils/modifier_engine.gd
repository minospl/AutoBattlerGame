class_name ModifierEngine
extends Object

## Triggers modifier of a unit at source_idx in the team matching a specific trigger type.
static func trigger_unit_modifier(source_idx: int, team_obj: BattleTeamModel, trigger_type: UnitModifier.Trigger) -> void:
	var unit: UnitInstance = team_obj.units[source_idx]

	if not unit or not unit.data.modifier:
		return

	var modifier: UnitModifier = unit.data.modifier
	if modifier.trigger == trigger_type:
		var repeat_count: int = 1
		if trigger_type == UnitModifier.Trigger.ON_BATTLE_START and team_obj.has_relic("Resonance Stone"):
			repeat_count = 2
		for _i: int in range(repeat_count):
			modifier.apply_modifier(source_idx, team_obj)

static func update_ongoing_modifiers(team_obj: BattleTeamModel, opponent: BattleTeamModel) -> void:
	for i: int in range(team_obj.units.size()):
		var unit: UnitInstance = team_obj.units[i]
		if not unit or not unit.data.modifier:
			continue
			
		var modifier: UnitModifier = unit.data.modifier
		if modifier.trigger != UnitModifier.Trigger.ONGOING:
			continue
			
		modifier.apply_ongoing(i, team_obj, opponent)
