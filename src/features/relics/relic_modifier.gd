class_name RelicModifier
extends Resource

## Called when the relic is acquired
func on_acquire(_relic_inst: RelicInstance, _run_state: RunState) -> void:
	pass

## Called at the start of battle
func on_battle_start(_relic_inst: RelicInstance, _player_team: BattleTeam, _enemy_team: BattleTeam) -> void:
	pass

## Returns dynamic description for the tooltip
func get_description(_relic_inst: RelicInstance = null) -> String:
	return ""
