class_name RedDragonModifier
extends UnitModifier

@export var attack_buff: int = 1

func _apply_modifier(source_idx: int, team_obj: BattleTeam) -> void:
	team_obj.buff_unit_attack(source_idx, attack_buff, true)

func get_description() -> String:
	return "%s\nGain [color=%s]+%d Attack[/color] permanently" % [get_trigger_name(), GameColors.DESC_ATTACK, attack_buff]
