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

func apply_shop_modifier(source_idx: int, team_units: Array) -> void:
	if source_idx < 0 or source_idx >= team_units.size() or team_units[source_idx] == null:
		return
	var my_unit: UnitInstance = team_units[source_idx]
	if not my_unit:
		return

	var valid_targets: Array[Dictionary] = []
	for i: int in range(team_units.size()):
		if team_units[i] == null:
			continue
		var unit: UnitInstance = team_units[i]
		if not unit:
			continue
			
		if i != source_idx and unit.data.modifier is DragonSlimeModifier:
			if unit.level > my_unit.level or (unit.level == my_unit.level and i < source_idx):
				return
				
		if i != source_idx and unit.has_type("Slime") and unit.data.modifier.trigger == Trigger.ON_BATTLE_END and not (unit.data.modifier is DragonSlimeModifier):
			valid_targets.append({"idx": i, "mod": unit.data.modifier})

	var times: int = int(get_modifier_value(my_unit.level))
	for entry: Dictionary in valid_targets:
		var target_mod: UnitModifier = entry["mod"]
		var target_idx: int = entry["idx"]
		for _rep: int in range(times):
			target_mod.apply_shop_modifier(target_idx, team_units)

func get_description(p_level: int = 1) -> String:
	var times: int = int(get_modifier_value(p_level)) + 1
	return "%s\nTrigger [color=%s]ALL[/color] [color=%s]SLIME[/color] modifiers %dx" % [get_trigger_name(trigger), GameColors.DESC_TARGET, GameColors.DESC_TYPE_SLIME, times]
