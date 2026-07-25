class_name UnitInstance
extends Resource

## Reference to the base unit template
@export var data: UnitData

## Health of this specific instance (unified HP property)
@export var health: int = 0

## Attack power of this specific instance
@export var attack: int = 0

## Heal value (on cast) of this specific instance
@export var heal: int = 0

## Shield value (on cast) of this specific instance
@export var shield: int = 0

## Burn value of this specific instance
@export var burn: int = 0

## Electrocute value of this specific instance
@export var electrocute: int = 0

## Current poison value of this specific instance
@export var poison: int = 0

## Level/Stars of the unit
@export var level: int = 1

## Cast speed (on cast cooldown)
@export var cast_speed: float

## Initialize the instance using a template
func initialize(p_data: UnitData) -> void:
	data = p_data
	health = p_data.max_health
	attack = p_data.attack
	heal = p_data.base_heal
	shield = p_data.base_shield
	burn = p_data.base_burn
	electrocute = p_data.base_electrocute
	poison = p_data.base_poison
	cast_speed = p_data.cast_speed

func get_unit_name() -> String:
	return data.display_name

func get_max_health() -> int:
	return health

func get_attack() -> int:
	return attack

func get_types() -> Array[UnitType]:
	return data.types if data else []

func has_type(p_type_name: String) -> bool:
	return data.has_type(p_type_name)

func get_cast_speed() -> float:
	return cast_speed

func clone() -> UnitInstance:
	var new_inst: UnitInstance = UnitInstance.new()
	new_inst.data = data
	new_inst.health = health
	new_inst.attack = attack
	new_inst.poison = poison
	new_inst.heal = heal
	new_inst.shield = shield
	new_inst.burn = burn
	new_inst.electrocute = electrocute
	new_inst.level = level
	new_inst.cast_speed = cast_speed
	return new_inst

func evolve(p_new_data: UnitData) -> void:
	if not p_new_data:
		return

	var old_base_health: int = (data.max_health * level)
	var old_base_attack: int = (data.attack * level)
	var old_base_heal: int = (data.base_heal * level)
	var old_base_shield: int = (data.base_shield * level)
	var old_base_burn: int = (data.base_burn * level)
	var old_base_electrocute: int = (data.base_electrocute * level)
	var old_base_poison: int = (data.base_poison * level)

	var bonus_health: int = maxi(0, health - old_base_health)
	var bonus_attack: int = maxi(0, attack - old_base_attack)
	var bonus_heal: int = maxi(0, heal - old_base_heal)
	var bonus_shield: int = maxi(0, shield - old_base_shield)
	var bonus_burn: int = maxi(0, burn - old_base_burn)
	var bonus_electrocute: int = maxi(0, electrocute - old_base_electrocute)
	var bonus_poison: int = maxi(0, poison - old_base_poison)

	data = p_new_data
	level = 1
	health = p_new_data.max_health + bonus_health
	attack = p_new_data.attack + bonus_attack
	heal = p_new_data.base_heal + bonus_heal
	shield = p_new_data.base_shield + bonus_shield
	burn = p_new_data.base_burn + bonus_burn
	electrocute = p_new_data.base_electrocute + bonus_electrocute
	poison = p_new_data.base_poison + bonus_poison
	cast_speed = p_new_data.cast_speed

func level_up() -> void:
	if level >= 3:
		return
	level += 1
	if data:
		health += data.max_health
		attack += data.attack
		poison += data.base_poison
		heal += data.base_heal
		shield += data.base_shield
		burn += data.base_burn
		electrocute += data.base_electrocute
		
	if level == 3 and data.modifier and data.modifier.has_method("evolve"):
		data.modifier.call("evolve", self)
