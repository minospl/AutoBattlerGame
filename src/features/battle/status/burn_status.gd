class_name BurnStatus
extends StatusEffect

func _init() -> void:
	tick_interval = 0.5

func on_apply() -> void:
	if team:
		team.emit_status_changed(status_type, stacks, get_cooldown_ratio())

func tick(delta: float) -> void:
	if stacks > 0 and team:
		timer += delta
		if timer >= tick_interval:
			timer -= tick_interval
			var damage: int = stacks
			stacks = max(0, stacks - 1)
			team.take_damage(damage, BattleTeamModel.DamageType.BURN)
			if stacks == 0:
				team.remove_status(status_type)
				return
		team.emit_status_changed(status_type, stacks, get_cooldown_ratio())
