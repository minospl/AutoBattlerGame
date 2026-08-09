class_name RunData
extends Resource

const MAX_ACTIVE_TEAM_SIZE: int = 6
const MAX_BENCH_SIZE: int = 6
const MAX_SHOP_CARDS_SIZE: int = 5
const STARTING_GOLD: int = 10
const STARTING_LIVES: int = 5
const STARTING_DAY: int = 1
const MAX_ROUNDS: int = 20
const STARTING_BASE_HEALTH: int = 100

@export var active_team: Array[UnitInstance] = []
@export var bench: Array[UnitInstance] = []
@export var shop_cards: Array[Resource] = []
@export var shop_frozen_statuses: Array[bool] = []
@export var relics: Array[RelicInstance] = []

@export var has_magnetic_core: bool = false
@export var base_health: int = STARTING_BASE_HEALTH
@export var gold: int = STARTING_GOLD
@export var lives: int = STARTING_LIVES
@export var day: int = STARTING_DAY
@export var shop_level: int = 1

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

func duplicate_data() -> RunData:
	var copy: RunData = RunData.new()
	copy.gold = gold
	copy.lives = lives
	copy.day = day
	copy.shop_level = shop_level
	copy.base_health = base_health
	copy.has_magnetic_core = has_magnetic_core

	var cloned_team: Array[UnitInstance] = []
	for u: UnitInstance in active_team:
		if u:
			cloned_team.append(u.clone())
		else:
			cloned_team.append(null)
	copy.active_team = cloned_team

	var cloned_bench: Array[UnitInstance] = []
	for u: UnitInstance in bench:
		if u:
			cloned_bench.append(u.clone())
		else:
			cloned_bench.append(null)
	copy.bench = cloned_bench

	var cloned_relics: Array[RelicInstance] = []
	for r: RelicInstance in relics:
		if r:
			cloned_relics.append(r.clone())
	copy.relics = cloned_relics
	
	# Sklep (bot i tak resetuje lub zmienia to w locie)
	var cloned_shop: Array[Resource] = []
	for c: Resource in shop_cards:
		cloned_shop.append(c)
	copy.shop_cards = cloned_shop
	copy.shop_frozen_statuses = shop_frozen_statuses.duplicate()

	return copy
