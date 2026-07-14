class_name GameRoot
extends Node

@export var shop_scene_path: String = "res://src/features/shop/shop_scene.tscn"
@export var battle_scene_path: String = "res://src/features/battle/battle_scene.tscn"
@export var compendium_scene_path: String = "res://src/features/compendium/compendium_scene.tscn"
@export var game_over_scene_path: String = "res://src/core/game_over_screen.tscn"

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
	unit_templates.clear()
	var resources: Array[Resource] = _load_resources_from_dir("res://src/features/units/templates/")
	for res: Resource in resources:
		if res is UnitData:
			unit_templates.append(res as UnitData)

func _load_item_templates() -> void:
	item_templates.clear()
	var resources: Array[Resource] = _load_resources_from_dir("res://src/features/items/templates/")
	for res: Resource in resources:
		if res is ItemData:
			item_templates.append(res as ItemData)

func _load_relic_templates() -> void:
	relic_templates.clear()
	var resources: Array[Resource] = _load_resources_from_dir("res://src/features/relics/templates/")
	for res: Resource in resources:
		if res is RelicData:
			relic_templates.append(res as RelicData)

func _load_resources_from_dir(path: String) -> Array[Resource]:
	var list: Array[Resource] = []
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		printerr("Failed to open directory: ", path)
		return list
		
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".tres") or file_name.ends_with(".res") or file_name.ends_with(".tres.remap") or file_name.ends_with(".res.remap"):
				var clean_name: String = file_name
				if file_name.ends_with(".remap"):
					clean_name = file_name.left(file_name.length() - 6)
				
				var res: Resource = load(path + clean_name)
				if res:
					list.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	return list

func _initialize_new_run() -> void:
	run_state = RunState.new()
	run_state.setup_templates(unit_templates, item_templates, relic_templates)
	run_state.active_team.resize(RunState.MAX_ACTIVE_TEAM_SIZE)
	run_state.bench.resize(RunState.MAX_BENCH_SIZE)
	run_state.shop_cards.resize(RunState.MAX_SHOP_CARDS_SIZE)
	run_state.shop_frozen_statuses.resize(RunState.MAX_SHOP_CARDS_SIZE)
	run_state.shop_frozen_statuses.fill(false)
	run_state.shop_level = 1
	
	# Find templates by unit name
	var find_template: Callable = func(p_name: String) -> UnitData:
		for t: UnitData in unit_templates:
			if t.display_name.to_lower() == p_name.to_lower():
				return t
		return null

	var titan: UnitData = find_template.call("Ancient Titan")
	var spellweaver: UnitData = find_template.call("Spellweaver")
	var druid: UnitData = find_template.call("Vitality Druid")
	var crab: UnitData = find_template.call("River Crab")

	var setup: Array[UnitData] = [titan, spellweaver, null, druid, crab, null]
	for i: int in range(RunState.MAX_ACTIVE_TEAM_SIZE):
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
			shop.compendium_requested.connect(_on_compendium_requested)
			shop.restart_requested.connect(_on_shop_restart_requested)
	)

func _on_shop_restart_requested() -> void:
	_initialize_new_run()
	_go_to_shop()

func _on_compendium_requested() -> void:
	_go_to_compendium()

func _on_compendium_back_requested() -> void:
	_go_to_shop()

func _go_to_compendium() -> void:
	_change_scene(compendium_scene_path, func(compendium_node: Node) -> void:
		var compendium: CompendiumScene = compendium_node as CompendiumScene
		if compendium:
			compendium.setup(run_state)
			compendium.back_requested.connect(_on_compendium_back_requested)
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
		
	var go_scene_res: PackedScene = load(game_over_scene_path) as PackedScene
	if not go_scene_res:
		printerr("Failed to load Game Over scene: ", game_over_scene_path)
		return
		
	var go_screen: GameOverScreen = go_scene_res.instantiate() as GameOverScreen
	add_child(go_screen)
	current_scene = go_screen
	
	go_screen.setup(p_victory, run_state.trophies, run_state.day)
	go_screen.restart_requested.connect(func() -> void:
		_initialize_new_run()
		_go_to_shop()
	)
