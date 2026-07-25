class_name RelicModifier
extends Resource

## Called when the relic is acquired
func on_acquire(_relic_inst: RelicInstance, _run_state: RunState) -> void:
	pass

## Called at the start of battle
func on_battle_start(_relic_inst: RelicInstance, _player_team: BattleTeamModel, _enemy_team: BattleTeamModel) -> void:
	pass

## Returns dynamic description for the tooltip
func get_description(_relic_inst: RelicInstance = null) -> String:
	return ""

## Returns keyword keys implied by this relic modifier for tooltips
func get_implied_keywords() -> Array[String]:
	return []

func get_trigger_name(title: String) -> String:
	return "[color=%s]%s[/color]" % [GameColors.DESC_TRIGGER, title]
