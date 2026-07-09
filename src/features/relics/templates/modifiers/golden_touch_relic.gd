class_name GoldenTouchRelic
extends RelicModifier

@export var extra_gold: int = 2

func on_acquire(relic_inst: RelicInstance, run_state: RunState) -> void:
	if run_state and relic_inst:
		var bonus: int = extra_gold * relic_inst.stacks
		run_state.day_changed.connect(func(_new_day: int) -> void:
			run_state.gold += bonus
		)

func get_description(relic_inst: RelicInstance = null) -> String:
	var current_stacks: int = relic_inst.stacks if relic_inst else 1
	var bonus: int = extra_gold * current_stacks
	return "At the start of each day, gain [color=%s]+%d Gold[/color]." % [GameColors.DESC_GOLD, bonus]
