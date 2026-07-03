class_name PoisonStatus
extends StatusEffect

var timer: float = 0.0

func on_apply() -> void:
	if team:
		team.emit_status_changed(status_type, stacks, timer / 1.0)

func tick(delta: float) -> void:
	if stacks > 0 and team:
		timer += delta
		if timer >= 1.0:
			timer -= 1.0
			team.take_damage(stacks, "poison")
		team.emit_status_changed(status_type, stacks, clampf(timer / 1.0, 0.0, 1.0))

func reset() -> void:
	super.reset()
	timer = 0.0
