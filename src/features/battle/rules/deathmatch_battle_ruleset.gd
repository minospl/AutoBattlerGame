class_name DeathmatchBattleRuleset
extends BattleRuleset

var opponents: Array[OpponentProfile] = []
var current_index: int = 0
var wins: int = 0

func setup_battle(scene: Node, run_state: RunState) -> void:
	var battle: BattleScene = scene as BattleScene
	
	opponents = run_state.generate_deathmatch_opponents()
	current_index = 0
	wins = 0
	
	if opponents.is_empty():
		run_state.is_deathmatch_completed = true
		battle.show_battle_outcome("victory")
		return
		
	battle.current_enemy_profile = opponents[current_index]
	battle.load_battle_team()

func on_enemy_defeat(scene: Node) -> void:
	var battle: BattleScene = scene as BattleScene
	
	wins += 1
	_load_next_opponent(battle)

func on_player_defeat(scene: Node) -> void:
	var battle: BattleScene = scene as BattleScene
	
	battle.run_state.lives -= 1
	
	if battle.run_state.lives <= 0:
		battle.show_battle_outcome("defeat", "DEATHMATCH FAILED")
	else:
		_load_next_opponent(battle)

func _load_next_opponent(battle: BattleScene) -> void:
	current_index += 1
	if current_index >= opponents.size():
		battle.run_state.is_deathmatch_completed = true
		battle.show_battle_outcome("victory", "DEATHMATCH COMPLETE", "You survived! Wins: %d / %d" % [wins, opponents.size()])
	else:
		battle.current_enemy_profile = opponents[current_index]
		battle.reset_for_next_round()
