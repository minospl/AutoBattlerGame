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
		return "%s\nCreated by merging 6 unique [color=%s]SLIMES[/color].\nTriggers their modifiers." % [get_trigger_name(trigger), GameColors.DESC_TYPE_SLIME]

	var desc_parts: Array[String] = []
	for entry: Dictionary in absorbed_units:
		var u_data: UnitData = entry.get("unit_data")
		if not u_data or not u_data.modifier:
			continue
		var mod: UnitModifier = u_data.modifier
		var lvl: int = entry.get("level", 1)
		var val: int = mod.call("get_modifier_value", lvl)

		if mod is BeastSlimeModifier:
			desc_parts.append("[color=%s]+%d ATK[/color]" % [GameColors.DESC_ATTACK, val])
		elif mod is PlantSlimeModifier:
			desc_parts.append("[color=%s]+%d HP[/color]" % [GameColors.DESC_HEALTH, val])
		elif mod is EarthSlimeModifier:
			desc_parts.append("[color=%s]+%d SHIELD[/color]" % [GameColors.DESC_SHIELD, val])
		elif mod is WaterSlimeModifier:
			desc_parts.append("[color=%s]+%d HEAL[/color]" % [GameColors.DESC_HEAL, val])
		elif mod is ToxicSlimeModifier:
			desc_parts.append("[color=%s]+%d POISON[/color]" % [GameColors.DESC_POISON, val])
		elif mod is FireSlimeModifier:
			desc_parts.append("[color=%s]+%d BURN[/color]" % [GameColors.DESC_BURN, val])
		elif mod is ElectricSlimeModifier:
			desc_parts.append("[color=%s]+%d ELECTROCUTE[/color]" % [GameColors.DESC_ELECTROCUTE, val])
		elif mod is DragonSlimeModifier:
			desc_parts.append("(%d TIMES)" % [1 + val])

	return "%s\nGain %s" % [get_trigger_name(trigger), ", ".join(desc_parts)]
