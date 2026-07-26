class_name MerchantsPactRelic
extends RelicModifier

@export var bonus_levels: int = 5

func on_acquire(_relic_inst: RelicInstance, run_state: RunState) -> void:
	run_state.shop_level += bonus_levels
	if not run_state.disabled_rarities.has(Rarity.Type.LEGENDARY):
		run_state.disabled_rarities.append(Rarity.Type.LEGENDARY)

func get_description(_relic_inst: RelicInstance = null) -> String:
	return "Increases your shop level by [color=%s]+%d[/color], but [color=%s]LEGENDARY[/color] cards will no longer appear." % [GameColors.DESC_GOLD, bonus_levels, GameColors.DESC_LEGENDARY]

func get_implied_keywords() -> Array[String]:
	return []
