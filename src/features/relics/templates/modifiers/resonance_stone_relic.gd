class_name ResonanceStoneRelic
extends RelicModifier

func get_description(_relic_inst: RelicInstance = null) -> String:
	return "Units %s modifiers trigger [color=%s]2 TIMES[/color]." % [get_trigger_name(BaseModifier.Trigger.ON_BATTLE_START), GameColors.DESC_TARGET]

func get_implied_keywords() -> Array[String]:
	return ["trigger_battle_start"]
