class_name StandardBattleRuleset
extends BattleRuleset

func setup_battle(scene: Node, run_state: RunState) -> void:
	var battle: BattleScene = scene as BattleScene
	
	battle.current_enemy_profile = run_state.generate_enemy_team()
	battle.load_battle_team()

func on_enemy_defeat(scene: Node) -> void:
	var battle: BattleScene = scene as BattleScene
	
	battle.show_battle_outcome("victory")

func on_player_defeat(scene: Node) -> void:
	var battle: BattleScene = scene as BattleScene
	
	battle.show_battle_outcome("defeat")
