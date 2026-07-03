class_name BurnStatus
extends StatusEffect

var timer: float = 0.0

func on_apply() -> void:
	if team:
		team.emit_status_changed(status_type, stacks, timer / 0.5)

func tick(delta: float) -> void:
	if stacks > 0 and team:
		timer += delta
		if timer >= 0.5:
			timer -= 0.5
			var damage: int = stacks
			stacks = max(0, stacks - 1)
			team.take_damage(damage, "burn")
			if stacks == 0:
				team.remove_status(status_type)
				return
		team.emit_status_changed(status_type, stacks, clampf(timer / 0.5, 0.0, 1.0))

func reset() -> void:
	super.reset()
	timer = 0.0
