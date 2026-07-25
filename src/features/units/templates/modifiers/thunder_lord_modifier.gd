class_name ThunderLordModifier
extends UnitModifier

@export var atk_value_1: int = 8
@export var atk_value_2: int = 16
@export var atk_value_3: int = 32

@export var shield_value_1: int = 15
@export var shield_value_2: int = 30
@export var shield_value_3: int = 60

func get_attack_value(p_level: int = 1) -> float:
	match p_level:
		1: return float(atk_value_1)
		2: return float(atk_value_2)
		3: return float(atk_value_3)
	return float(atk_value_1)

func get_shield_value(p_level: int = 1) -> float:
	match p_level:
		1: return float(shield_value_1)
		2: return float(shield_value_2)
		3: return float(shield_value_3)
	return float(shield_value_1)

func apply_modifier(source_idx: int, team_obj: BattleTeamModel) -> void:
	var unit: UnitInstance = team_obj.units[source_idx]
	var current_level: int = unit.level if unit else 1
	for idx: int in TargetResolver.get_target_indices(source_idx, TargetType.HORIZONTAL, team_obj.has_magnetic_core, team_obj.has_focusing_lens):
		team_obj.buff_unit_attack(idx, int(get_attack_value(current_level)), false)
		team_obj.add_unit_shield(idx, int(get_shield_value(current_level)), false)

func get_description(p_level: int = 1) -> String:
	var target_str: String = "[color=%s]HORIZONTAL[/color] allies" % GameColors.DESC_TARGET
	var values: Array = [get_trigger_name(), target_str, GameColors.DESC_ATTACK, int(get_attack_value(p_level)), GameColors.DESC_SHIELD, int(get_shield_value(p_level))]
	return "%s\nGive %s [color=%s]+%d ATK[/color] and [color=%s]+%d SHIELD[/color] for this battle" % values
