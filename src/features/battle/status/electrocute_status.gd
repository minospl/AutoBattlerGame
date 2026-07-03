class_name ElectrocuteStatus
extends StatusEffect

func on_apply() -> void:
	if team:
		team.emit_status_changed(status_type, stacks, 0.0)

func modify_incoming_damage(amount: int, damage_type: String) -> int:
	if amount > 0 and damage_type == "physical":
		return amount + stacks
	return amount
