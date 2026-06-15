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
	
	# Root container transparent style
	var transparent_style = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", transparent_style)
	
	var container_border_color = Color(0.08, 0.08, 0.09, 1.0) # Thick dark outline
	
	# Bench Section Container Style (White Box)
	var bench_style = StyleBoxFlat.new()
	bench_style.bg_color = Color(1.0, 1.0, 1.0, 1.0) # Solid white
	bench_style.border_width_left = 3
	bench_style.border_width_top = 3
	bench_style.border_width_right = 3
	bench_style.border_width_bottom = 3
	bench_style.border_color = container_border_color
	bench_style.corner_radius_top_left = 8
	bench_style.corner_radius_top_right = 8
	bench_style.corner_radius_bottom_right = 8
	bench_style.corner_radius_bottom_left = 8
	%BenchSection.add_theme_stylebox_override("panel", bench_style)
	
	# Bench Header Style (Yellow Banner)
	var bench_header_style = StyleBoxFlat.new()
	bench_header_style.bg_color = Color(0.95, 0.72, 0.18, 1.0) # Yellow (#f1b82d)
	bench_header_style.corner_radius_top_left = 5
	bench_header_style.corner_radius_top_right = 5
	bench_header_style.corner_radius_bottom_right = 0
	bench_header_style.corner_radius_bottom_left = 0
	%BenchHeader.add_theme_stylebox_override("panel", bench_header_style)
	
	# Team Section Container Style (White Box)
	var team_style = StyleBoxFlat.new()
	team_style.bg_color = Color(1.0, 1.0, 1.0, 1.0) # Solid white
	team_style.border_width_left = 3
	team_style.border_width_top = 3
	team_style.border_width_right = 3
	team_style.border_width_bottom = 3
	team_style.border_color = container_border_color
	team_style.corner_radius_top_left = 8
	team_style.corner_radius_top_right = 8
	team_style.corner_radius_bottom_right = 8
	team_style.corner_radius_bottom_left = 8
	%TeamSection.add_theme_stylebox_override("panel", team_style)
	
	# Team Header Style (Pink Banner)
	var team_header_style = StyleBoxFlat.new()
	team_header_style.bg_color = Color(0.89, 0.31, 0.44, 1.0) # Pink (#e24f70)
	team_header_style.corner_radius_top_left = 5
	team_header_style.corner_radius_top_right = 5
	team_header_style.corner_radius_bottom_right = 0
	team_header_style.corner_radius_bottom_left = 0
	%TeamHeader.add_theme_stylebox_override("panel", team_header_style)
	
	# Label outline styling
	var label_outline_color = Color(0.1, 0.1, 0.1, 1.0)
	%BenchLabel.add_theme_color_override("font_outline_color", label_outline_color)
	%BenchLabel.add_theme_constant_override("outline_size", 5)
	%TeamLabel.add_theme_color_override("font_outline_color", label_outline_color)
	%TeamLabel.add_theme_constant_override("outline_size", 5)
	
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
			var card_scene = load("res://src/ui/monster_card.tscn")
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
