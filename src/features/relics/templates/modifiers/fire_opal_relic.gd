class_name FireOpalRelic
extends RelicModifier

@export var burn_stacks: int = 8

func on_battle_start(relic_inst: RelicInstance, _player_team: BattleTeamModel, enemy_team: BattleTeamModel) -> void:
	if enemy_team and relic_inst:
		var total_stacks: int = burn_stacks * relic_inst.stacks
		enemy_team.apply_status("burn", total_stacks)

func get_description(relic_inst: RelicInstance = null) -> String:
	var current_stacks: int = relic_inst.stacks if relic_inst else 1
	var total_stacks: int = burn_stacks * current_stacks
	return "At the start of battle, apply [color=%s]%d Burn[/color] stacks to the enemy team." % [GameColors.DESC_BURN, total_stacks]
