class_name StatusEffect
extends RefCounted

var status_type: String = ""
var team: BattleTeam = null
var stacks: int = 0

func initialize(p_type: String, p_team: BattleTeam, p_stacks: int) -> void:
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

func modify_incoming_damage(amount: int, _damage_type: String) -> int:
	return amount

func reset() -> void:
	stacks = 0

