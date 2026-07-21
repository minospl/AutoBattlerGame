class_name GoldenAppleModifier
extends ItemModifier

@export var base_health_boost: int = 50

func apply_shop_effect(run_state: RunState) -> void:
	if run_state:
		run_state.base_health += base_health_boost

func get_description() -> String:
	return "Increase your team's base health by [color=%s]+%d[/color] globally." % [GameColors.DESC_HEALTH, base_health_boost]
