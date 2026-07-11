class_name ForestGuardianModifier
extends UnitModifier

@export var value_1: int = 5
@export var value_2: int = 5
@export var value_3: int = 5

func get_target(p_level: int = 1) -> TargetType:
	if p_level >= 2:
		return TargetType.HORIZONTAL_PLUS
	return TargetType.HORIZONTAL

func get_modifier_value(p_level: int = 1) -> float:
	match p_level:
		1: return float(value_1)
		2: return float(value_2)
		3: return float(value_3)
	return float(value_1)

func is_permanent(p_level: int) -> bool:
	return p_level >= 3

func apply_modifier(source_idx: int, team_obj: BattleTeam) -> void:
	var unit: UnitInstance = team_obj.units[source_idx]
	var current_level: int = unit.level if unit else 1
	var current_target: TargetType = get_target(current_level)
	var buff: int = int(get_modifier_value(current_level))
	var permanent: bool = is_permanent(current_level)
	for idx: int in TargetResolver.get_target_indices(source_idx, current_target, team_obj.has_magnetic_core):
		team_obj.add_unit_shield(idx, buff, permanent)

func get_description(p_level: int = 1) -> String:
	var current_target: TargetType = get_target(p_level)
	var target_str: String = "[color=%s]HORIZONTAL%s[/color] allies" % [GameColors.DESC_TARGET, "+" if current_target == TargetType.HORIZONTAL_PLUS else ""]
			
	var buff: int = int(get_modifier_value(p_level))
	var duration_str: String = "permanently" if is_permanent(p_level) else "for this battle"
	return "%s\nGive %s [color=%s]+%d Shield[/color] %s" % [get_trigger_name(), target_str, GameColors.DESC_SHIELD, buff, duration_str]
