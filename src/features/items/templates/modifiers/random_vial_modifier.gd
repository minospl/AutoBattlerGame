class_name RandomVialModifier
extends ItemModifier

@export var boost_amount: int = 5

func apply_unit_effect(target_unit: UnitInstance) -> void:
	if not target_unit:
		return
		
	var stats: Array[String] = ["health", "attack", "poison", "heal", "shield", "burn", "electrocute"]
	var chosen: String = stats[randi() % stats.size()]
	
	match chosen:
		"health":
			target_unit.health += boost_amount
		"attack":
			target_unit.attack += boost_amount
		"poison":
			target_unit.poison += boost_amount
		"heal":
			target_unit.heal += boost_amount
		"shield":
			target_unit.shield += boost_amount
		"burn":
			target_unit.burn += boost_amount
		"electrocute":
			target_unit.electrocute += boost_amount

func get_description() -> String:
	return "Give a unit [color=%s]+%d[/color] to a random stat." % [GameColors.DESC_GOLD, boost_amount]
