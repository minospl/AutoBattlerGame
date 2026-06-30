class_name GameRoot
extends Node

@export var shop_scene_path: String = "res://src/features/shop/shop_scene.tscn"
@export var battle_scene_path: String = "res://src/features/battle/battle_scene.tscn"

var run_state: RunState
var unit_templates: Array[UnitData] = []
var current_scene: Node = null

func _ready() -> void:
	_load_unit_templates()
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

func _initialize_new_run() -> void:
	run_state = RunState.new()
	run_state.active_team.resize(6)
	run_state.bench.resize(8)
	run_state.shop_units.resize(4)
	run_state.shop_frozen_statuses = [false, false, false, false]
	run_state.gold = 10
	run_state.lives = 10
	run_state.day = 1
	run_state.trophies = 0
	run_state.max_trophies = 10
	
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
	for i: int in range(6):
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
			shop.setup(run_state, unit_templates)
			shop.battle_requested.connect(_on_battle_requested)
	)

func _go_to_battle() -> void:
	var enemy_team_units: Array[UnitInstance] = generate_enemy_team(run_state.day)
	_change_scene(battle_scene_path, func(battle_node: Node) -> void:
		var battle: BattleScene = battle_node as BattleScene
		if battle:
			battle.setup(run_state, enemy_team_units)
			battle.battle_finished.connect(_on_battle_finished)
	)

func generate_enemy_team(p_day: int) -> Array[UnitInstance]:
	var enemies: Array[UnitInstance] = []
	enemies.resize(6)
	
	var team_size: int = clampi(1 + floori((p_day - 1) / 2.0), 1, 6)
	
	var max_price_unlocked: int = 2
	if p_day >= 3 and p_day <= 4:
		max_price_unlocked = 3
	elif p_day >= 5:
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
		
		var target_level: int = clampi(1 + floori((p_day - 1) / 3.0), 1, 3)
		while inst.level < target_level:
			inst.level_up()
			
		enemies[i] = inst
		
	return enemies

func _on_battle_requested() -> void:
	_go_to_battle()

func _on_battle_finished(p_outcome: String) -> void:
	if p_outcome == "victory":
		run_state.trophies += 1
	elif p_outcome == "defeat":
		run_state.lives -= 1
	
	if run_state.lives <= 0:
		_show_game_over(false)
	elif run_state.trophies >= run_state.max_trophies:
		_show_game_over(true)
	else:
		run_state.day += 1
		run_state.gold += 10
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
