class_name ChronomancerModifier
extends UnitModifier

@export var value_1: float = 0.5
@export var value_2: float = 1.0
@export var value_3: float = 2.0

func get_target(p_level: int = 1) -> TargetType:
	if p_level >= 3:
		return TargetType.HORIZONTAL
	return TargetType.RIGHT

func get_modifier_value(p_level: int = 1) -> float:
	match p_level:
		1: return value_1
		2: return value_2
		3: return value_3
	return value_1

func apply_modifier(source_idx: int, team_obj: BattleTeam) -> void:
	var unit: UnitInstance = team_obj.units[source_idx]
	var current_level: int = unit.level if unit else 1
	var reduction: float = get_modifier_value(current_level)
	var current_target: TargetType = get_target(current_level)
	for idx: int in TargetResolver.get_target_indices(source_idx, current_target):
		team_obj.buff_unit_cast_speed(idx, reduction, false)

func get_description(p_level: int = 1) -> String:
	var reduction: float = get_modifier_value(p_level)
	var target_phrase: String = "the ally to the [color=%s]RIGHT[/color]" % GameColors.DESC_TARGET if p_level < 3 else "[color=%s]HORIZONTAL[/color] allies" % GameColors.DESC_TARGET
	return "%s\nReduce cast cooldown of %s by %.1fs for this battle" % [get_trigger_name(), target_phrase, reduction]

func get_implied_keywords() -> Array[String]:
	return ["cast_speed"]
