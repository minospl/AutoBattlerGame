class_name RainbowSlimeModifier
extends UnitModifier

## List of absorbed unit templates and their levels: Array[{ "unit_data": UnitData, "level": int }]
@export var absorbed_units: Array[Dictionary] = []

func apply_shop_modifier(source_idx: int, team_units: Array) -> void:
	var source_unit: UnitInstance = team_units[source_idx]

	var repeat_count: int = 1
	for entry: Dictionary in absorbed_units:
		var u_data: UnitData = entry.get("unit_data")
		if u_data and u_data.modifier is DragonSlimeModifier:
			var dragon_mod: DragonSlimeModifier = u_data.modifier as DragonSlimeModifier
			var dragon_lvl: int = entry.get("level", 1)
			repeat_count += int(dragon_mod.get_modifier_value(dragon_lvl))

	for entry: Dictionary in absorbed_units:
		var u_data: UnitData = entry.get("unit_data")
		if u_data and u_data.modifier and not (u_data.modifier is DragonSlimeModifier):
			var mod: UnitModifier = u_data.modifier
			var lvl: int = entry.get("level", 1)
			if mod.trigger == Trigger.ON_BATTLE_END:
				for _rep: int in range(repeat_count):
					mod.apply_effect(source_unit, lvl)

func get_description(_level: int = 1) -> String:
	if absorbed_units.is_empty():
		return "%s\nAbsorbs powers of 6 merged Slimes." % [get_trigger_name(trigger)]

	var desc_lines: Array[String] = [get_trigger_name(trigger), "Trigger absorbed [color=%s]SLIMES[/color]:" % [GameColors.DESC_TYPE_SLIME]]
	for entry: Dictionary in absorbed_units:
		var u_data: UnitData = entry.get("unit_data")
		desc_lines.append("\n%s (Lvl %d)" % [u_data.display_name, entry.get("level", 1)])

	return "\n".join(desc_lines)
