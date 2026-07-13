class_name FocusingLensRelic
extends RelicModifier

func get_description(_relic_inst: RelicInstance = null) -> String:
	return "Allies whose abilities target [color=%s]LEFT[/color], [color=%s]RIGHT[/color], or [color=%s]HORIZONTAL[/color] neighbors now affect all allies in that direction." % [GameColors.DESC_TARGET, GameColors.DESC_TARGET, GameColors.DESC_TARGET]
