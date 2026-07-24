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

func setup_templates(p_units: Array[UnitData], p_items: Array[ItemData], p_relics: Array[RelicData] = []) -> void:
	unit_templates.clear()
	for u: UnitData in p_units:
		if u:
			# var dup: UnitData = u.duplicate(true) as UnitData
			unit_templates.append(u.duplicate(true))
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
	return EnemyTeamGenerator.generate_enemy_team(day, unit_templates)

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

func roll_shop(free: bool = false) -> void:
	ShopHelper.roll_shop(self, free)

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
