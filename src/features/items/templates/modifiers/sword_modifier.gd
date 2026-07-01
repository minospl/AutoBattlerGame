class_name SwordModifier
extends ItemModifier

@export var attack_boost: int = 2

func apply_unit_effect(target_unit: UnitInstance) -> void:
	if target_unit:
		target_unit.attack += attack_boost

func get_description() -> String:
	return "Give a unit [color=%s]+%d Attack[/color]." % [GameColors.DESC_ATTACK, attack_boost]
