class_name PoisonousFangsRelic
extends RelicModifier

@export var poison_stacks: int = 1

func on_battle_start(relic_inst: RelicInstance, player_team: BattleTeamModel, enemy_team: BattleTeamModel) -> void:
	if player_team and enemy_team and relic_inst:
		var total_poison: int = poison_stacks * relic_inst.stacks
		player_team.unit_casted.connect(func(_source_idx: int) -> void:
			enemy_team.apply_status("poison", total_poison)
		)

func get_description(relic_inst: RelicInstance = null) -> String:
	var current_stacks: int = relic_inst.stacks if relic_inst else 1
	var total_poison: int = poison_stacks * current_stacks
	return "%s\nApply [color=%s]+%d Poison[/color] to the enemy team." % [get_trigger_name("On Cast"), GameColors.DESC_POISON, total_poison]

func get_implied_keywords() -> Array[String]:
	return ["poison", "trigger_cast"]
