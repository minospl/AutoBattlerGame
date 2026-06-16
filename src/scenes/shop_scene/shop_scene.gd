class_name ShopScene
extends Control

## Signal emitted when the team or bench contents are reorganized
signal team_state_changed

@export var active_slot_count: int = 6
@export var bench_slot_count: int = 8

# Logic data structures representing team state
var active_team: Array[MonsterInstance] = []
var bench: Array[MonsterInstance] = []
var monster_templates: Array[MonsterData] = []

@onready var shop_bar: ShopBar = %ShopBar
@onready var bench_panel: BenchPanel = %BenchPanel
@onready var team_panel: TeamPanel = %TeamPanel

var slot_scene = preload("res://src/shared/components/monster_slot.tscn")

var active_slots: Array[MonsterSlot]:
	get:
		return team_panel.slots

var bench_slots: Array[MonsterSlot]:
	get:
		return bench_panel.slots

func _ready() -> void:
	active_team.resize(active_slot_count)
	bench.resize(bench_slot_count)
	
	# Connect sub-panel signals
	bench_panel.slot_changed.connect(_on_slot_changed)
	team_panel.slot_changed.connect(_on_slot_changed)
	
	# Connect control panel signals
	shop_bar.add_monster_requested.connect(_on_add_monster_pressed)
	shop_bar.clear_requested.connect(_on_clear_pressed)
	
	create_slots()
	
	# Apply visual styling programmatically to keep the presentation premium and clean
	_apply_visual_styling()
	
	# Load our pre-created templates
	var paths = [
		"res://src/resources/monsters/czerwony_smok.tres",
		"res://src/resources/monsters/lesny_straznik.tres",
		"res://src/resources/monsters/dziki_wilk.tres",
		"res://src/resources/monsters/rzeczny_krab.tres"
	]
	
	for path in paths:
		if not ResourceLoader.exists(path):
			continue
			
		var template = load(path)
		if template == null:
			continue
			
		if not (template is MonsterData):
			continue
			
		monster_templates.append(template)
			
	# Spawn initial monsters: 1 of each type that currently exists
	for template in monster_templates:
		var instance = MonsterInstance.new()
		instance.initialize(template)
		add_monster_to_bench(instance)

func _apply_visual_styling() -> void:
	# 1. Main Background Panel
	var bg_panel = get_node("BackgroundPanel") as Panel
	if bg_panel:
		var bg_style = StyleBoxTexture.new()
		bg_style.texture = load("res://src/assets/ui/shop_background.jpg")
		bg_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		bg_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		bg_style.modulate_color = Color(1.0, 1.0, 1.0, 1.0) # Full color for the classic Pokemon storage box tiled texture
		bg_panel.add_theme_stylebox_override("panel", bg_style)
	
	# 2. Outer Border Color
	var outer_border = %OuterBorder as ColorRect
	if outer_border:
		outer_border.color = GameColors.PANEL_BORDER_DEFAULT
	


## Instantiate slot scenes and arrange them inside containers
func create_slots() -> void:
	bench_panel.create_slots(slot_scene, bench_slot_count)
	team_panel.create_slots(slot_scene, active_slot_count)

func _on_slot_changed(_slot: MonsterSlot) -> void:
	sync_data_from_ui()
	_on_team_state_changed()

## Rebuild runtime data arrays from current UI slot child structures
func sync_data_from_ui() -> void:
	for i in range(active_slot_count):
		active_team[i] = active_slots[i].get_monster_instance()
		
	for i in range(bench_slot_count):
		bench[i] = bench_slots[i].get_monster_instance()
		
	team_state_changed.emit()

## Populate the UI based on external changes to logic data structures
func populate_ui() -> void:
	var card_scene = load("res://src/shared/components/monster_card.tscn")
	
	# Clear existing cards immediately
	for slot in active_slots:
		var card = slot.get_card()
		if card:
			slot.remove_card(card)
			card.queue_free()
			
	for slot in bench_slots:
		var card = slot.get_card()
		if card:
			slot.remove_card(card)
			card.queue_free()
			
	# Instantiate cards according to the data state
	for i in range(active_slot_count):
		if i < active_team.size() and active_team[i] != null:
			var card = card_scene.instantiate()
			card.monster_instance = active_team[i]
			active_slots[i].add_card(card)
			
	for i in range(bench_slot_count):
		if i < bench.size() and bench[i] != null:
			var card = card_scene.instantiate()
			card.monster_instance = bench[i]
			bench_slots[i].add_card(card)

## Add a monster to the first empty slot on the bench
func add_monster_to_bench(monster: MonsterInstance) -> bool:
	for i in range(bench_slot_count):
		if bench[i] == null:
			bench[i] = monster
			var card_scene = load("res://src/shared/components/monster_card.tscn")
			var card = card_scene.instantiate()
			card.monster_instance = monster
			bench_slots[i].add_card(card)
			sync_data_from_ui()
			return true
	return false # Bench is full

## Empty all team and bench slots
func clear_all() -> void:
	for i in range(active_slot_count):
		active_team[i] = null
		var card = active_slots[i].get_card()
		if card:
			active_slots[i].remove_card(card)
			card.queue_free()
			
	for i in range(bench_slot_count):
		bench[i] = null
		var card = bench_slots[i].get_card()
		if card:
			bench_slots[i].remove_card(card)
			card.queue_free()
			
	sync_data_from_ui()

func _on_add_monster_pressed() -> void:
	if monster_templates.is_empty():
		return
		
	# Pick random template
	var template = monster_templates[randi() % monster_templates.size()]
	
	# Create runtime instance
	var instance = MonsterInstance.new()
	instance.initialize(template)
	
	# Try to add to bench
	add_monster_to_bench(instance)

func _on_clear_pressed() -> void:
	clear_all()

func _on_team_state_changed() -> void:
	pass
