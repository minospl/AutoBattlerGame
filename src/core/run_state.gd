class_name RunState
extends Resource

@export var active_team: Array[UnitInstance] = []
@export var bench: Array[UnitInstance] = []
@export var shop_units: Array[Resource] = [] # Can hold UnitInstance, ShopItemInstance, or null
@export var shop_frozen_statuses: Array[bool] = []
@export var gold: int = 10
@export var lives: int = 10
@export var day: int = 1
@export var trophies: int = 0
@export var max_trophies: int = 10

func check_and_merge_units() -> bool:
	var groups: Dictionary = {}
	
	for i: int in range(active_team.size()):
		var unit: UnitInstance = active_team[i]
		if unit and unit.level < 3:
			var key: String = unit.get_unit_name() + "_" + str(unit.level)
			if not groups.has(key):
				groups[key] = []
			(groups[key] as Array).append({"is_bench": false, "idx": i, "unit": unit})

	for i: int in range(bench.size()):
		var unit: UnitInstance = bench[i]
		if unit and unit.level < 3:
			var key: String = unit.get_unit_name() + "_" + str(unit.level)
			if not groups.has(key):
				groups[key] = []
			(groups[key] as Array).append({"is_bench": true, "idx": i, "unit": unit})

	for key: String in groups:
		var list: Array = groups[key] as Array
		if list.size() >= 3:
			var main_info: Dictionary = list[0] as Dictionary
			var main_unit: UnitInstance = main_info["unit"] as UnitInstance
			main_unit.level_up()
			
			for j: int in range(1, 3):
				var info: Dictionary = list[j] as Dictionary
				if info["is_bench"] as bool:
					bench[info["idx"] as int] = null
				else:
					active_team[info["idx"] as int] = null
			return true
			
	return false
