class_name TurnProcessor
extends RefCounted

static func process_turn_end(data: RunData, generated_gold_from_battle: int) -> void:
	# 1. Dodaj złoto z walki + bazowe
	data.gold += data.DAY_GOLD_INCREASE + generated_gold_from_battle
	
	# 2. Awans do następnego dnia i podbicie sklepu
	data.day += 1
	data.shop_level += 1
	
	# Czyszczenie sklepu z kart, które nie są zamrożone
	for i: int in range(data.shop_cards.size()):
		if not data.shop_frozen_statuses[i]:
			data.shop_cards[i] = null
			
	# 3. Wyzwalacze ON_BATTLE_END na aktywnej drużynie
	for i: int in range(data.active_team.size()):
		var unit: UnitInstance = data.active_team[i]
		if not unit or not unit.data.modifier:
			continue
			
		if unit.data.modifier.trigger == UnitModifier.Trigger.ON_BATTLE_END:
			unit.data.modifier.apply_shop_modifier(i, data.active_team)

	# 4. Automatyczna uniwersalna fuzja
	_check_and_execute_slime_fusion(data)

static func _check_and_execute_slime_fusion(data: RunData) -> bool:
	if data.active_team.size() < 6:
		return false

	for u: UnitInstance in data.active_team + data.bench:
		if u and u.get_unit_name() == "Rainbow Slime":
			return false

	var unique_slimes: Dictionary[String, bool] = {}
	for i: int in range(data.active_team.size()):
		var unit: UnitInstance = data.active_team[i]
		if unit and unit.has_type("Slime"):
			unique_slimes[unit.data.display_name] = true

	if unique_slimes.size() < 6:
		return false

	var rainbow_template: UnitData = load("res://src/features/units/templates/rainbow_slime.tres")
	var rainbow_inst: UnitInstance = UnitInstance.new()
	rainbow_inst.initialize(rainbow_template)

	var absorbed_list: Array[Dictionary] = []
	for i: int in range(data.active_team.size()):
		var slime_inst: UnitInstance = data.active_team[i]
		if slime_inst != null:
			rainbow_inst.absorb_bonus_stats_from(slime_inst)
			absorbed_list.append({
				"unit_data": slime_inst.data,
				"level": slime_inst.level
			})

	var custom_mod: RainbowSlimeModifier = rainbow_inst.data.modifier.duplicate() as RainbowSlimeModifier
	if custom_mod:
		custom_mod.absorbed_units = absorbed_list
		rainbow_inst.data = rainbow_inst.data.duplicate() as UnitData
		rainbow_inst.data.modifier = custom_mod

	data.active_team[0] = rainbow_inst
	for i: int in range(1, data.active_team.size()):
		data.active_team[i] = null

	return true
