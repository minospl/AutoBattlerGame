class_name RunState
extends Resource

const MAX_ACTIVE_TEAM_SIZE: int = 6
const MAX_BENCH_SIZE: int = 6
const MAX_SHOP_CARDS_SIZE: int = 5
const ITEM_PURCHASE_LIMIT: int = 2
const STARTING_GOLD: int = 10
const STARTING_LIVES: int = 10
const STARTING_DAY: int = 1
const STARTING_TROPHIES: int = 0
const MAX_TROPHIES: int = 10
const STARTING_BASE_HEALTH: int = 100

func _init() -> void:
	if active_team.is_empty():
		active_team.resize(MAX_ACTIVE_TEAM_SIZE)
	if bench.is_empty():
		bench.resize(MAX_BENCH_SIZE)
	if shop_cards.is_empty():
		shop_cards.resize(MAX_SHOP_CARDS_SIZE)
	if shop_frozen_statuses.is_empty():
		shop_frozen_statuses.resize(MAX_SHOP_CARDS_SIZE)
		shop_frozen_statuses.fill(false)

signal gold_changed(p_gold: int)
signal lives_changed(p_lives: int)
signal day_changed(p_day: int)
signal trophies_changed(p_trophies: int)
signal shop_level_changed(p_level: int)
signal shop_slot_updated(p_slot_index: int, p_card_instance: Resource)
signal shop_slot_freeze_changed(p_slot_index: int, p_is_frozen: bool)
signal relics_changed(p_relics: Array[RelicInstance])
signal relic_added(relic: RelicInstance)
signal shop_card_generated(card: Resource)
signal shop_rolled()
signal shop_size_changed(p_new_size: int)

var unit_templates: Array[UnitData] = []
var item_templates: Array[ItemData] = []
var relic_templates: Array[RelicData] = []

func setup_templates(p_units: Array[UnitData], p_items: Array[ItemData], p_relics: Array[RelicData] = []) -> void:
	unit_templates = p_units
	item_templates = p_items
	relic_templates = p_relics

@export var active_team: Array[UnitInstance] = []
@export var bench: Array[UnitInstance] = []
@export var shop_cards: Array[Resource] = [] # Can hold UnitInstance, ItemInstance, or null
@export var shop_frozen_statuses: Array[bool] = []
@export var relics: Array[RelicInstance] = []
@export var has_magnetic_core: bool = false
@export var base_health: int = STARTING_BASE_HEALTH
@export var item_purchase_limit: int = ITEM_PURCHASE_LIMIT
@export var item_purchase_count: int = 0
@export var max_trophies: int = MAX_TROPHIES
@export var battle_speed: float = 1.0
@export var disabled_rarities: Array[Rarity.Type] = []
@export var rarity_config: ShopRarityConfig = ShopRarityConfig.new()

var has_focusing_lens: bool:
	get:
		return has_relic("Focusing Lens")

@export var unique_chance: float = 0.0

var has_unique_potential: bool:
	get:
		return unique_chance > 0.0

@export var gold: int = STARTING_GOLD:
	set(val):
		if gold != val:
			gold = val
			gold_changed.emit(gold)

@export var lives: int = STARTING_LIVES:
	set(val):
		if lives != val:
			lives = val
			lives_changed.emit(lives)

@export var day: int = STARTING_DAY:
	set(val):
		if day != val:
			day = val
			day_changed.emit(day)

@export var trophies: int = STARTING_TROPHIES:
	set(val):
		if trophies != val:
			trophies = val
			trophies_changed.emit(trophies)

@export var shop_level: int = 1:
	set(val):
		if shop_level != val:
			shop_level = val
			shop_level_changed.emit(shop_level)

func get_base_shop_weights() -> Array[float]:
	return rarity_config.get_weights_for_day(shop_level, disabled_rarities)

var shop_weights: Array[float]:
	get:
		return get_base_shop_weights()

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

func roll_rarity() -> Rarity.Type:
	var weights: Array[float] = shop_weights
	var roll: float = randf()
	var cumulative: float = 0.0
	
	cumulative += weights[0]
	if roll < cumulative:
		return Rarity.Type.COMMON
	cumulative += weights[1]
	if roll < cumulative:
		return Rarity.Type.RARE
	cumulative += weights[2]
	if roll < cumulative:
		return Rarity.Type.EPIC
	return Rarity.Type.LEGENDARY

func complete_battle(outcome: String) -> void:
	item_purchase_count = 0
	
	if outcome == "victory":
		trophies += 1
	elif outcome == "defeat":
		lives -= 1
		
	if lives > 0 and trophies < max_trophies:
		day += 1
		gold += 10
		shop_level += 1
		for i: int in range(shop_cards.size()):
			if not shop_frozen_statuses[i]:
				shop_cards[i] = null

func is_victory() -> bool:
	return trophies >= max_trophies

func is_defeat() -> bool:
	return lives <= 0

func is_game_over() -> bool:
	return is_victory() or is_defeat()

func generate_enemy_team() -> Array[UnitInstance]:
	var enemies: Array[UnitInstance] = []
	enemies.resize(6)
	
	var team_size: int = clampi(1 + floori((day - 1) / 2.0), 1, 6)
	
	var max_price_unlocked: int = 2
	if day >= 3 and day <= 4:
		max_price_unlocked = 3
	elif day >= 5:
		max_price_unlocked = 4
		
	var pool: Array[UnitData] = []
	for t: UnitData in unit_templates:
		if t.price <= max_price_unlocked:
			pool.append(t)
			
	if pool.is_empty():
		return enemies
		
	for i: int in range(team_size):
		var template: UnitData = pool[randi() % pool.size()]
		var inst: UnitInstance = UnitInstance.new()
		inst.initialize(template)
		
		var target_level: int = clampi(1 + floori((day - 1) / 3.0), 1, 3)
		while inst.level < target_level:
			inst.level_up()
			
		enemies[i] = inst
		
	return enemies

func sync_battle_team_stats(player_battle_units: Array[UnitInstance]) -> void:
	for i: int in range(active_team.size()):
		var persistent_unit: UnitInstance = active_team[i]
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
			active_team[i] = null

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

func get_random_unit_template_by_rarity(rarity_type: Rarity.Type) -> UnitData:
	var matching: Array[UnitData] = []
	for template: UnitData in unit_templates:
		var r_type: Rarity.Type = template.rarity.rarity_type

		if r_type == Rarity.Type.UNIQUE:
			if rarity_type == Rarity.Type.UNIQUE:
				matching.append(template)
			continue

		if r_type == rarity_type:
			matching.append(template)

	if matching.is_empty():
		for template: UnitData in unit_templates:
			var r_type: Rarity.Type = template.rarity.rarity_type
			if r_type != Rarity.Type.UNIQUE:
				matching.append(template)
				
	if matching.is_empty():
		return null
		
	return matching[randi() % matching.size()]

func get_random_item_template_by_rarity(rarity_type: Rarity.Type) -> ItemData:
	var matching: Array[ItemData] = []
	for template: ItemData in item_templates:
		var r_type: Rarity.Type = template.rarity.rarity_type
			
		if r_type == rarity_type:
			matching.append(template)
			
	if matching.is_empty():
		for template: ItemData in item_templates:
			var r_type: Rarity.Type = template.rarity.rarity_type
			if r_type != Rarity.Type.UNIQUE:
				matching.append(template)
				
	if matching.is_empty():
		return null
		
	return matching[randi() % matching.size()]

func roll_single_shop_card(slot_idx: int) -> Resource:
	var rolled_rarity: Rarity.Type = roll_rarity()
	if unique_chance > 0.0 and randf() < unique_chance:
		rolled_rarity = Rarity.Type.UNIQUE
		
	var spawn_item: bool = false
	var last_slot_idx: int = shop_cards.size() - 1
	if slot_idx == last_slot_idx and item_purchase_count < item_purchase_limit:
		if not item_templates.is_empty():
			spawn_item = true
		
	var rolled_card: Resource = null
	if spawn_item:
		var template: ItemData = get_random_item_template_by_rarity(rolled_rarity)
		if template:
			var instance: ItemInstance = ItemInstance.new()
			instance.initialize(template)
			rolled_card = instance
	else:
		if unit_templates.is_empty():
			return null
			
		var template: UnitData = get_random_unit_template_by_rarity(rolled_rarity)
		if template:
			var instance: UnitInstance = UnitInstance.new()
			instance.initialize(template)
			rolled_card = instance
			
	if rolled_card:
		shop_card_generated.emit(rolled_card)
		
	return rolled_card

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
	shop_cards[shop_slot_idx] = roll_single_shop_card(shop_slot_idx)
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
	item_purchase_count += 1
	
	# Refill shop slot immediately
	shop_cards[shop_slot_idx] = null
	shop_cards[shop_slot_idx] = roll_single_shop_card(shop_slot_idx)
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
		
	shop_rolled.emit()
		
	for i: int in range(shop_cards.size()):
		if not shop_frozen_statuses[i]:
			shop_cards[i] = roll_single_shop_card(i)
			shop_slot_updated.emit(i, shop_cards[i])

func change_shop_size(p_diff: int) -> void:
	if p_diff == 0:
		return
		
	var new_size: int = clampi(shop_cards.size() + p_diff, 1, 10)
	var old_size: int = shop_cards.size()
	if new_size == old_size:
		return

	# Add slot to the first
	if new_size > old_size:
		var diff: int = new_size - old_size
		var new_cards: Array[Resource] = []
		var new_frozen: Array[bool] = []
		new_cards.resize(new_size)
		new_frozen.resize(new_size)
		
		for i: int in range(old_size):
			new_cards[i + diff] = shop_cards[i]
			new_frozen[i + diff] = shop_frozen_statuses[i]
			
		for i: int in range(diff):
			new_cards[i] = null
			new_frozen[i] = false
			
		shop_cards = new_cards
		shop_frozen_statuses = new_frozen
		
		for i: int in range(diff):
			shop_cards[i] = roll_single_shop_card(i)
	else:
		shop_cards.resize(new_size)
		shop_frozen_statuses.resize(new_size)
			
	shop_size_changed.emit(new_size)

func add_relic(relic: RelicInstance) -> void:		
	if relic.data and relic.data.display_name == "Magnetic Core":
		has_magnetic_core = true
		
	# Check if we already have this relic and increase stack count
	for existing: RelicInstance in relics:
		if existing.data == relic.data:
			existing.stacks += relic.stacks
			if existing.data.modifier:
				existing.data.modifier.on_acquire(relic, self)
			relics_changed.emit(relics)
			relic_added.emit(existing)
			return
			
	relics.append(relic)
	if relic.data and relic.data.modifier:
		relic.data.modifier.on_acquire(relic, self)
	relics_changed.emit(relics)
	relic_added.emit(relic)

func buy_clickable_item(shop_slot_idx: int) -> bool:
	if shop_slot_idx < 0 or shop_slot_idx >= shop_cards.size():
		return false
		
	var item_or_unit: Resource = shop_cards[shop_slot_idx]
	if not (item_or_unit is ItemInstance):
		return false
		
	var item: ItemInstance = item_or_unit as ItemInstance
	var cost: int = item.data.price if item.data else 2
	if gold < cost:
		return false
		
	# Apply effect
	if item.data and item.data.modifier:
		item.data.modifier.apply_shop_effect(self)
		
	# Execute purchase
	gold -= cost
	item_purchase_count += 1
	
	# Refill shop slot immediately
	shop_cards[shop_slot_idx] = null
	shop_cards[shop_slot_idx] = roll_single_shop_card(shop_slot_idx)
	shop_frozen_statuses[shop_slot_idx] = false
	
	# Emit updates
	shop_slot_updated.emit(shop_slot_idx, shop_cards[shop_slot_idx])
	shop_slot_freeze_changed.emit(shop_slot_idx, false)
	
	return true

func has_relic(p_name: String) -> bool:
	return RelicInstance.has_relic(relics, p_name)

## Returns an array of relic templates that are available to be rolled/acquired
## (filters out unique relics that the player already owns).
## If a rarity is specified, it also filters by that rarity.
func get_available_relic_templates(p_rarity: Rarity = null) -> Array[RelicData]:
	var available: Array[RelicData] = []
	for relic: RelicData in relic_templates:
		if not relic:
			continue
		# Filter by rarity if requested
		if p_rarity and (not relic.rarity or relic.rarity.rarity_type != p_rarity.rarity_type):
			continue
		# Filter out unique relics (those with UNIQUE rarity) that are already owned
		if relic.rarity.rarity_type == Rarity.Type.UNIQUE and has_relic(relic.display_name):
			continue
		available.append(relic)
	return available

func reset_for_new_run(p_lives: int = STARTING_LIVES, p_day: int = STARTING_DAY, p_trophies: int = STARTING_TROPHIES, p_gold: int = STARTING_GOLD) -> void:
	lives = p_lives
	day = p_day
	trophies = p_trophies
	gold = p_gold
	base_health = STARTING_BASE_HEALTH
	relics.clear()
	has_magnetic_core = false
	relics_changed.emit(relics)
	
	# Clear active team and bench
	for i: int in range(active_team.size()):
		active_team[i] = null
	for i: int in range(bench.size()):
		bench[i] = null
		
	# Reset shop cards and frozen statuses
	for i: int in range(shop_cards.size()):
		shop_cards[i] = null
	shop_frozen_statuses.fill(false)
	
	# Roll the shop for free
	roll_shop(true)

func add_random_relic(p_rarity: Rarity = null) -> void:
	var available: Array[RelicData] = get_available_relic_templates(p_rarity)
	if available.is_empty():
		printerr("No relics found")
		return
		
	var rolled_relic: RelicData = available[randi() % available.size()]
	var relic_inst: RelicInstance = RelicInstance.new()
	relic_inst.initialize(rolled_relic)
	add_relic(relic_inst)
