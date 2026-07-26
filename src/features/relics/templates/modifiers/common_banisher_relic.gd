class_name CommonBanisherRelic
extends RelicModifier

func on_acquire(_relic_inst: RelicInstance, run_state: RunState) -> void:
	if not run_state.disabled_rarities.has(Rarity.Type.COMMON):
		run_state.disabled_rarities.append(Rarity.Type.COMMON)

func get_description(_relic_inst: RelicInstance = null) -> String:
	return "[color=%s]COMMON[/color] rarity cards no longer appear in the shop." % [GameColors.DESC_COMMON]

func get_implied_keywords() -> Array[String]:
	return []
