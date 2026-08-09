class_name CrownOfVictoryRelic
extends RelicModifier

@export var gold_reward: int = 10

func on_acquire(relic_inst: RelicInstance, run_state: RunState) -> void:
	if run_state and relic_inst:
		run_state.battle_completed.connect(func(outcome: String) -> void:
			if outcome == "victory":
				var bonus: int = gold_reward * relic_inst.stacks
				run_state.gold += bonus
		)

func get_description(relic_inst: RelicInstance = null) -> String:
	var current_stacks: int = relic_inst.stacks if relic_inst else 1
	var bonus: int = gold_reward * current_stacks
	return "%s\nGain [color=%s]+%d GOLD[/color]." % [get_trigger_name(BaseModifier.Trigger.ON_VICTORY), GameColors.DESC_GOLD, bonus]

func get_implied_keywords() -> Array[String]:
	return []
