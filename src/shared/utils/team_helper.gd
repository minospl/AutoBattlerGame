class_name TeamHelper
extends RefCounted

static func sync_battle_team_stats(p_run_state: RunState, player_battle_units: Array[UnitInstance]) -> void:
	for i: int in range(p_run_state.active_team.size()):
		var persistent_unit: UnitInstance = p_run_state.active_team[i]
		var battle_unit_wrapper: BattleUnitInstance = player_battle_units[i] as BattleUnitInstance
		var battle_unit: UnitInstance = battle_unit_wrapper.base_unit if battle_unit_wrapper else null
		if persistent_unit and battle_unit:
			persistent_unit.health = battle_unit.health
			persistent_unit.attack = battle_unit.attack
			persistent_unit.poison = battle_unit.poison
			persistent_unit.burn = battle_unit.burn
			persistent_unit.electrocute = battle_unit.electrocute
			persistent_unit.heal = battle_unit.heal
			persistent_unit.shield = battle_unit.shield
			persistent_unit.cast_speed = battle_unit.cast_speed
		else:
			p_run_state.active_team[i] = null

static func check_and_merge_units(p_run_state: RunState) -> Dictionary:
	var groups: Dictionary[String, Array] = {}
	
	for i: int in range(p_run_state.active_team.size()):
		var unit: UnitInstance = p_run_state.active_team[i]
		if unit and unit.level < 3:
			var key: String = unit.get_unit_name() + "_" + str(unit.level)
			if not groups.has(key):
				groups[key] = []
			var list: Array = groups[key]
			list.append({"is_bench": false, "idx": i, "unit": unit})

	for i: int in range(p_run_state.bench.size()):
		var unit: UnitInstance = p_run_state.bench[i]
		if unit and unit.level < 3:
			var key: String = unit.get_unit_name() + "_" + str(unit.level)
			if not groups.has(key):
				groups[key] = []
			var list: Array = groups[key]
			list.append({"is_bench": true, "idx": i, "unit": unit})

	for key: String in groups:
		var list: Array = groups[key]
		if list.size() >= 3:
			var main_info: Dictionary = list[0]
			var raw_obj: Object = main_info.get("unit")
			var main_unit: UnitInstance = raw_obj as UnitInstance
			if main_unit:
				var old_data: UnitData = main_unit.data
				var merged_others: Array[UnitInstance] = []
				for j: int in range(1, 3):
					var info: Dictionary = list[j]
					var other: UnitInstance = info.get("unit")
					if other:
						merged_others.append(other)
				
				main_unit.level_up(merged_others)
				if main_unit.data != old_data:
					ShopHelper.handle_unit_evolution(p_run_state, old_data, main_unit.data)
			
			var removed_list: Array = []
			for j: int in range(1, 3):
				var info: Dictionary = list[j]
				var is_bench: bool = info["is_bench"]
				var idx: int = info["idx"]
				if is_bench:
					p_run_state.bench[idx] = null
				else:
					p_run_state.active_team[idx] = null
				removed_list.append({"is_bench": is_bench, "idx": idx})
				
			return {
				"main": main_info,
				"removed": removed_list
			}
			
	return {}

static func swap_units(p_run_state: RunState, from_idx: int, from_active: bool, to_idx: int, to_active: bool) -> void:
	var source_array: Array[UnitInstance] = p_run_state.active_team if from_active else p_run_state.bench
	var target_array: Array[UnitInstance] = p_run_state.active_team if to_active else p_run_state.bench
	
	if from_idx < 0 or from_idx >= source_array.size() or to_idx < 0 or to_idx >= target_array.size():
		return
		
	var temp: UnitInstance = source_array[from_idx]
	source_array[from_idx] = target_array[to_idx]
	target_array[to_idx] = temp

static func sell_unit(p_run_state: RunState, slot_idx: int, is_active: bool) -> void:
	var target_array: Array[UnitInstance] = p_run_state.active_team if is_active else p_run_state.bench
	if slot_idx < 0 or slot_idx >= target_array.size():
		return
		
	var unit: UnitInstance = target_array[slot_idx]
	if unit == null:
		return
		
	var sell_price: int = 1
	if unit.data:
		sell_price = max(1, unit.data.price - 1)
		
	# Execute sell
	target_array[slot_idx] = null
	p_run_state.gold += sell_price
