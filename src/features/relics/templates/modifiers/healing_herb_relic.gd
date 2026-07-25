class_name HealingHerbRelic
extends RelicModifier

@export var heal_power: int = 5

func on_battle_start(relic_inst: RelicInstance, player_team: BattleTeamModel, _enemy_team: BattleTeamModel) -> void:
	if player_team and relic_inst:
		var total_heal: int = heal_power * relic_inst.stacks
		player_team.unit_casted.connect(func(_source_idx: int) -> void:
			player_team.heal(total_heal)
		)

func get_description(relic_inst: RelicInstance = null) -> String:
	var current_stacks: int = relic_inst.stacks if relic_inst else 1
	var total_heal: int = heal_power * current_stacks
	return "%s\nHeal for [color=%s]%d HP[/color]." % [get_trigger_name("ON CAST"), GameColors.DESC_HEAL, total_heal]

func get_implied_keywords() -> Array[String]:
	return ["heal", "trigger_cast"]
