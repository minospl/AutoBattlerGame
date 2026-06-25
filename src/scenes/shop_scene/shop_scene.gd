class_name ShopScene
extends Control

## Signal emitted when the team or bench contents are reorganized
signal team_state_changed

@export var active_slot_count: int = 6
@export var bench_slot_count: int = 8

# Logic data structures representing team state
var active_team: Array[UnitInstance] = []
var bench: Array[UnitInstance] = []
var unit_templates: Array[UnitData] = []

@onready var shop_header_bar: ShopHeaderBar = %ShopHeaderBar
@onready var bench_panel: BenchPanel = %BenchPanel
@onready var team_panel: TeamPanel = %TeamPanel
@onready var shop_panel: ShopPanel = %ShopPanel

var gold: int = 10:
	set(value):
		gold = value
		if is_inside_tree() and shop_panel:
			shop_panel.gold = gold

var slot_scene = preload("res://src/shared/components/shop_card_slot.tscn")

var active_slots: Array[ShopCardSlot]:
	get:
		return team_panel.slots

var bench_slots: Array[ShopCardSlot]:
	get:
		return bench_panel.slots

var preview_tooltip: Control

func _ready() -> void:
	active_team.resize(active_slot_count)
	bench.resize(bench_slot_count)
	
	# Connect sub-panel signals
	bench_panel.slot_changed.connect(_on_slot_changed)
	team_panel.slot_changed.connect(_on_slot_changed)
	
	# Connect control panel signals
	shop_header_bar.add_monster_requested.connect(_on_add_monster_requested)
	shop_header_bar.restart_requested.connect(_on_restart_requested)
	shop_header_bar.battle_requested.connect(_on_battle_requested)
	
	# Connect shop panel signals
	shop_panel.roll_requested.connect(_on_roll_requested)
	shop_panel.sell_card_requested.connect(_on_sell_card_requested)
	
	# Setup the side preview panel
	if has_node("%PreviewContainer"):
		var tooltip_scene = load("res://src/shared/components/card_tooltip.tscn")
		preview_tooltip = tooltip_scene.instantiate()
		# Align the preview card to the top of the margin container (height of the bench)
		preview_tooltip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		preview_tooltip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		%PreviewContainer.add_child(preview_tooltip)
		preview_tooltip.visible = false
	
	create_slots()
	
	# Apply visual styling programmatically to keep the presentation premium and clean
	_apply_visual_styling()
	
	# Load our pre-created templates
	var paths : Array[String] = [
		"res://src/resources/units/red_dragon.tres",
		"res://src/resources/units/forest_guardian.tres",
		"res://src/resources/units/wild_wolf.tres",
		"res://src/resources/units/river_crab.tres",
		"res://src/resources/units/spellweaver.tres",
		"res://src/resources/units/vitality_druid.tres",
		"res://src/resources/units/ancient_titan.tres"
	]
	
	for path in paths:
		if not ResourceLoader.exists(path):
			continue
			
		var template = load(path)
		if template == null:
			continue
			
		if not (template is UnitData):
			continue
			
		unit_templates.append(template)
			
	# Initialize CurrentRun if empty, otherwise load it
	if CurrentRun.state == null:
		CurrentRun.initialize_new_run(unit_templates)
		load_state_from_run()
		roll_shop(true)
	else:
		load_state_from_run()
	
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
		bg_style.modulate_color = Color(1.0, 1.0, 1.0, 1.0)
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

func _on_slot_changed(_slot: ShopCardSlot) -> void:
	sync_data_from_ui()
	_on_team_state_changed()

## Rebuild runtime data arrays from current UI slot child structures
func sync_data_from_ui() -> void:
	for i in range(active_slot_count):
		active_team[i] = active_slots[i].get_unit_instance()
		
	for i in range(bench_slot_count):
		bench[i] = bench_slots[i].get_unit_instance()
		
	team_state_changed.emit()

## Populate the UI based on external changes to logic data structures
func populate_ui() -> void:
	var card_scene = load("res://src/shared/components/shop_card.tscn")
	
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
			card.unit_instance = active_team[i]
			_connect_card_signals(card)
			active_slots[i].add_card(card)
			
	for i in range(bench_slot_count):
		if i < bench.size() and bench[i] != null:
			var card = card_scene.instantiate()
			card.unit_instance = bench[i]
			_connect_card_signals(card)
			bench_slots[i].add_card(card)

## Add a unit to the first empty slot on the bench
func add_unit_to_bench(unit: UnitInstance) -> bool:
	for i in range(bench_slot_count):
		if bench[i] == null:
			bench[i] = unit
			var card_scene = load("res://src/shared/components/shop_card.tscn")
			var card = card_scene.instantiate()
			card.unit_instance = unit
			_connect_card_signals(card)
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

func _on_add_monster_requested() -> void:
	if unit_templates.is_empty():
		return
		
	# Pick random template
	var template = unit_templates[randi() % unit_templates.size()]
	
	# Create runtime instance
	var instance = UnitInstance.new()
	instance.initialize(template)
	
	# Try to add to bench
	add_unit_to_bench(instance)

func _on_restart_requested() -> void:
	# 1. Clear team and bench slots
	clear_all()
	
	# 2. Reset header bar values to starting position
	shop_header_bar.lives = 10
	shop_header_bar.day = 4
	shop_header_bar.trophies = 3
	
	# 3. Spawn initial units: 1 of each type
	for template in unit_templates:
		var instance = UnitInstance.new()
		instance.initialize(template)
		add_unit_to_bench(instance)
		
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

func _on_sell_card_requested(card: Control, original_slot: ShopCardSlot) -> void:
	var refund_gold = 1
	if "price" in card:
		refund_gold = card.price
		
	card.queue_free()
	if original_slot:
		original_slot.slot_changed.emit(original_slot)
	gold += refund_gold

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
		
	if slot_index < 3: # Units
		if unit_templates.is_empty():
			return
		var template = unit_templates[randi() % unit_templates.size()]
		var instance = UnitInstance.new()
		instance.initialize(template)
		
		var card_scene = preload("res://src/shared/components/shop_card.tscn")
		var card = card_scene.instantiate()
		card.unit_instance = instance
		_connect_card_signals(card)
		slot.add_card(card)
	else: # Item Card
		var item_scene = preload("res://src/shared/components/shop_card_item.tscn")
		var item_card = item_scene.instantiate() as ShopCardItem
		
		var item_inst = ShopItemInstance.new()
		if randf() < 0.5:
			item_inst.item_name = "Apple"
			item_inst.stat_boost_hp = 2
			item_inst.stat_boost_attack = 0
			item_inst.price = 2
		else:
			item_inst.item_name = "Sword"
			item_inst.stat_boost_hp = 0
			item_inst.stat_boost_attack = 2
			item_inst.price = 3
			
		item_card.item_instance = item_inst
		_connect_card_signals(item_card)
		slot.add_card(item_card)
		
	slot.update_placeholder()

func set_preview_card(card: Control) -> void:
	if not preview_tooltip:
		return
		
	if card is ShopCard and card.unit_instance:
		CardUIHelper.show_tooltip(preview_tooltip, card.unit_instance)
		_on_card_hovered(card, true)
	elif card is ShopCardItem and card.item_instance:
		CardUIHelper.show_item_tooltip(preview_tooltip, card.item_instance)

func clear_preview_card(card: Control = null) -> void:
	if not preview_tooltip:
		return
		
	CardUIHelper.hide_tooltip(preview_tooltip)
	_on_card_hovered(card, false)

func _on_card_hovered(card: Control, is_hovered: bool) -> void:
	# Clear all target highlights first
	for slot in active_slots:
		slot.set_target_highlight(false)
	for slot in bench_slots:
		slot.set_target_highlight(false)
		
	if not is_hovered or card == null or not (card is ShopCard) or card.unit_instance == null:
		return
		
	# Find which slot contains the hovered card
	var source_slot: ShopCardSlot = null
	for slot in active_slots:
		if slot.get_card() == card:
			source_slot = slot
			break
	if not source_slot:
		for slot in bench_slots:
			if slot.get_card() == card:
				source_slot = slot
				break
				
	if not source_slot or not source_slot.is_active_team:
		return # Card is in shop, bench, or not placed in active team
		
	var idx = source_slot.slot_index
	
	if card.unit_instance.data and card.unit_instance.data.modifier:
		var modifier: UnitModifier = card.unit_instance.data.modifier
		# Skip SELF target highlighting as we only want to highlight other targets
		if modifier.target != UnitModifier.TargetType.SELF:
			var target_indices = TargetResolver.get_target_indices(idx, modifier.target)
			for t_idx in target_indices:
				if t_idx < active_slots.size():
					active_slots[t_idx].set_target_highlight(true)

func _connect_card_signals(card: Control) -> void:
	if card.has_signal("hovered"):
		if not card.hovered.is_connected(_on_card_hover_changed):
			card.hovered.connect(_on_card_hover_changed)

func _on_card_hover_changed(card: Control, is_hovered: bool) -> void:
	if is_hovered:
		set_preview_card(card)
	else:
		clear_preview_card(card)

func load_state_from_run() -> void:
	if CurrentRun.state == null:
		return
		
	gold = CurrentRun.state.gold
	shop_header_bar.lives = CurrentRun.state.lives
	shop_header_bar.day = CurrentRun.state.day
	shop_header_bar.trophies = CurrentRun.state.trophies
	
	# Load active team and bench
	active_team = CurrentRun.state.active_team.duplicate()
	bench = CurrentRun.state.bench.duplicate()
	
	populate_ui()
	
	# Recreate cards in shop slots
	for i in range(shop_panel.slots.size()):
		var slot = shop_panel.slots[i]
		
		# Clear current card
		var old_card = slot.get_card()
		if old_card:
			slot.remove_card(old_card)
			old_card.queue_free()
			
		var item_or_unit = CurrentRun.state.shop_units[i]
		var is_frozen = CurrentRun.state.shop_frozen_statuses[i]
		
		slot.is_frozen = is_frozen
		if slot.has_node("%FreezeButton"):
			(slot.get_node("%FreezeButton") as Button).button_pressed = is_frozen
			
		if item_or_unit != null:
			if item_or_unit is UnitInstance:
				var card_scene = load("res://src/shared/components/shop_card.tscn")
				var card = card_scene.instantiate()
				card.unit_instance = item_or_unit
				_connect_card_signals(card)
				slot.add_card(card)
			elif item_or_unit is ShopItemInstance:
				var item_scene = load("res://src/shared/components/shop_card_item.tscn")
				var item_card = item_scene.instantiate() as ShopCardItem
				item_card.item_instance = item_or_unit
				_connect_card_signals(item_card)
				slot.add_card(item_card)
				
		slot.update_placeholder()

func sync_data_to_run_state() -> void:
	if CurrentRun.state == null:
		return
		
	sync_data_from_ui()
	
	CurrentRun.state.gold = gold
	CurrentRun.state.lives = shop_header_bar.lives
	CurrentRun.state.day = shop_header_bar.day
	CurrentRun.state.trophies = shop_header_bar.trophies
	
	CurrentRun.state.active_team = active_team.duplicate()
	CurrentRun.state.bench = bench.duplicate()
	
	for i in range(shop_panel.slots.size()):
		var slot = shop_panel.slots[i]
		var card = slot.get_card()
		if card:
			if card is ShopCard:
				CurrentRun.state.shop_units[i] = card.unit_instance
			elif card is ShopCardItem:
				CurrentRun.state.shop_units[i] = card.item_instance
		else:
			CurrentRun.state.shop_units[i] = null
			
		CurrentRun.state.shop_frozen_statuses[i] = slot.is_frozen

func _on_battle_requested() -> void:
	sync_data_to_run_state()
	get_tree().change_scene_to_file("res://src/scenes/battle_scene/battle_scene.tscn")
