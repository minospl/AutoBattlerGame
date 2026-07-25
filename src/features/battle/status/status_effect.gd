class_name StatusEffect
extends RefCounted

var status_type: String = ""
var team: BattleTeamModel = null
var stacks: int = 0
var timer: float = 0.0
var tick_interval: float = 1.0

func initialize(p_type: String, p_team: BattleTeamModel, p_stacks: int) -> void:
	status_type = p_type
	team = p_team
	stacks = p_stacks
	on_apply()

func on_apply() -> void:
	pass

func add_stacks(amount: int) -> void:
	stacks += amount
	on_apply()

func tick(_delta: float) -> void:
	pass

func modify_incoming_damage(amount: int, _damage_type: BattleTeamModel.DamageType) -> int:
	return amount

func get_cooldown_ratio() -> float:
	if tick_interval > 0.0:
		return clampf(timer / tick_interval, 0.0, 1.0)
	return 0.0

func reset() -> void:
	stacks = 0
	timer = 0.0
