class_name CommonBanisherRelic
extends RelicModifier

func on_acquire(_relic_inst: RelicInstance, run_state: RunState) -> void:
	if not run_state.disabled_rarities.has(Rarity.Type.COMMON):
		run_state.disabled_rarities.append(Rarity.Type.COMMON)

func get_description(_relic_inst: RelicInstance = null) -> String:
	return "Common rarity cards no longer appear in the shop. Their chances are distributed among higher rarities."
