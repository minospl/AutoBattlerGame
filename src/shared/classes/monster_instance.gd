class_name MonsterInstance
extends Resource

## Reference to the base monster template
@export var data: MonsterData

## Current health of this specific instance
@export var current_health: int = 0

## Current attack power of this specific instance (can be modified by status effects)
@export var current_attack: int = 0

## Current poison value of this specific instance
@export var poison: int = 0

## Level/Stars of the monster (useful for future upgrades)
@export var level: int = 1

@export var max_health_bonus: int = 0

## Initialize the instance using a template
func initialize(p_data: MonsterData) -> void:
	data = p_data
	current_health = p_data.max_health
	current_attack = p_data.attack
	poison = p_data.base_poison

func get_monster_name() -> String:
	return data.monster_name if data else "Nieznany"

func get_max_health() -> int:
	return (data.max_health if data else 1) + max_health_bonus

func get_attack() -> int:
	return current_attack

func get_types() -> Array[MonsterType]:
	return data.types if data else []

func is_dead() -> bool:
	return current_health <= 0
