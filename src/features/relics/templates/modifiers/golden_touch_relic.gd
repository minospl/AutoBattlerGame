class_name GoldenTouchRelic
extends RelicModifier

@export var extra_gold: int = 2

func on_acquire(relic_inst: RelicInstance, run_state: RunState) -> void:
	run_state.battle_completed.connect(func(_outcome: String) -> void:
		var bonus: int = extra_gold * relic_inst.stacks
		run_state.gold += bonus
	)

func get_description(relic_inst: RelicInstance = null) -> String:
	var current_stacks: int = relic_inst.stacks if relic_inst else 1
	var bonus: int = extra_gold * current_stacks
	return "%s\nGain [color=%s]+%d GOLD[/color]." % [get_trigger_name(BaseModifier.Trigger.ON_BATTLE_END), GameColors.DESC_GOLD, bonus]

func get_implied_keywords() -> Array[String]:
	return []
