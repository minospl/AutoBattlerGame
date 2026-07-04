class_name ShopScene
extends Control

## Signal emitted when the team or bench contents are reorganized
signal team_state_changed
## Signal emitted when the player wants to transition to battle
signal battle_requested

@export var active_slot_count: int = 6
@export var bench_slot_count: int = 8

# Logic data structures representing team state
var active_team: Array[UnitInstance] = []
var bench: Array[UnitInstance] = []
var unit_templates: Array[UnitData] = []
var item_templates: Array[ItemData] = []
var run_state: RunState

@onready var shop_header_bar: ShopHeaderBar = %ShopHeaderBar
@onready var bench_panel: BenchPanel = %BenchPanel
@onready var team_panel: TeamPanel = %TeamPanel
@onready var shop_panel: ShopPanel = %ShopPanel

var gold: int = 10:
	set(value):
		gold = value
		if is_inside_tree() and shop_panel:
			shop_panel.gold = gold

var slot_scene: PackedScene = preload("res://src/features/shop/components/shop_card_slot.tscn")
var card_scene: PackedScene = preload("res://src/features/shop/components/shop_card.tscn")
var item_card_scene: PackedScene = preload("res://src/features/shop/components/shop_card_item.tscn")
var tooltip_scene: PackedScene = preload("res://src/shared/ui/components/card_tooltip.tscn")
var overlay_script: Script = preload("res://src/features/shop/components/targeting_line_overlay.gd")

var active_slots: Array[ShopCardSlot]:
	get:
		return team_panel.slots

var bench_slots: Array[ShopCardSlot]:
	get:
		return bench_panel.slots

var preview_tooltip: CardTooltip
var current_hovered_card: Control = null
var current_drag_hovered_slot: ShopCardSlot = null

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
		preview_tooltip = tooltip_scene.instantiate() as CardTooltip
		# Align the preview card to the top of the margin container (height of the bench)
		preview_tooltip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		preview_tooltip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		%PreviewContainer.add_child(preview_tooltip)
		preview_tooltip.visible = false
	
	create_slots()
	
	# Apply visual styling programmatically to keep the presentation premium and clean
	_apply_visual_styling()
	
	# Initialize run state if already set, otherwise wait for setup()
	if run_state:
		load_state_from_run()

func setup(p_state: RunState, p_templates: Array[UnitData], p_item_templates: Array[ItemData] = []) -> void:
	run_state = p_state
	unit_templates = p_templates
	item_templates = p_item_templates
	
	load_state_from_run()
	
	# If this is a fresh setup with empty shop units, let's roll it!
	var has_shop_cards: bool = false
	for u: Resource in run_state.shop_cards:
		if u != null:
			has_shop_cards = true
			break
	if not has_shop_cards:
		roll_shop(true)
	
	# Instantiate and add the targeting line overlay to draw on top of everything
	var overlay: Control = Control.new()
	overlay.name = "TargetingLineOverlay"
	overlay.set_script(overlay_script)
	overlay.set("parent_scene", self)
	add_child(overlay)

func _apply_visual_styling() -> void:
	# 1. Main Background Panel
	var bg_panel: Panel = get_node("BackgroundPanel") as Panel
	if bg_panel:
		var bg_style: StyleBoxTexture = StyleBoxTexture.new()
		bg_style.texture = load("res://src/assets/ui/shop_background.jpg") as Texture2D
		bg_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		bg_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		bg_style.modulate_color = Color(1.0, 1.0, 1.0, 1.0)
		bg_panel.add_theme_stylebox_override("panel", bg_style)
	
	# 2. Outer Border Color
	var outer_border: ColorRect = %OuterBorder as ColorRect
	if outer_border:
		outer_border.color = GameColors.PANEL_BORDER_DEFAULT

## Instantiate slot scenes and arrange them inside containers
func create_slots() -> void:
	bench_panel.create_slots(slot_scene, bench_slot_count)
	team_panel.create_slots(slot_scene, active_slot_count)
	shop_panel.create_slots(slot_scene, 4)
	
	# Bind dependency injection Callables for slots
	var get_gold_fn: Callable = func() -> int: return get_gold()
	var deduct_gold_fn: Callable = func(amount: int) -> void: deduct_gold(amount)
	var refill_slot_fn: Callable = func(idx: int) -> void: refill_shop_slot(idx)
	
	var all_slots: Array[ShopCardSlot] = []
	all_slots.append_array(active_slots)
	all_slots.append_array(bench_slots)
	all_slots.append_array(shop_panel.slots)
	
	for slot: ShopCardSlot in all_slots:
		slot.gold_provider = get_gold_fn
		slot.gold_deductor = deduct_gold_fn
		slot.shop_refiller = refill_slot_fn
		
		# Connect drag hover signals for target highlighting preview
		if not slot.drag_hover_started.is_connected(_on_slot_drag_hover_started):
			slot.drag_hover_started.connect(_on_slot_drag_hover_started)
		if not slot.drag_hover_ended.is_connected(_on_slot_drag_hover_ended):
			slot.drag_hover_ended.connect(_on_slot_drag_hover_ended)


func _on_slot_changed(_slot: ShopCardSlot) -> void:
	sync_data_from_ui()
	check_for_unit_merges()
	_on_team_state_changed()

func check_for_unit_merges() -> void:
	if not run_state:
		return
	
	run_state.active_team = active_team.duplicate()
	run_state.bench = bench.duplicate()
	
	var merged: bool = false
	while run_state.check_and_merge_units():
		merged = true
		
	if merged:
		active_team = run_state.active_team.duplicate()
		bench = run_state.bench.duplicate()
		populate_ui()

## Rebuild runtime data arrays from current UI slot child structures
func sync_data_from_ui() -> void:
	for i: int in range(active_slot_count):
		active_team[i] = active_slots[i].get_unit_instance()
		
	for i: int in range(bench_slot_count):
		bench[i] = bench_slots[i].get_unit_instance()
		
	team_state_changed.emit()

## Populate the UI based on external changes to logic data structures
func populate_ui() -> void:
	
	# Clear existing cards immediately
	for slot: ShopCardSlot in active_slots:
		var card: Control = slot.get_card()
		if card:
			slot.remove_card(card)
			card.queue_free()
			
	for slot: ShopCardSlot in bench_slots:
		var card: Control = slot.get_card()
		if card:
			slot.remove_card(card)
			card.queue_free()
			
	# Instantiate cards according to the data state
	for i: int in range(active_slot_count):
		if i < active_team.size() and active_team[i] != null:
			var card: ShopCard = card_scene.instantiate()
			card.unit_instance = active_team[i]
			_connect_card_signals(card)
			active_slots[i].add_card(card)
			
	for i: int in range(bench_slot_count):
		if i < bench.size() and bench[i] != null:
			var card: ShopCard = card_scene.instantiate()
			card.unit_instance = bench[i]
			_connect_card_signals(card)
			bench_slots[i].add_card(card)

## Add a unit to the first empty slot on the bench
func add_unit_to_bench(unit: UnitInstance) -> bool:
	for i: int in range(bench_slot_count):
		if bench[i] == null:
			bench[i] = unit
			var card: ShopCard = card_scene.instantiate()
			card.unit_instance = unit
			_connect_card_signals(card)
			bench_slots[i].add_card(card)
			sync_data_from_ui()
			return true
	return false # Bench is full

## Empty all team and bench slots
func clear_all() -> void:
	for i: int in range(active_slot_count):
		active_team[i] = null
		var card: ShopCard = active_slots[i].get_card() 
		if card:
			active_slots[i].remove_card(card)
			card.queue_free()
			
	for i: int in range(bench_slot_count):
		bench[i] = null
		var card: ShopCard = bench_slots[i].get_card()
		if card:
			bench_slots[i].remove_card(card)
			card.queue_free()
			
	sync_data_from_ui()

func _on_add_monster_requested() -> void:
	if unit_templates.is_empty():
		return
		
	# Pick random template
	var template: UnitData = unit_templates[randi() % unit_templates.size()]
	
	# Create runtime instance
	var instance: UnitInstance = UnitInstance.new()
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
	for template: UnitData in unit_templates:
		var instance: UnitInstance = UnitInstance.new()
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
	var refund_gold: int = 1
	if "price" in card:
		refund_gold = card.get("price")
		
	if original_slot:
		original_slot.remove_card(card)
	card.queue_free()
	if original_slot:
		original_slot.slot_changed.emit(original_slot)
	gold += refund_gold

func roll_shop(_free: bool = false) -> void:
	for i: int in range(shop_panel.slots.size()):
		var slot: ShopCardSlot = shop_panel.slots[i] as ShopCardSlot
		
		# If the slot is frozen and is NOT empty, keep it
		if slot.is_frozen and not slot.is_empty():
			continue
			
		refill_shop_slot(i)

func get_random_unit_template_by_rarity(rarity_name: String) -> UnitData:
	var matching: Array[UnitData] = []
	for template: UnitData in unit_templates:
		if template == null:
			continue
		var r_name: String = "Common"
		if template.rarity:
			r_name = template.rarity.rarity_name
		if r_name == rarity_name:
			matching.append(template)
			
	# Fallback if no matching templates
	if matching.is_empty():
		for template: UnitData in unit_templates:
			if template != null:
				matching.append(template)
				
	if matching.is_empty():
		return null
		
	return matching[randi() % matching.size()]

func get_random_item_template_by_rarity(rarity_name: String) -> ItemData:
	var matching: Array[ItemData] = []
	for template: ItemData in item_templates:
		if template == null:
			continue
		var r_name: String = "Common"
		if template.rarity:
			r_name = template.rarity.rarity_name
		if r_name == rarity_name:
			matching.append(template)
			
	# Fallback if no matching templates
	if matching.is_empty():
		for template: ItemData in item_templates:
			if template != null:
				matching.append(template)
				
	if matching.is_empty():
		return null
		
	return matching[randi() % matching.size()]

func refill_shop_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= shop_panel.slots.size():
		return
		
	var slot: ShopCardSlot = shop_panel.slots[slot_index] as ShopCardSlot
	
	# Clear current card
	var old_card: Control = slot.get_card()
	if old_card:
		slot.remove_card(old_card)
		old_card.queue_free()
		
	# Unfreeze the slot upon refill
	slot.is_frozen = false
	if slot.has_node("%FreezeButton"):
		(slot.get_node("%FreezeButton") as Button).button_pressed = false
		
	# Roll 30% chance for an item card if templates are available, else 70% unit card
	var spawn_item: bool = false
	if not item_templates.is_empty() and randf() < 0.3:
		spawn_item = true
		
	var rolled_rarity: String = "Common"
	if run_state:
		rolled_rarity = run_state.roll_rarity_name()
		
	if spawn_item:
		var template: ItemData = get_random_item_template_by_rarity(rolled_rarity)
		if template:
			var instance: ItemInstance = ItemInstance.new()
			instance.initialize(template)
			
			var card: ShopCardItem = item_card_scene.instantiate() as ShopCardItem
			card.item_instance = instance
			_connect_card_signals(card)
			slot.add_card(card)
	else:
		if unit_templates.is_empty():
			return
		var template: UnitData = get_random_unit_template_by_rarity(rolled_rarity)
		if template:
			var instance: UnitInstance = UnitInstance.new()
			instance.initialize(template)
			
			var card: ShopCard = card_scene.instantiate() as ShopCard
			card.unit_instance = instance
			_connect_card_signals(card)
			slot.add_card(card)
		
	slot.update_placeholder()

func set_preview_card(card: Control) -> void:
	if not preview_tooltip:
		return
		
	current_hovered_card = card
	
	if card is ShopCard:
		var shop_card: ShopCard = card
		if shop_card.unit_instance:
			CardUIHelper.show_tooltip(preview_tooltip, shop_card.unit_instance)
			_on_card_hovered(shop_card, true)
	elif card is ShopCardItem:
		var item_card: ShopCardItem = card
		if item_card.item_instance:
			CardUIHelper.show_item_tooltip(preview_tooltip, item_card.item_instance)

func clear_preview_card(card: Control = null) -> void:
	if not preview_tooltip:
		return
		
	# Only clear if the card exiting hover is actually the one currently tracked!
	if card != null and current_hovered_card != card:
		return
		
	current_hovered_card = null
	CardUIHelper.hide_tooltip(preview_tooltip)
	_on_card_hovered(card, false)

func _clear_all_target_highlights() -> void:
	for slot: ShopCardSlot in active_slots:
		slot.set_target_highlight(false)
	for slot: ShopCardSlot in bench_slots:
		slot.set_target_highlight(false)

func _on_card_hovered(card: Control, is_hovered: bool) -> void:
	# Clear all target highlights first
	_clear_all_target_highlights()
		
	if not is_hovered or card == null or not (card is ShopCard) or (card as ShopCard).unit_instance == null:
		return
		
	# Find which slot contains the hovered card
	var source_slot: ShopCardSlot = null
	for slot: ShopCardSlot in active_slots:
		if slot.get_card() == card:
			source_slot = slot
			break
	if not source_slot:
		for slot: ShopCardSlot in bench_slots:
			if slot.get_card() == card:
				source_slot = slot
				break
				
	if not source_slot or not source_slot.is_active_team:
		return # Card is in shop, bench, or not placed in active team
		
	var idx: int = source_slot.slot_index
	var unit_card: ShopCard = card as ShopCard
	if unit_card and unit_card.unit_instance and unit_card.unit_instance.data and unit_card.unit_instance.data.modifier:
		var modifier: UnitModifier = unit_card.unit_instance.data.modifier
		# Skip SELF target highlighting as we only want to highlight other targets
		var current_target: UnitModifier.TargetType = modifier.get_target(unit_card.unit_instance.level)
		if current_target != UnitModifier.TargetType.SELF:
			var target_indices: Array[int] = TargetResolver.get_target_indices(idx, current_target)
			for t_idx: int in target_indices:
				if t_idx < active_slots.size():
					active_slots[t_idx].set_target_highlight(true)

func _connect_card_signals(card: Control) -> void:
	if card is ShopCard:
		var shop_card: ShopCard = card
		if not shop_card.hovered.is_connected(_on_card_hover_changed):
			shop_card.hovered.connect(_on_card_hover_changed)
		if not shop_card.clicked.is_connected(_on_card_clicked):
			shop_card.clicked.connect(_on_card_clicked)
	elif card is ShopCardItem:
		var item_card: ShopCardItem = card
		if not item_card.hovered.is_connected(_on_card_hover_changed):
			item_card.hovered.connect(_on_card_hover_changed)

func _on_card_hover_changed(card: Control, is_hovered: bool) -> void:
	if is_hovered:
		set_preview_card(card)
	else:
		clear_preview_card(card)

func _on_slot_drag_hover_started(slot: ShopCardSlot, data: Dictionary) -> void:
	current_drag_hovered_slot = slot
	_clear_all_target_highlights()
	
	if not slot.is_active_team:
		return
		
	var dragged_card: Variant = data.get("card")
	if not (dragged_card is ShopCard):
		return
		
	var unit_card: ShopCard = dragged_card
	var unit: UnitInstance = unit_card.unit_instance
	if not unit or not unit.data or not unit.data.modifier:
		return
		
	var modifier: UnitModifier = unit.data.modifier
	var current_target: UnitModifier.TargetType = modifier.get_target(unit.level)
	if current_target == UnitModifier.TargetType.SELF:
		return
		
	var target_indices: Array[int] = TargetResolver.get_target_indices(slot.slot_index, current_target)
	for t_idx: int in target_indices:
		if t_idx < active_slots.size():
			active_slots[t_idx].set_target_highlight(true)

func _on_slot_drag_hover_ended(slot: ShopCardSlot) -> void:
	if current_drag_hovered_slot == slot:
		current_drag_hovered_slot = null
		_clear_all_target_highlights()

func _on_card_clicked(card: ShopCard) -> void:
	var original_slot: ShopCardSlot = card.slot
	if not original_slot or not original_slot.is_shop_slot:
		return
		
	# Check gold
	if gold < original_slot.price:
		return
		
	# Find target slot (team first, then bench)
	var target_slot: ShopCardSlot = null
	for s: ShopCardSlot in active_slots:
		if s.is_empty():
			target_slot = s
			break
	if not target_slot:
		for s: ShopCardSlot in bench_slots:
			if s.is_empty():
				target_slot = s
				break
				
	if not target_slot:
		return # No room
		
	# Purchase
	original_slot.remove_card(card)
	target_slot.add_card(card)
	
	deduct_gold(original_slot.price)
	refill_shop_slot(original_slot.slot_index)
	
	original_slot.slot_changed.emit(original_slot)
	target_slot.slot_changed.emit(target_slot)

func load_state_from_run() -> void:
	if run_state == null:
		return
		
	gold = run_state.gold
	shop_header_bar.lives = run_state.lives
	shop_header_bar.day = run_state.day
	shop_header_bar.trophies = run_state.trophies
	
	# Update shop level and chance text in the shop panel
	shop_panel.shop_level = run_state.shop_level
	shop_panel.chance_text = run_state.get_chance_text()
	
	# Load active team and bench
	active_team = run_state.active_team.duplicate()
	bench = run_state.bench.duplicate()
	
	populate_ui()
	
	# Recreate cards in shop slots
	for i: int in range(shop_panel.slots.size()):
		var slot: ShopCardSlot = shop_panel.slots[i] as ShopCardSlot
		
		# Clear current card
		var old_card: Control = slot.get_card()
		if old_card:
			slot.remove_card(old_card)
			old_card.queue_free()
			
		var item_or_unit: Resource = run_state.shop_cards[i]
		var is_frozen: bool = run_state.shop_frozen_statuses[i]
		
		slot.is_frozen = is_frozen
		if slot.has_node("%FreezeButton"):
			(slot.get_node("%FreezeButton") as Button).button_pressed = is_frozen
			
		if item_or_unit != null:
			if item_or_unit is UnitInstance:
				var card: ShopCard = card_scene.instantiate() as ShopCard
				var unit_inst: UnitInstance = item_or_unit
				card.unit_instance = unit_inst
				_connect_card_signals(card)
				slot.add_card(card)
			elif item_or_unit is ItemInstance:
				var item_card: ShopCardItem = item_card_scene.instantiate() as ShopCardItem
				item_card.item_instance = item_or_unit
				_connect_card_signals(item_card)
				slot.add_card(item_card)
				
		slot.update_placeholder()
 
func sync_data_to_run_state() -> void:
	if run_state == null:
		return
		
	sync_data_from_ui()
	
	run_state.gold = gold
	run_state.lives = shop_header_bar.lives
	run_state.day = shop_header_bar.day
	run_state.trophies = shop_header_bar.trophies
	
	run_state.active_team = active_team.duplicate()
	run_state.bench = bench.duplicate()
	
	for i: int in range(shop_panel.slots.size()):
		var slot: ShopCardSlot = shop_panel.slots[i] as ShopCardSlot
		var card: Control = slot.get_card()
		if card:
			if card is ShopCard:
				run_state.shop_cards[i] = (card as ShopCard).unit_instance
			elif card is ShopCardItem:
				run_state.shop_cards[i] = (card as ShopCardItem).item_instance
		else:
			run_state.shop_cards[i] = null
			
		run_state.shop_frozen_statuses[i] = slot.is_frozen
 
func _on_battle_requested() -> void:
	sync_data_to_run_state()
	battle_requested.emit()
