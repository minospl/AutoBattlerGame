class_name GoldenBeetleModifier
extends UnitModifier

@export var value_1: int = 1
@export var value_2: int = 2
@export var value_3: int = 3

func get_modifier_value(p_level: int = 1) -> float:
	match p_level:
		1: return float(value_1)
		2: return float(value_2)
		3: return float(value_3)
	return float(value_1)

func apply_modifier(source_idx: int, team_obj: BattleTeam) -> void:
	var unit: UnitInstance = team_obj.units[source_idx]
	var current_level: int = unit.level if unit else 1
	var gold_to_add: int = int(get_modifier_value(current_level))
	team_obj.add_unit_gold(source_idx, gold_to_add)

func get_description(p_level: int = 1) -> String:
	var amount: int = int(get_modifier_value(p_level))
	return "%s\nGenerate [color=gold]%d Gold[/color] on cast" % [get_trigger_name(), amount]
