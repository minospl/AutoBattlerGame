class_name BattleUnitInstance
extends UnitInstance

## Reference to the base cloned UnitInstance
var base_unit: UnitInstance

func initialize_battle_unit(p_unit: UnitInstance) -> void:
	base_unit = p_unit
	health = p_unit.health
	attack = p_unit.attack
	poison = p_unit.poison
	burn = p_unit.burn
	electrocute = p_unit.electrocute
	heal = p_unit.heal
	shield = p_unit.shield
	cast_speed = p_unit.cast_speed
	level = p_unit.level
	data = p_unit.data

var ongoing_attack_bonus: int = 0

func get_attack() -> int:
	return attack + ongoing_attack_bonus
