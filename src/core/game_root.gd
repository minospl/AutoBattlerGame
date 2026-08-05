class_name GameRoot
extends Node

@export var shop_scene_path: String = "res://src/features/shop/shop_scene.tscn"
@export var battle_scene_path: String = "res://src/features/battle/battle_scene.tscn"
@export var compendium_scene_path: String = "res://src/features/compendium/compendium_scene.tscn"
@export var game_over_scene_path: String = "res://src/core/game_over_screen.tscn"
@export var game_menu_modal_scene: PackedScene = preload("res://src/features/menu/game_menu_modal.tscn")
@export var settings_modal_scene: PackedScene = preload("res://src/features/settings/settings_modal.tscn")

var run_state: RunState
@export var unit_templates: Array[UnitData] = []
@export var item_templates: Array[ItemData] = []
@export var relic_templates: Array[RelicData] = []
var current_scene: Node = null
var current_modal: Control = null

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	_load_unit_templates()
	_load_item_templates()
	_load_relic_templates()
	_initialize_new_run()
	_go_to_shop()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_modal and is_instance_valid(current_modal):
			return
		if current_scene and current_scene is ShopScene:
			get_viewport().set_input_as_handled()
			_open_game_menu_modal()

func _load_unit_templates() -> void:
	unit_templates.clear()
	var resources: Array[Resource] = _load_resources_from_dir("res://src/features/units/templates/")
	for res: UnitData in resources:
		if not unit_templates.has(res):
			unit_templates.append(res)

func _load_item_templates() -> void:
	item_templates.clear()
	var resources: Array[Resource] = _load_resources_from_dir("res://src/features/items/templates/")
	for res: ItemData in resources:
		if not item_templates.has(res):
			item_templates.append(res)

func _load_relic_templates() -> void:
	relic_templates.clear()
	var resources: Array[Resource] = _load_resources_from_dir("res://src/features/relics/templates/")
	for res: RelicData in resources:
		if not relic_templates.has(res):
			relic_templates.append(res)

func _load_resources_from_dir(path: String) -> Array[Resource]:
	var list: Array[Resource] = []
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		printerr("Failed to open directory: ", path)
		return list
		
	for file_name: String in dir.get_files():
		var clean_name: String = file_name
		if file_name.ends_with(".remap"):
			clean_name = file_name.left(file_name.length() - 6)
			
		if clean_name.ends_with(".tres"):
			var full_path: String = path + clean_name
			if ResourceLoader.exists(full_path):
				var res: Resource = ResourceLoader.load(full_path, "", ResourceLoader.CACHE_MODE_REPLACE)
				if res and not list.has(res):
					list.append(res)
					
	return list

func _initialize_new_run() -> void:
	_load_unit_templates()
	run_state = RunState.new()
	run_state.setup_templates(unit_templates, item_templates, relic_templates)
	run_state.active_team.resize(RunState.MAX_ACTIVE_TEAM_SIZE)
	run_state.bench.resize(RunState.MAX_BENCH_SIZE)
	run_state.shop_cards.resize(RunState.MAX_SHOP_CARDS_SIZE)
	run_state.shop_frozen_statuses.resize(RunState.MAX_SHOP_CARDS_SIZE)
	run_state.shop_frozen_statuses.fill(false)
	run_state.shop_level = 1
	run_state.opponent_provider = OfflineOpponentProvider.new(unit_templates)
	
	# Find templates by unit name
	var find_template: Callable = func(p_name: String) -> UnitData:
		for t: UnitData in unit_templates:
			if t and t.display_name.to_lower() == p_name.to_lower():
				return t
		return null

	var water_slime: UnitData = find_template.call("Water Slime")
	var plant_slime: UnitData = find_template.call("Plant Slime")
	var earth_slime: UnitData = find_template.call("Earth Slime")
	var toxic_slime: UnitData = find_template.call("Toxic Slime")
	var fire_slime: UnitData = find_template.call("Fire Slime")
	var dragon_slime: UnitData = find_template.call("Dragon Slime")

	var setup: Array[UnitData] = [water_slime, plant_slime, earth_slime, toxic_slime, fire_slime, dragon_slime]
	for i: int in range(RunState.MAX_ACTIVE_TEAM_SIZE):
		var temp: UnitData = setup[i]
		if temp:
			var instance: UnitInstance = UnitInstance.new()
			instance.initialize(temp)
			instance.level = randi_range(1, 3)
			run_state.active_team[i] = instance
		else:
			run_state.active_team[i] = null

func _change_scene(scene_path: String, setup_callable: Callable) -> void:
	_close_modal()
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
			shop.menu_requested.connect(_on_menu_requested)
	)

func _restart_run() -> void:
	_initialize_new_run()
	_go_to_shop()

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
	var ruleset: BattleRuleset
	if run_state.is_deathmatch and not run_state.is_endless_mode:
		ruleset = DeathmatchBattleRuleset.new()
	else:
		ruleset = StandardBattleRuleset.new()
		
	_change_scene(battle_scene_path, func(battle_node: Node) -> void:
		var battle: BattleScene = battle_node as BattleScene
		if battle:
			battle.setup(run_state, ruleset)
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

func _on_menu_requested() -> void:
	if current_modal and is_instance_valid(current_modal):
		_close_modal()
	else:
		_open_game_menu_modal()

func _open_game_menu_modal() -> void:
	_close_modal()
	if not game_menu_modal_scene:
		printerr("Failed to load GameMenuModal")
		return
	var modal: GameMenuModal = game_menu_modal_scene.instantiate() as GameMenuModal
	add_child(modal)
	current_modal = modal
	
	modal.resume_requested.connect(_close_modal)
	modal.compendium_requested.connect(func() -> void:
		_close_modal()
		_go_to_compendium()
	)
	modal.settings_requested.connect(_open_settings_modal)
	modal.restart_requested.connect(func() -> void:
		_close_modal()
		_restart_run()
	)

func _open_settings_modal() -> void:
	_close_modal()
	if not settings_modal_scene:
		printerr("Failed to load SettingsModal")
		return
	var modal: SettingsModal = settings_modal_scene.instantiate() as SettingsModal
	add_child(modal)
	current_modal = modal
	
	modal.back_requested.connect(_open_game_menu_modal)

func _close_modal() -> void:
	if current_modal and is_instance_valid(current_modal):
		current_modal.queue_free()
	current_modal = null
