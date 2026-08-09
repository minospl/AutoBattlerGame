class_name ShieldBatteryRelic
extends RelicModifier

@export var shield_per_cast: int = 5

func on_battle_start(relic_inst: RelicInstance, player_team: BattleTeamModel, _enemy_team: BattleTeamModel) -> void:
	if player_team and relic_inst:
		player_team.unit_casted.connect(func(source_idx: int) -> void:
			if player_team.units[source_idx]:
				var total_shield: int = shield_per_cast * relic_inst.stacks
				player_team.buff_unit_shield(source_idx, total_shield)
		)

func get_description(relic_inst: RelicInstance = null) -> String:
	var current_stacks: int = relic_inst.stacks if relic_inst else 1
	var total_shield: int = shield_per_cast * current_stacks
	return "%s\nGain [color=%s]+%d SHIELD[/color] for this battle." % [get_trigger_name(BaseModifier.Trigger.ON_CAST), GameColors.DESC_SHIELD, total_shield]

func get_implied_keywords() -> Array[String]:
	return ["shield", "trigger_cast"]
