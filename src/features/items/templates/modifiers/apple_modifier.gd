class_name AppleModifier
extends ItemModifier

@export var health_boost: int = 5

func apply_unit_effect(target_unit: UnitInstance) -> void:
	if target_unit:
		target_unit.buff_health(health_boost)

func get_description() -> String:
	return "Give a unit [color=%s]+%d HP[/color]." % [GameColors.DESC_HEALTH, health_boost]
