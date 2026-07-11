class_name GameRoot
extends Node

@export var shop_scene_path: String = "res://src/features/shop/shop_scene.tscn"
@export var battle_scene_path: String = "res://src/features/battle/battle_scene.tscn"

const MAX_ACTIVE_TEAM_SIZE: int = 6
const MAX_BENCH_SIZE: int = 6
const MAX_SHOP_CARDS_SIZE: int = 4
const STARTING_GOLD: int = 10
const STARTING_LIVES: int = 10
const STARTING_DAY: int = 1
const STARTING_TROPHIES: int = 0
const MAX_TROPHIES: int = 10

var run_state: RunState
var unit_templates: Array[UnitData] = []
var item_templates: Array[ItemData] = []
var relic_templates: Array[RelicData] = []
var current_scene: Node = null

func _ready() -> void:
	_load_unit_templates()
	_load_item_templates()
	_load_relic_templates()
	_initialize_new_run()
	_go_to_shop()

func _load_unit_templates() -> void:
	unit_templates = [
		preload("res://src/features/units/templates/red_dragon.tres"),
		preload("res://src/features/units/templates/forest_guardian.tres"),
		preload("res://src/features/units/templates/wild_wolf.tres"),
		preload("res://src/features/units/templates/river_crab.tres"),
		preload("res://src/features/units/templates/spellweaver.tres"),
		preload("res://src/features/units/templates/vitality_druid.tres"),
		preload("res://src/features/units/templates/ancient_titan.tres"),
		preload("res://src/features/units/templates/chronomancer.tres"),
		preload("res://src/features/units/templates/golden_beetle.tres")
	]

func _load_item_templates() -> void:
	item_templates = [
		preload("res://src/features/items/templates/apple.tres") as ItemData,
		preload("res://src/features/items/templates/sword.tres") as ItemData,
		preload("res://src/features/items/templates/common_relic_chest.tres") as ItemData,
		preload("res://src/features/items/templates/rare_relic_chest.tres") as ItemData,
		preload("res://src/features/items/templates/epic_relic_chest.tres") as ItemData,
		preload("res://src/features/items/templates/legendary_relic_chest.tres") as ItemData
	]

func _load_relic_templates() -> void:
	relic_templates = [
		preload("res://src/features/relics/templates/cursed_doll.tres") as RelicData,
		preload("res://src/features/relics/templates/iron_shield.tres") as RelicData,
		preload("res://src/features/relics/templates/healing_herb.tres") as RelicData,
		preload("res://src/features/relics/templates/poisonous_fangs.tres") as RelicData,
		preload("res://src/features/relics/templates/thiefs_glove.tres") as RelicData,
		preload("res://src/features/relics/templates/golden_touch.tres") as RelicData,
		preload("res://src/features/relics/templates/fire_opal.tres") as RelicData,
		preload("res://src/features/relics/templates/shield_battery.tres") as RelicData,
		preload("res://src/features/relics/templates/magnetic_core.tres") as RelicData
	]

func _initialize_new_run() -> void:
	run_state = RunState.new()
	run_state.setup_templates(unit_templates, item_templates, relic_templates)
	run_state.active_team.resize(MAX_ACTIVE_TEAM_SIZE)
	run_state.bench.resize(MAX_BENCH_SIZE)
	run_state.shop_cards.resize(MAX_SHOP_CARDS_SIZE)
	run_state.shop_frozen_statuses.resize(MAX_SHOP_CARDS_SIZE)
	run_state.shop_frozen_statuses.fill(false)
	run_state.gold = STARTING_GOLD
	run_state.lives = STARTING_LIVES
	run_state.day = STARTING_DAY
	run_state.trophies = STARTING_TROPHIES
	run_state.max_trophies = MAX_TROPHIES
	run_state.shop_level = 1
	
	# Find templates by unit name
	var find_template: Callable = func(p_name: String) -> UnitData:
		for t: UnitData in unit_templates:
			if t.unit_name.to_lower() == p_name.to_lower():
				return t
		return null

	var titan: UnitData = find_template.call("Ancient Titan")
	var spellweaver: UnitData = find_template.call("Spellweaver")
	var druid: UnitData = find_template.call("Vitality Druid")
	var crab: UnitData = find_template.call("River Crab")

	var setup: Array[UnitData] = [titan, spellweaver, null, druid, crab, null]
	for i: int in range(MAX_ACTIVE_TEAM_SIZE):
		var temp: UnitData = setup[i]
		if temp:
			var instance: UnitInstance = UnitInstance.new()
			instance.initialize(temp)
			run_state.active_team[i] = instance
		else:
			run_state.active_team[i] = null

func _change_scene(scene_path: String, setup_callable: Callable) -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null
		
	var scene_resource: PackedScene = load(scene_path) as PackedScene
	if not scene_resource:
		printerr("Failed to load scene: ", scene_path)
		return
		
	current_scene = scene_resource.instantiate()
	add_child(current_scene)
	
	setup_callable.call(current_scene)

func _go_to_shop() -> void:
	_change_scene(shop_scene_path, func(shop_node: Node) -> void:
		var shop: ShopScene = shop_node as ShopScene
		if shop:
			shop.setup(run_state)
			shop.battle_requested.connect(_on_battle_requested)
	)

func _go_to_battle() -> void:
	var enemy_team_units: Array[UnitInstance] = run_state.generate_enemy_team()
	_change_scene(battle_scene_path, func(battle_node: Node) -> void:
		var battle: BattleScene = battle_node as BattleScene
		if battle:
			battle.setup(run_state, enemy_team_units)
			battle.battle_finished.connect(_on_battle_finished)
	)

func _on_battle_requested() -> void:
	_go_to_battle()

func _on_battle_finished(p_outcome: String) -> void:
	run_state.complete_battle(p_outcome)
	
	if run_state.is_defeat():
		_show_game_over(false)
	elif run_state.is_victory():
		_show_game_over(true)
	else:
		_go_to_shop()

func _show_game_over(p_victory: bool) -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null
		
	var go_screen: GameOverScreen = GameOverScreen.new()
	add_child(go_screen)
	current_scene = go_screen
	
	go_screen.setup(p_victory, run_state.trophies, run_state.day)
	go_screen.restart_requested.connect(func() -> void:
		_initialize_new_run()
		_go_to_shop()
	)
