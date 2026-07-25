class_name PoisonStatus
extends StatusEffect

func _init() -> void:
	tick_interval = 1.0

func on_apply() -> void:
	if team:
		team.emit_status_changed(status_type, stacks, get_cooldown_ratio())

func tick(delta: float) -> void:
	if stacks > 0 and team:
		timer += delta
		if timer >= tick_interval:
			timer -= tick_interval
			team.take_damage(stacks, BattleTeamModel.DamageType.POISON)
		team.emit_status_changed(status_type, stacks, get_cooldown_ratio())
