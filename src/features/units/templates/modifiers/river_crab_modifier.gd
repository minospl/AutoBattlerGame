class_name RiverCrabModifier
extends UnitModifier

@export var attack_buff: int = 2

func _apply_modifier(source_idx: int, team_obj: BattleTeam) -> void:
	team_obj.buff_unit_attack(source_idx, attack_buff)

func get_description() -> String:
	return "%s\nGain [color=%s]+%d Attack[/color] for this battle" % [get_trigger_name(), GameColors.DESC_ATTACK, attack_buff]
