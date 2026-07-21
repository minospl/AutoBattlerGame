class_name UniquePotentialRelic
extends RelicModifier

@export var unique_chance_bonus: float = 0.5

func on_acquire(_relic_inst: RelicInstance, run_state: RunState) -> void:
	run_state.unique_chance += unique_chance_bonus

func get_description(_relic_inst: RelicInstance = null) -> String:
	return "Grants a [color=%s]+%d%%[/color] chance for [color=%s]UNIQUE[/color] units to appear in the shop." % [GameColors.DESC_GOLD, roundi(unique_chance_bonus * 100), GameColors.DESC_UNIQUE]
