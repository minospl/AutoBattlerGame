class_name MagneticCoreRelic
extends RelicModifier

func get_description(_relic_inst: RelicInstance = null) -> String:
	return "Allies with [color=%s]ADJACENT[/color] abilities now target [color=%s]ALL[/color] allies." % [GameColors.DESC_TARGET, GameColors.DESC_TARGET]
