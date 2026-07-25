class_name FocusingLensRelic
extends RelicModifier

func get_description(_relic_inst: RelicInstance = null) -> String:
	return "Allies whose abilities target [color=%s]LEFT[/color], [color=%s]RIGHT[/color], or [color=%s]HORIZONTAL[/color] allies now affect all allies in that direction." % [GameColors.DESC_TARGET, GameColors.DESC_TARGET, GameColors.DESC_TARGET]

func get_implied_keywords() -> Array[String]:
	return ["target_left", "target_right", "target_horizontal", "target_left_plus", "target_right_plus", "target_horizontal_plus"]
