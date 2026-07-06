class_name RunState
extends Resource

const MAX_ACTIVE_TEAM_SIZE: int = 6
const MAX_BENCH_SIZE: int = 8

func _init() -> void:
	if active_team.is_empty():
		active_team.resize(MAX_ACTIVE_TEAM_SIZE)
	if bench.is_empty():
		bench.resize(MAX_BENCH_SIZE)


signal gold_changed(p_gold: int)
signal lives_changed(p_lives: int)
signal day_changed(p_day: int)
signal trophies_changed(p_trophies: int)
signal shop_level_changed(p_level: int)
signal shop_slot_updated(p_slot_index: int, p_card_instance: Resource)
signal shop_slot_freeze_changed(p_slot_index: int, p_is_frozen: bool)

var unit_templates: Array[UnitData] = []
var item_templates: Array[ItemData] = []

func setup_templates(p_units: Array[UnitData], p_items: Array[ItemData]) -> void:
	unit_templates = p_units
	item_templates = p_items

@export var active_team: Array[UnitInstance] = []
@export var bench: Array[UnitInstance] = []
@export var shop_cards: Array[Resource] = [] # Can hold UnitInstance, ItemInstance, or null
@export var shop_frozen_statuses: Array[bool] = []

@export var gold: int = 10:
	set(val):
		if gold != val:
			gold = val
			gold_changed.emit(gold)

@export var lives: int = 10:
	set(val):
		if lives != val:
			lives = val
			lives_changed.emit(lives)

@export var day: int = 1:
	set(val):
		if day != val:
			day = val
			day_changed.emit(day)

@export var trophies: int = 0:
	set(val):
		if trophies != val:
			trophies = val
			trophies_changed.emit(trophies)

@export var max_trophies: int = 10

@export var battle_speed: float = 1.0

@export var shop_level: int = 1:
	set(val):
		if shop_level != val:
			shop_level = val
			shop_level_changed.emit(shop_level)

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

# --- SHOP BUSINESS LOGIC & ROLLING ---

func get_random_unit_template_by_rarity(rarity_name: String) -> UnitData:
	var matching: Array[UnitData] = []
	for template: UnitData in unit_templates:
		if template == null:
			continue
		var r_name: String = "Common"
		if template.rarity:
			r_name = template.rarity.rarity_name
		if r_name == rarity_name:
			matching.append(template)
			
	if matching.is_empty():
		for template: UnitData in unit_templates:
			if template != null:
				matching.append(template)
				
	if matching.is_empty():
		return null
		
	return matching[randi() % matching.size()]

func get_random_item_template_by_rarity(rarity_name: String) -> ItemData:
	var matching: Array[ItemData] = []
	for template: ItemData in item_templates:
		if template == null:
			continue
		var r_name: String = "Common"
		if template.rarity:
			r_name = template.rarity.rarity_name
		if r_name == rarity_name:
			matching.append(template)
			
	if matching.is_empty():
		for template: ItemData in item_templates:
			if template != null:
				matching.append(template)
				
	if matching.is_empty():
		return null
		
	return matching[randi() % matching.size()]

func roll_single_shop_card() -> Resource:
	var spawn_item: bool = false
	if not item_templates.is_empty() and randf() < 0.3:
		spawn_item = true
		
	var rolled_rarity: String = roll_rarity_name()
	if spawn_item:
		var template: ItemData = get_random_item_template_by_rarity(rolled_rarity)
		if template:
			var instance: ItemInstance = ItemInstance.new()
			instance.initialize(template)
			return instance
	else:
		if unit_templates.is_empty():
			return null
		var template: UnitData = get_random_unit_template_by_rarity(rolled_rarity)
		if template:
			var instance: UnitInstance = UnitInstance.new()
			instance.initialize(template)
			return instance
	return null

func buy_unit(shop_slot_idx: int, target_idx: int, target_is_active: bool) -> bool:
	if shop_slot_idx < 0 or shop_slot_idx >= shop_cards.size():
		return false
		
	var item_or_unit: Resource = shop_cards[shop_slot_idx]
	if not (item_or_unit is UnitInstance):
		return false
		
	var unit: UnitInstance = item_or_unit as UnitInstance
	var cost: int = unit.data.price if unit.data else 3
	if gold < cost:
		return false
		
	var target_array: Array[UnitInstance] = active_team if target_is_active else bench
	if target_idx < 0 or target_idx >= target_array.size():
		return false
		
	if target_array[target_idx] != null:
		return false # Slot is occupied
		
	# Execute purchase
	gold -= cost
	target_array[target_idx] = unit
	
	# Refill shop slot immediately
	shop_cards[shop_slot_idx] = roll_single_shop_card()
	shop_frozen_statuses[shop_slot_idx] = false
	
	# Emit updates
	shop_slot_updated.emit(shop_slot_idx, shop_cards[shop_slot_idx])
	shop_slot_freeze_changed.emit(shop_slot_idx, false)
	
	return true

func apply_item(shop_slot_idx: int, target_idx: int, target_is_active: bool) -> bool:
	if shop_slot_idx < 0 or shop_slot_idx >= shop_cards.size():
		return false
		
	var item_or_unit: Resource = shop_cards[shop_slot_idx]
	if not (item_or_unit is ItemInstance):
		return false
		
	var item: ItemInstance = item_or_unit as ItemInstance
	var cost: int = item.data.price if item.data else 2
	if gold < cost:
		return false
		
	var target_array: Array[UnitInstance] = active_team if target_is_active else bench
	if target_idx < 0 or target_idx >= target_array.size():
		return false
		
	var target_unit: UnitInstance = target_array[target_idx]
	if target_unit == null:
		return false # No unit to feed
		
	# Apply effect
	if item.data and item.data.modifier:
		item.data.modifier.apply_unit_effect(target_unit)
		
	# Execute purchase
	gold -= cost
	
	# Refill shop slot immediately
	shop_cards[shop_slot_idx] = roll_single_shop_card()
	shop_frozen_statuses[shop_slot_idx] = false
	
	# Emit updates
	shop_slot_updated.emit(shop_slot_idx, shop_cards[shop_slot_idx])
	shop_slot_freeze_changed.emit(shop_slot_idx, false)
	
	return true

func swap_units(from_idx: int, from_active: bool, to_idx: int, to_active: bool) -> void:
	var source_array: Array[UnitInstance] = active_team if from_active else bench
	var target_array: Array[UnitInstance] = active_team if to_active else bench
	
	if from_idx < 0 or from_idx >= source_array.size() or to_idx < 0 or to_idx >= target_array.size():
		return
		
	var temp: UnitInstance = source_array[from_idx]
	source_array[from_idx] = target_array[to_idx]
	target_array[to_idx] = temp

func sell_unit(slot_idx: int, is_active: bool) -> void:
	var target_array: Array[UnitInstance] = active_team if is_active else bench
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
	gold += sell_price

func toggle_freeze_shop_slot(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= shop_frozen_statuses.size():
		return
	var next_status: bool = not shop_frozen_statuses[slot_idx]
	shop_frozen_statuses[slot_idx] = next_status
	shop_slot_freeze_changed.emit(slot_idx, next_status)

func roll_shop(free: bool = false) -> void:
	if not free:
		if gold < 1:
			return
		gold -= 1
		
	for i: int in range(shop_cards.size()):
		if not shop_frozen_statuses[i]:
			shop_cards[i] = roll_single_shop_card()
			shop_slot_updated.emit(i, shop_cards[i])
