class_name ShoppingBagRelic
extends RelicModifier

@export var extra_purchases: int = 2

func on_acquire(relic_inst: RelicInstance, run_state: RunState) -> void:
	run_state.item_purchase_limit += extra_purchases * relic_inst.stacks

func get_description(relic_inst: RelicInstance = null) -> String:
	var current_stacks: int = relic_inst.stacks if relic_inst else 1
	var total: int = extra_purchases * current_stacks
	return "You can buy [color=%s]+%d[/color] [color=%s]ITEMS[/color] in the shop." % [GameColors.DESC_GOLD, total, GameColors.DESC_ITEM]

func get_implied_keywords() -> Array[String]:
	return []
