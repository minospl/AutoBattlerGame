class_name RunState
extends Resource

const ITEM_PURCHASE_LIMIT: int = 2

@export var data: RunData = RunData.new()

func _init() -> void:
	if data == null:
		data = RunData.new()

signal gold_changed(p_gold: int)
signal lives_changed(p_lives: int)
signal day_changed(p_day: int)
signal shop_level_changed(p_level: int)
signal shop_slot_updated(p_slot_index: int, p_card_instance: Resource)
signal shop_slot_freeze_changed(p_slot_index: int, p_is_frozen: bool)
signal relics_changed(p_relics: Array[RelicInstance])
signal relic_added(relic: RelicInstance)
signal shop_card_generated(card: Resource)
signal shop_rolled()
signal shop_size_changed(p_new_size: int)
signal base_health_changed(p_base_health: int)
signal battle_completed(outcome: String)
signal next_opponent_changed(p_opponent: OpponentProfile)

func notify_shop_slot_updated(p_slot_index: int, p_card_instance: Resource) -> void:
	shop_slot_updated.emit(p_slot_index, p_card_instance)

func notify_shop_slot_freeze_changed(p_slot_index: int, p_is_frozen: bool) -> void:
	shop_slot_freeze_changed.emit(p_slot_index, p_is_frozen)

func notify_shop_card_generated(card: Resource) -> void:
	shop_card_generated.emit(card)

func notify_shop_rolled() -> void:
	shop_rolled.emit()

func notify_shop_size_changed(p_new_size: int) -> void:
	shop_size_changed.emit(p_new_size)

var unit_templates: Array[UnitData] = []
var item_templates: Array[ItemData] = []
var relic_templates: Array[RelicData] = []
var pending_on_battle_end: bool = false
var opponent_provider: OpponentProvider

var opponents_pool: Array[OpponentProfile] = []
var next_opponent: OpponentProfile = null

@export var is_deathmatch: bool = false
@export var is_deathmatch_completed: bool = false
@export var is_endless_mode: bool = false

func setup_templates(p_units: Array[UnitData], p_items: Array[ItemData], p_relics: Array[RelicData] = []) -> void:
	unit_templates.clear()
	for u: UnitData in p_units:
		if u:
			# var dup: UnitData = u.duplicate(true) as UnitData
			unit_templates.append(u.duplicate(true))
	item_templates = p_items
	relic_templates = p_relics

var active_team: Array[UnitInstance]:
	get: return data.active_team
	set(val): data.active_team = val

var bench: Array[UnitInstance]:
	get: return data.bench
	set(val): data.bench = val

var shop_cards: Array[Resource]:
	get: return data.shop_cards
	set(val): data.shop_cards = val

var shop_frozen_statuses: Array[bool]:
	get: return data.shop_frozen_statuses
	set(val): data.shop_frozen_statuses = val

var relics: Array[RelicInstance]:
	get: return data.relics
	set(val): data.relics = val

var has_magnetic_core: bool:
	get: return data.has_magnetic_core
	set(val): data.has_magnetic_core = val

var base_health: int:
	get: return data.base_health
	set(val):
		if data.base_health != val:
			data.base_health = val
			base_health_changed.emit(val)

var gold: int:
	get: return data.gold
	set(val):
		if data.gold != val:
			data.gold = val
			gold_changed.emit(val)

var lives: int:
	get: return data.lives
	set(val):
		if data.lives != val:
			data.lives = val
			lives_changed.emit(val)

var day: int:
	get: return data.day
	set(val):
		if data.day != val:
			data.day = val
			day_changed.emit(val)

var shop_level: int:
	get: return data.shop_level
	set(val):
		if data.shop_level != val:
			data.shop_level = val
			shop_level_changed.emit(val)

@export var item_purchase_limit: int = ITEM_PURCHASE_LIMIT
@export var item_purchase_count: int = 0
@export var max_rounds: int = RunData.MAX_ROUNDS
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
	
	if weights.size() > 0:
		cumulative += weights[0]
		if roll < cumulative:
			return Rarity.Type.COMMON
	if weights.size() > 1:
		cumulative += weights[1]
		if roll < cumulative:
			return Rarity.Type.UNCOMMON
	if weights.size() > 2:
		cumulative += weights[2]
		if roll < cumulative:
			return Rarity.Type.RARE
	if weights.size() > 3:
		cumulative += weights[3]
		if roll < cumulative:
			return Rarity.Type.EPIC
	if weights.size() > 4:
		cumulative += weights[4]
		if roll < cumulative:
			return Rarity.Type.LEGENDARY
	return Rarity.Type.COMMON

func complete_battle(outcome: String, generated_gold: int = 0) -> void:
	item_purchase_count = 0
	
	if outcome == "victory":
		if next_opponent != null:
			next_opponent.data.lives -= 1
	elif outcome == "defeat":
		lives -= 1
		
	if lives > 0 and day <= RunData.MAX_ROUNDS:
		TurnProcessor.process_turn_end(data, generated_gold)
		gold_changed.emit(gold)
		day_changed.emit(day)
		shop_level_changed.emit(shop_level)
				
	if lives > 0 and day > RunData.MAX_ROUNDS:
		is_deathmatch = true
				
	battle_completed.emit(outcome)

func is_victory() -> bool:
	return is_deathmatch_completed and lives > 0 and not is_endless_mode

func is_defeat() -> bool:
	return lives <= 0

func is_game_over() -> bool:
	return is_victory() or is_defeat()

func prepare_next_opponent() -> void:
	if opponent_provider:
		var previous: OpponentProfile = next_opponent
		opponent_provider.update_opponents_pool(self)
		next_opponent = opponent_provider.select_next_opponent(self, previous)
		next_opponent_changed.emit(next_opponent)

func generate_enemy_team() -> OpponentProfile:
	if next_opponent:
		return next_opponent
		
	return opponent_provider.get_next_opponent(self)

func generate_deathmatch_opponents() -> Array[OpponentProfile]:
	if opponent_provider:
		return opponent_provider.get_all_alive_opponents(self)
	return []

func sync_battle_team_stats(player_battle_units: Array[UnitInstance]) -> void:
	TeamHelper.sync_battle_team_stats(self, player_battle_units)

func check_and_merge_units() -> Dictionary:
	return TeamHelper.check_and_merge_units(self)

# --- SHOP BUSINESS LOGIC & ROLLING ---

func get_random_unit_template_by_rarity(rarity_type: Rarity.Type) -> UnitData:
	return ShopHelper.get_random_unit_template_by_rarity(self, rarity_type)

func get_random_item_template_by_rarity(rarity_type: Rarity.Type) -> ItemData:
	return ShopHelper.get_random_item_template_by_rarity(self, rarity_type)

func roll_single_shop_card(slot_idx: int) -> Resource:
	return ShopHelper.roll_single_shop_card(self, slot_idx)

func buy_unit(shop_slot_idx: int, target_idx: int, target_is_active: bool) -> bool:
	return ShopHelper.buy_unit(self, shop_slot_idx, target_idx, target_is_active)

func apply_item(shop_slot_idx: int, target_idx: int, target_is_active: bool) -> bool:
	return ShopHelper.apply_item(self, shop_slot_idx, target_idx, target_is_active)

func swap_units(from_idx: int, from_active: bool, to_idx: int, to_active: bool) -> void:
	TeamHelper.swap_units(self, from_idx, from_active, to_idx, to_active)

func sell_unit(slot_idx: int, is_active: bool) -> void:
	TeamHelper.sell_unit(self, slot_idx, is_active)

func toggle_freeze_shop_slot(slot_idx: int) -> void:
	ShopHelper.toggle_freeze_shop_slot(self, slot_idx)

func request_shop_roll() -> void:
	ShopHelper.request_shop_roll(self)

func roll_shop() -> void:
	ShopHelper.roll_shop(self)

func change_shop_size(p_diff: int) -> void:
	ShopHelper.change_shop_size(self, p_diff)

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
	return ShopHelper.buy_clickable_item(self, shop_slot_idx)

func has_relic(p_name: String) -> bool:
	return RelicInstance.has_relic(relics, p_name)

func get_available_relic_templates(p_rarity: Rarity = null) -> Array[RelicData]:
	var available: Array[RelicData] = []
	for relic: RelicData in relic_templates:
		if not relic:
			continue
		if p_rarity and (not relic.rarity or relic.rarity.rarity_type != p_rarity.rarity_type):
			continue
		if relic.rarity.rarity_type == Rarity.Type.UNIQUE and has_relic(relic.display_name):
			continue
		available.append(relic)
	return available

func reset_for_new_run(p_lives: int = RunData.STARTING_LIVES, p_day: int = RunData.STARTING_DAY, p_gold: int = RunData.STARTING_GOLD) -> void:
	data = RunData.new()
	lives = p_lives
	day = p_day
	gold = p_gold
	base_health = RunData.STARTING_BASE_HEALTH
	opponents_pool.clear()
	next_opponent = null
	relics.clear()
	has_magnetic_core = false
	is_deathmatch = false
	is_deathmatch_completed = false
	is_endless_mode = false
	relics_changed.emit(relics)
	
	for i: int in range(active_team.size()):
		active_team[i] = null
	for i: int in range(bench.size()):
		bench[i] = null
		
	for i: int in range(shop_cards.size()):
		shop_cards[i] = null
	shop_frozen_statuses.fill(false)
	
	roll_shop()

func add_random_relic(p_rarity: Rarity = null) -> void:
	var available: Array[RelicData] = get_available_relic_templates(p_rarity)
	if available.is_empty():
		printerr("No relics found")
		return
		
	var rolled_relic: RelicData = available[randi() % available.size()]
	var relic_inst: RelicInstance = RelicInstance.new()
	relic_inst.initialize(rolled_relic)
	add_relic(relic_inst)
