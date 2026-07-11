class_name ThiefsGloveRelic
extends RelicModifier

@export var gold_amount: int = 1
@export var max_gold_per_battle: int = 5

func on_battle_start(relic_inst: RelicInstance, player_team: BattleTeam, _enemy_team: BattleTeam) -> void:
	if player_team and relic_inst:
		var limit: int = max_gold_per_battle * relic_inst.stacks
		var gold_generated: Array[int] = [0]
		player_team.unit_attacked.connect(func(source_idx: int) -> void:
			if gold_generated[0] < limit:
				gold_generated[0] += gold_amount
				player_team.add_unit_gold(source_idx, gold_amount)
		)

func get_description(relic_inst: RelicInstance = null) -> String:
	var current_stacks: int = relic_inst.stacks if relic_inst else 1
	var limit: int = max_gold_per_battle * current_stacks
	return "Whenever a friendly unit attacks, gain [color=%s]1 Gold[/color] (up to [color=%s]%d Gold[/color] per battle)." % [GameColors.DESC_GOLD, GameColors.DESC_GOLD, limit]
