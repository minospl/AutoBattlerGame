class_name ElixirOfLifeRelic
extends RelicModifier

@export var extra_health: int = 50

func on_acquire(relic_inst: RelicInstance, run_state: RunState) -> void:
	if run_state and relic_inst:
		run_state.base_health += extra_health * relic_inst.stacks

func get_description(relic_inst: RelicInstance = null) -> String:
	var current_stacks: int = relic_inst.stacks if relic_inst else 1
	var total_hp: int = extra_health * current_stacks
	return "Increase your team's base health by [color=%s]+%d[/color]." % [GameColors.DESC_HEALTH, total_hp]

func get_implied_keywords() -> Array[String]:
	return []
