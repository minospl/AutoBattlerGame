class_name MagneticCoreRelic
extends RelicModifier

func get_description(_relic_inst: RelicInstance = null) -> String:
	return "Allies with [color=%s]ADJACENT[/color] modifiers now target [color=%s]ALL[/color] allies." % [GameColors.DESC_TARGET, GameColors.DESC_TARGET]

func get_implied_keywords() -> Array[String]:
	return ["target_adjacent", "target_all"]
