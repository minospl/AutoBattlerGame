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

# Drag state tracking for selling
var dragged_card: Control = null
var dragged_card_original_slot: MonsterSlot = null

@onready var shop_bar: ShopBar = %ShopBar
@onready var bench_panel: BenchPanel = %BenchPanel
@onready var team_panel: TeamPanel = %TeamPanel
@onready var shop_panel: ShopPanel = %ShopPanel

var gold: int = 10:
	set(value):
		gold = value
		if is_inside_tree() and shop_panel:
			shop_panel.gold = gold

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
	shop_bar.restart_requested.connect(_on_restart_pressed)
	
	# Connect shop panel signals
	shop_panel.roll_requested.connect(_on_roll_requested)
	shop_panel.sell_card_requested.connect(_on_sell_card_requested)
	
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
		
	# Set initial gold and roll the shop for free
	gold = 10
	roll_shop(true)
	
	# Instantiate and add the targeting line overlay to draw on top of everything
	var overlay_script = load("res://src/scenes/shop_scene/components/targeting_line_overlay.gd")
	var overlay = Control.new()
	overlay.name = "TargetingLineOverlay"
	overlay.set_script(overlay_script)
	overlay.parent_scene = self
	add_child(overlay)
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
	shop_panel.create_slots(slot_scene, 4)

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

func _on_restart_pressed() -> void:
	# 1. Clear team and bench slots
	clear_all()
	
	# 2. Reset shop bar values to starting position
	shop_bar.lives = 10
	shop_bar.day = 4
	shop_bar.trophies = 3
	
	# 3. Spawn initial monsters: 1 of each type
	for template in monster_templates:
		var instance = MonsterInstance.new()
		instance.initialize(template)
		add_monster_to_bench(instance)
		
	# 4. Reset gold to 10 and roll the shop for free
	gold = 10
	roll_shop(true)

func _on_team_state_changed() -> void:
	pass

func get_gold() -> int:
	return gold

func deduct_gold(amount: int) -> void:
	gold -= amount

func _on_roll_requested() -> void:
	if gold >= 1:
		gold -= 1
		roll_shop(false)

func _on_sell_card_requested(card: Control, original_slot: MonsterSlot) -> void:
	var refund_gold = 1
	if "price" in card:
		refund_gold = card.price
		
	card.queue_free()
	if original_slot:
		original_slot.slot_changed.emit(original_slot)
	gold += refund_gold

func notify_drag_started(card: Control, original_slot: MonsterSlot) -> void:
	dragged_card = card
	dragged_card_original_slot = original_slot

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		dragged_card = null
		dragged_card_original_slot = null

func roll_shop(_free: bool = false) -> void:
	for i in range(shop_panel.slots.size()):
		var slot = shop_panel.slots[i]
		
		# If the slot is frozen and is NOT empty, keep it
		if slot.is_frozen and not slot.is_empty():
			continue
			
		refill_shop_slot(i)

func refill_shop_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= shop_panel.slots.size():
		return
		
	var slot = shop_panel.slots[slot_index]
	
	# Clear current card
	var old_card = slot.get_card()
	if old_card:
		slot.remove_card(old_card)
		old_card.queue_free()
		
	# Unfreeze the slot upon refill
	slot.is_frozen = false
	if slot.has_node("%FreezeButton"):
		(slot.get_node("%FreezeButton") as Button).button_pressed = false
		
	if slot_index < 3: # Monsters
		if monster_templates.is_empty():
			return
		var template = monster_templates[randi() % monster_templates.size()]
		var instance = MonsterInstance.new()
		instance.initialize(template)
		
		var card_scene = preload("res://src/shared/components/monster_card.tscn")
		var card = card_scene.instantiate()
		card.monster_instance = instance
		slot.add_card(card)
	else: # Food Item
		var food_scene = preload("res://src/shared/components/food_item.tscn")
		var food_card = food_scene.instantiate() as FoodItem
		if randf() < 0.5:
			food_card.food_name = "Apple"
			food_card.stat_boost_hp = 2
			food_card.stat_boost_attack = 0
			food_card.price = 2
		else:
			food_card.food_name = "Sword"
			food_card.stat_boost_hp = 0
			food_card.stat_boost_attack = 2
			food_card.price = 3
		slot.add_card(food_card)
		
	slot.update_placeholder()
