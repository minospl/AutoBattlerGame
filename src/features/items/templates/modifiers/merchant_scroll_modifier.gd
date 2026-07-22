class_name MerchantScrollModifier
extends ItemModifier

@export var bonus_levels: int = 1

func apply_shop_effect(run_state: RunState) -> void:
	if run_state:
		run_state.shop_level += bonus_levels

func get_description() -> String:
	return "Increases your shop level by [color=%s]+%d[/color]." % [GameColors.DESC_GOLD, bonus_levels]
