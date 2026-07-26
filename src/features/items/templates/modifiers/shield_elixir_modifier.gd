class_name ShieldElixirModifier
extends ItemModifier

@export var shield_boost: int = 5

func apply_unit_effect(target_unit: UnitInstance) -> void:
	if target_unit:
		target_unit.buff_shield(shield_boost)

func get_description() -> String:
	return "Give a unit [color=%s]+%d SHIELD[/color]." % [GameColors.DESC_SHIELD, shield_boost]
