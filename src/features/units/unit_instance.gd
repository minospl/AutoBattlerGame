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

signal stat_buffed(stat_type: StatType.Type, amount: int)

func buff_health(amount: int) -> void:
	if amount <= 0:
		return
	health += amount
	stat_buffed.emit(StatType.Type.HP, amount)

func buff_attack(amount: int) -> void:
	if amount <= 0:
		return
	attack += amount
	stat_buffed.emit(StatType.Type.ATK, amount)

func buff_heal(amount: int) -> void:
	if amount <= 0:
		return
	heal += amount
	stat_buffed.emit(StatType.Type.HEAL, amount)

func buff_shield(amount: int) -> void:
	if amount <= 0:
		return
	shield += amount
	stat_buffed.emit(StatType.Type.SHIELD, amount)

func buff_poison(amount: int) -> void:
	if amount <= 0:
		return
	poison += amount
	stat_buffed.emit(StatType.Type.POISON, amount)

func buff_burn(amount: int) -> void:
	if amount <= 0:
		return
	burn += amount
	stat_buffed.emit(StatType.Type.BURN, amount)

func buff_electrocute(amount: int) -> void:
	if amount <= 0:
		return
	electrocute += amount
	stat_buffed.emit(StatType.Type.ELECTROCUTE, amount)

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

	var old_clone: UnitInstance = clone()
	initialize(p_new_data)
	absorb_bonus_stats_from(old_clone)

func level_up(p_other_units: Array[UnitInstance] = []) -> void:
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

		for other: UnitInstance in p_other_units:
			absorb_bonus_stats_from(other)

	if level == 3 and data.modifier and data.modifier.has_method("evolve"):
		data.modifier.call("evolve", self)

func absorb_bonus_stats_from(other: UnitInstance) -> void:
	var base_hp: int = other.data.max_health * other.level
	var base_atk: int = other.data.attack * other.level
	var base_heal: int = other.data.base_heal * other.level
	var base_shield: int = other.data.base_shield * other.level
	var base_burn: int = other.data.base_burn * other.level
	var base_elec: int = other.data.base_electrocute * other.level
	var base_poi: int = other.data.base_poison * other.level

	health += maxi(0, other.health - base_hp)
	attack += maxi(0, other.attack - base_atk)
	heal += maxi(0, other.heal - base_heal)
	shield += maxi(0, other.shield - base_shield)
	burn += maxi(0, other.burn - base_burn)
	electrocute += maxi(0, other.electrocute - base_elec)
	poison += maxi(0, other.poison - base_poi)

func to_dict() -> Dictionary:
	return {
		"template_id": data.display_name if data else "",
		"health": health,
		"attack": attack,
		"heal": heal,
		"shield": shield,
		"burn": burn,
		"electrocute": electrocute,
		"poison": poison,
		"level": level,
		"cast_speed": cast_speed
	}

static func from_dict(dict: Dictionary, templates: Array[UnitData]) -> UnitInstance:
	var inst: UnitInstance = UnitInstance.new()
	
	var tpl_id: String = dict.get("template_id", "")
	for t: UnitData in templates:
		if t and t.display_name == tpl_id:
			inst.data = t
			break
			
	inst.health = dict.get("health", 0)
	inst.attack = dict.get("attack", 0)
	inst.heal = dict.get("heal", 0)
	inst.shield = dict.get("shield", 0)
	inst.burn = dict.get("burn", 0)
	inst.electrocute = dict.get("electrocute", 0)
	inst.poison = dict.get("poison", 0)
	inst.level = dict.get("level", 1)
	inst.cast_speed = dict.get("cast_speed", 1.0)
	
	return inst
