class_name PocketPouchRelic
extends RelicModifier

@export var extra_slots: int = 1

func on_acquire(_relic_inst: RelicInstance, run_state: RunState) -> void:
	run_state.change_shop_size(extra_slots)

func get_description(_relic_inst: RelicInstance = null) -> String:
	return "Increases the number of slots in the shop by [color=%s]+%d[/color]." % [GameColors.DESC_GOLD, extra_slots]
