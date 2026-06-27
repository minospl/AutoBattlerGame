class_name UnitInstance
extends Resource

## Reference to the base unit template
@export var data: UnitData

## Health of this specific instance (unified HP property)
@export var health: int = 0

## Attack power of this specific instance
@export var attack: int = 0

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

## Level/Stars of the unit
@export var level: int = 1

## Cast speed (on cast cooldown)
@export var cast_speed: float

## Initialize the instance using a template
func initialize(p_data: UnitData) -> void:
	data = p_data
	health = p_data.max_health if p_data else 1
	attack = p_data.attack if p_data else 0
	poison = p_data.base_poison if p_data else 0
	heal = p_data.base_heal if p_data else 0
	shield = p_data.base_shield if p_data else 0
	thorns = p_data.base_thorns if p_data else 0
	burn = p_data.base_burn if p_data else 0
	electrocute = p_data.base_electrocute if p_data else 0
	cast_speed = p_data.cast_speed if p_data else 1.0

func get_unit_name() -> String:
	return data.unit_name if data else "Unknown"

func get_max_health() -> int:
	return health

func get_attack() -> int:
	return attack

func get_types() -> Array[UnitType]:
	return data.types if data else []

func get_cast_speed() -> float:
	return cast_speed

func clone() -> UnitInstance:
	var new_inst : UnitInstance = UnitInstance.new()
	new_inst.data = data
	new_inst.health = health
	new_inst.attack = attack
	new_inst.poison = poison
	new_inst.heal = heal
	new_inst.shield = shield
	new_inst.thorns = thorns
	new_inst.burn = burn
	new_inst.electrocute = electrocute
	new_inst.level = level
	new_inst.cast_speed = cast_speed
	return new_inst
