class_name RunState
extends Resource

const MAX_ACTIVE_TEAM_SIZE: int = 6
const MAX_BENCH_SIZE: int = 8

func _init() -> void:
	if active_team.is_empty():
		active_team.resize(MAX_ACTIVE_TEAM_SIZE)
	if bench.is_empty():
		bench.resize(MAX_BENCH_SIZE)


@export var active_team: Array[UnitInstance] = []
@export var bench: Array[UnitInstance] = []
@export var shop_cards: Array[Resource] = [] # Can hold UnitInstance, ItemInstance, or null
@export var shop_frozen_statuses: Array[bool] = []
@export var gold: int = 10
@export var lives: int = 10
@export var day: int = 1
@export var trophies: int = 0
@export var max_trophies: int = 10
@export var battle_speed: float = 1.0
@export var shop_level: int = 1

const DAILY_SHOP_WEIGHTS: Dictionary = {
	1: [1.00, 0.00, 0.00, 0.00],
	2: [0.95, 0.05, 0.00, 0.00],
	3: [0.90, 0.10, 0.00, 0.00],
	4: [0.85, 0.15, 0.00, 0.00],
	5: [0.80, 0.20, 0.00, 0.00],
	6: [0.75, 0.25, 0.00, 0.00],
	7: [0.70, 0.30, 0.00, 0.00],
	8: [0.65, 0.30, 0.05, 0.00],
	9: [0.60, 0.30, 0.10, 0.00],
	10: [0.55, 0.30, 0.15, 0.00],
	11: [0.50, 0.30, 0.20, 0.00],
	12: [0.45, 0.30, 0.25, 0.00],
	13: [0.40, 0.30, 0.30, 0.00],
	14: [0.35, 0.30, 0.30, 0.05],
	15: [0.30, 0.30, 0.30, 0.10],
	16: [0.20, 0.30, 0.35, 0.15],
	17: [0.15, 0.30, 0.35, 0.20],
	18: [0.10, 0.30, 0.35, 0.25],
	19: [0.10, 0.30, 0.35, 0.25],
	20: [0.10, 0.25, 0.35, 0.30],
	21: [0.10, 0.20, 0.35, 0.35],
	22: [0.10, 0.15, 0.35, 0.40],
	23: [0.10, 0.10, 0.35, 0.45],
	24: [0.10, 0.10, 0.30, 0.50],
	25: [0.10, 0.10, 0.25, 0.55],
	26: [0.10, 0.10, 0.20, 0.60],
	27: [0.10, 0.10, 0.15, 0.65],
	28: [0.10, 0.10, 0.10, 0.70]
}

func get_base_shop_weights() -> Array[float]:
	var level_clamped: int = clampi(shop_level, 1, 28)
	var w: Variant = DAILY_SHOP_WEIGHTS.get(level_clamped, [0.10, 0.10, 0.10, 0.70])
	var typed_w: Array[float] = []
	if w is Array:
		for val: Variant in w:
			if val is float:
				typed_w.append(val)
	return typed_w

var shop_weights: Array[float]:
	get:
		var weights: Array[float] = get_base_shop_weights()
		
		# --- PLACEHOLDER FOR FUTURE MODIFIERS / RELICS ---
		# E.g., if player has a relic that bans legendary cards:
		# weights[3] = 0.0
		# weights = normalize_weights(weights)
		# -------------------------------------------------
		
		return weights

func normalize_weights(p_weights: Array[float]) -> Array[float]:
	var total: float = 0.0
	for w: float in p_weights:
		total += w
	if total > 0.0:
		for i: int in range(p_weights.size()):
			p_weights[i] /= total
	else:
		p_weights = [1.0, 0.0, 0.0, 0.0]
	return p_weights

func roll_rarity_name() -> String:
	var weights: Array[float] = shop_weights
	var roll: float = randf()
	var cumulative: float = 0.0
	
	cumulative += weights[0]
	if roll < cumulative:
		return "Common"
	cumulative += weights[1]
	if roll < cumulative:
		return "Rare"
	cumulative += weights[2]
	if roll < cumulative:
		return "Epic"
	return "Legendary"

func get_chance_text() -> String:
	var weights: Array[float] = shop_weights
	var parts: Array[String] = []
	if weights[0] > 0.0:
		parts.append("[color=#708094]C:%d%%[/color]" % int(weights[0] * 100))
	if weights[1] > 0.0:
		parts.append("[color=#3082cf]R:%d%%[/color]" % int(weights[1] * 100))
	if weights[2] > 0.0:
		parts.append("[color=#8059d6]E:%d%%[/color]" % int(weights[2] * 100))
	if weights[3] > 0.0:
		parts.append("[color=#d69e2e]L:%d%%[/color]" % int(weights[3] * 100))
	return " | ".join(parts)

func check_and_merge_units() -> Dictionary:
	var groups: Dictionary[String, Array] = {}
	
	for i: int in range(active_team.size()):
		var unit: UnitInstance = active_team[i]
		if unit and unit.level < 3:
			var key: String = unit.get_unit_name() + "_" + str(unit.level)
			if not groups.has(key):
				groups[key] = []
			var list: Array = groups[key]
			list.append({"is_bench": false, "idx": i, "unit": unit})

	for i: int in range(bench.size()):
		var unit: UnitInstance = bench[i]
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
			var main_unit: UnitInstance = main_info["unit"]
			main_unit.level_up()
			
			var removed_list: Array = []
			for j: int in range(1, 3):
				var info: Dictionary = list[j]
				var is_bench: bool = info["is_bench"]
				var idx: int = info["idx"]
				if is_bench:
					bench[idx] = null
				else:
					active_team[idx] = null
				removed_list.append({"is_bench": is_bench, "idx": idx})
				
			return {
				"main": main_info,
				"removed": removed_list
			}
			
	return {}
