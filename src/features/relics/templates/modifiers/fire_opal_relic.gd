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
	return "%s\nApply [color=%s]%d Burn[/color] stacks to the enemy team." % [get_trigger_name("On Battle Start"), GameColors.DESC_BURN, total_stacks]

func get_implied_keywords() -> Array[String]:
	return ["burn", "trigger_battle_start"]
