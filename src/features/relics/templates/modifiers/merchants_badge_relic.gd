class_name MerchantsBadgeRelic
extends RelicModifier

@export var bonus_levels: int = 2

func on_acquire(relic_inst: RelicInstance, run_state: RunState) -> void:
	run_state.shop_level += bonus_levels * relic_inst.stacks

func get_description(relic_inst: RelicInstance = null) -> String:
	var current_stacks: int = relic_inst.stacks if relic_inst else 1
	var total: int = bonus_levels * current_stacks
	return "Increases your shop level by [color=%s]+%d[/color]." % [GameColors.DESC_GOLD, total]

func get_implied_keywords() -> Array[String]:
	return []
