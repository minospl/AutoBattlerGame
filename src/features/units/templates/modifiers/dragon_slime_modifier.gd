class_name DragonSlimeModifier
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

func apply_modifier(source_idx: int, team_obj: BattleTeamModel) -> void:
	var source_unit: UnitInstance = team_obj.units[source_idx]
	var current_level: int = source_unit.level if source_unit else 1
	var times: int = int(get_modifier_value(current_level))
	
	for i: int in range(team_obj.units.size()):
		if i == source_idx:
			continue
		var target_unit: UnitInstance = team_obj.units[i]
		if not target_unit:
			continue
		var is_slime: bool = false
		for t: UnitType in target_unit.data.types:
			if t.type_name.to_lower() == "slime":
				is_slime = true
				break
				
		if is_slime and target_unit.has_type("slime"):
			for _rep: int in range(times):
				target_unit.data.modifier.apply_modifier(i, team_obj)

func get_description(p_level: int = 1) -> String:
	var times: int = int(get_modifier_value(p_level))
	return "%s\nTrigger [color=%s]ALL[/color] other [color=%s]SLIME[/color] modifiers %dx" % [get_trigger_name(trigger), GameColors.DESC_TARGET, GameColors.DESC_TYPE_SLIME, times]
