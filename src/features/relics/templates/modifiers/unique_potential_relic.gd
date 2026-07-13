class_name UniquePotentialRelic
extends RelicModifier

func get_description(_relic_inst: RelicInstance = null) -> String:
	return "Grants a [color=%s]10%%[/color] chance for [color=%s]UNIQUE[/color] units to appear in the shop." % [GameColors.DESC_HEALTH, GameColors.DESC_UNIQUE]
