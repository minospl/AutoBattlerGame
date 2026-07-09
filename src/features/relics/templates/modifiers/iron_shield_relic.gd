class_name IronShieldRelic
extends RelicModifier

@export var shield_amount: int = 10

func on_battle_start(relic_inst: RelicInstance, player_team: BattleTeam, _enemy_team: BattleTeam) -> void:
	if player_team and relic_inst:
		var total_shield: int = shield_amount * relic_inst.stacks
		for idx: int in [0, 1, 2]:
			if player_team.units[idx]:
				player_team.add_unit_shield(idx, total_shield)

func get_description(relic_inst: RelicInstance = null) -> String:
	var current_stacks: int = relic_inst.stacks if relic_inst else 1
	var total_shield: int = shield_amount * current_stacks
	return "At the start of battle, give your units in the top row (rząd górny) [color=%s]+%d Shield[/color]." % [GameColors.DESC_SHIELD, total_shield]
