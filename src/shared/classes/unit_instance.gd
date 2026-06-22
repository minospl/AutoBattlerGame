class_name UnitInstance
extends Resource

## Reference to the base unit template
@export var data: UnitData

## Current health of this specific instance
@export var current_health: int = 0

## Current attack power of this specific instance (can be modified by status effects)
@export var current_attack: int = 0

## Current poison value of this specific instance
@export var poison: int = 0

## Heal value (on cast) of this specific instance
@export var heal: int = 0

## Shield value (on cast) of this specific instance
@export var shield: int = 0


## Thorns value of this specific instance
@export var thorns: int = 0

## Burn value of this specific instance
@export var burn: int = 0

## Electrocute value of this specific instance
@export var electrocute: int = 0

## Level/Stars of the unit (useful for future upgrades)
@export var level: int = 1

@export var max_health_bonus: int = 0
var temp_max_health_bonus: int = 0

@export var current_cast_speed: float

## Initialize the instance using a template
func initialize(p_data: UnitData) -> void:
	data = p_data
	current_health = p_data.max_health
	current_attack = p_data.attack
	poison = p_data.base_poison
	heal = p_data.base_heal if p_data else 0
	shield = p_data.base_shield if p_data else 0
	thorns = p_data.base_thorns if p_data else 0
	burn = p_data.base_burn if p_data else 0
	electrocute = p_data.base_electrocute if p_data else 0
	current_cast_speed = p_data.cast_speed

func get_unit_name() -> String:
	return data.unit_name if data else "Unknown"

func get_max_health() -> int:
	return (data.max_health if data else 1) + max_health_bonus + temp_max_health_bonus

func get_attack() -> int:
	return current_attack

func get_types() -> Array[UnitType]:
	return data.types if data else []

func is_dead() -> bool:
	return current_health <= 0

func get_cast_speed() -> float:
	return current_cast_speed

func clone() -> UnitInstance:
	var new_inst = UnitInstance.new()
	new_inst.data = data
	new_inst.current_health = current_health
	new_inst.current_attack = current_attack
	new_inst.poison = poison
	new_inst.heal = heal
	new_inst.shield = shield
	new_inst.thorns = thorns
	new_inst.burn = burn
	new_inst.electrocute = electrocute
	new_inst.level = level
	new_inst.max_health_bonus = max_health_bonus
	new_inst.current_cast_speed = current_cast_speed
	return new_inst

