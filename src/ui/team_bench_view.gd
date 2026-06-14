class_name TeamBenchView
extends PanelContainer

## Signal emitted when the team or bench contents are reorganized
signal team_state_changed

@export var active_slot_count: int = 6
@export var bench_slot_count: int = 8

# Logic data structures representing team state
var active_team: Array[MonsterInstance] = []
var bench: Array[MonsterInstance] = []

@onready var frontline_hbox: HBoxContainer = %FrontlineHBox
@onready var backline_hbox: HBoxContainer = %BacklineHBox
@onready var bench_hbox: HBoxContainer = %BenchHBox

var slot_scene = preload("res://src/ui/monster_slot.tscn")

var active_slots: Array[MonsterSlot] = []
var bench_slots: Array[MonsterSlot] = []

func _ready() -> void:
	active_team.resize(active_slot_count)
	bench.resize(bench_slot_count)
	
	# Set up a clean, flat container stylebox (Batamon aesthetic)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.09, 1) # sleek dark background canvas
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.14, 0.15, 0.17, 1.0)
	
	add_theme_stylebox_override("panel", style)
	
	create_slots()

## Instantiate slot scenes and arrange them inside containers
func create_slots() -> void:
	for child in frontline_hbox.get_children():
		child.queue_free()
	for child in backline_hbox.get_children():
		child.queue_free()
	for child in bench_hbox.get_children():
		child.queue_free()
		
	active_slots.clear()
	bench_slots.clear()
	
	# Load slot scene
	var loaded_slot_scene = load("res://src/ui/monster_slot.tscn")
	
	# Active Team Slots (Frontline 3, Backline 3)
	for i in range(active_slot_count):
		var slot = loaded_slot_scene.instantiate() as MonsterSlot
		slot.is_active_team = true
		slot.slot_index = i
		slot.slot_changed.connect(_on_slot_changed)
		
		if i < 3:
			backline_hbox.add_child(slot) # Slots 0, 1, 2 are backline
		else:
			frontline_hbox.add_child(slot) # Slots 3, 4, 5 are frontline
			
		active_slots.append(slot)
		
	# Bench Slots (HBox)
	for i in range(bench_slot_count):
		var slot = loaded_slot_scene.instantiate() as MonsterSlot
		slot.is_active_team = false
		slot.slot_index = i
		slot.slot_changed.connect(_on_slot_changed)
		bench_hbox.add_child(slot)
		bench_slots.append(slot)

func _on_slot_changed(_slot: MonsterSlot) -> void:
	sync_data_from_ui()

## Rebuild runtime data arrays from current UI slot child structures
func sync_data_from_ui() -> void:
	for i in range(active_slot_count):
		active_team[i] = active_slots[i].get_monster_instance()
		
	for i in range(bench_slot_count):
		bench[i] = bench_slots[i].get_monster_instance()
		
	team_state_changed.emit()

## Populate the UI based on external changes to logic data structures
func populate_ui() -> void:
	var card_scene = load("res://src/ui/monster_card.tscn")
	
	# Clear existing cards immediately
	for slot in active_slots:
		var card = slot.get_card()
		if card:
			slot.remove_child(card)
			card.queue_free()
			
	for slot in bench_slots:
		var card = slot.get_card()
		if card:
			slot.remove_child(card)
			card.queue_free()
			
	# Instantiate cards according to the data state
	for i in range(active_slot_count):
		if i < active_team.size() and active_team[i] != null:
			var card = card_scene.instantiate()
			card.monster_instance = active_team[i]
			active_slots[i].add_child(card)
			
	for i in range(bench_slot_count):
		if i < bench.size() and bench[i] != null:
			var card = card_scene.instantiate()
			card.monster_instance = bench[i]
			bench_slots[i].add_child(card)

## Add a monster to the first empty slot on the bench
func add_monster_to_bench(monster: MonsterInstance) -> bool:
	for i in range(bench_slot_count):
		if bench[i] == null:
			bench[i] = monster
			var card_scene = load("res://src/ui/monster_card.tscn")
			var card = card_scene.instantiate()
			card.monster_instance = monster
			bench_slots[i].add_child(card)
			sync_data_from_ui()
			return true
	return false # Bench is full

## Empty all team and bench slots
func clear_all() -> void:
	for i in range(active_slot_count):
		active_team[i] = null
		var card = active_slots[i].get_card()
		if card:
			active_slots[i].remove_child(card)
			card.queue_free()
			
	for i in range(bench_slot_count):
		bench[i] = null
		var card = bench_slots[i].get_card()
		if card:
			bench_slots[i].remove_child(card)
			card.queue_free()
			
	sync_data_from_ui()
