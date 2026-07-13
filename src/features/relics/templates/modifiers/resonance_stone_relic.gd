class_name ResonanceStoneRelic
extends RelicModifier

func get_description(_relic_inst: RelicInstance = null) -> String:
	return "Allies' [color=%s]ON_BATTLE_START[/color] abilities trigger [color=%s]2 times[/color]." % [GameColors.DESC_TARGET, GameColors.DESC_TARGET]
