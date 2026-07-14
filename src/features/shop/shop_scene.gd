class_name ShopScene
extends Control

## Signal emitted when the team or bench contents are reorganized
signal team_state_changed
## Signal emitted when the player wants to transition to battle
signal battle_requested
## Signal emitted when the player wants to view the compendium
signal compendium_requested
## Signal emitted when the player wants to restart the run
signal restart_requested

var active_slot_count: int:
	get:
		return RunState.MAX_ACTIVE_TEAM_SIZE

var bench_slot_count: int:
	get:
		return RunState.MAX_BENCH_SIZE

var gold: int:
	get:
		return run_state.gold if run_state else 10
	set(value):
		if run_state:
			run_state.gold = value
		if is_inside_tree() and shop_panel:
			shop_panel.gold = value

var run_state: RunState
var relic_bar: RelicBar = null

@onready var shop_header_bar: ShopHeaderBar = %ShopHeaderBar
@onready var bench_panel: BenchPanel = %BenchPanel
@onready var team_panel: TeamPanel = %TeamPanel
@onready var shop_panel: ShopPanel = %ShopPanel
@onready var relic_bar_wrapper: Control = %RelicBarWrapper

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
	# Connect sub-panel signals
	bench_panel.card_dropped.connect(_on_card_dropped)
	team_panel.card_dropped.connect(_on_card_dropped)
	
	# Connect control panel signals
	shop_header_bar.add_monster_requested.connect(_on_add_monster_requested)
	shop_header_bar.add_relic_requested.connect(_on_add_relic_requested)
	shop_header_bar.restart_requested.connect(_on_restart_requested)
	shop_header_bar.battle_requested.connect(_on_battle_requested)
	shop_header_bar.compendium_requested.connect(func() -> void: compendium_requested.emit())
	
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
	
	# Initialize RelicBar below ShopHeaderBar (inside the scene-defined RelicBarWrapper placeholder)
	if relic_bar_wrapper:
		relic_bar = RelicBar.new()
		relic_bar.setup(preview_tooltip)
		relic_bar.anchor_left = 0.0
		relic_bar.anchor_right = 1.0
		relic_bar.offset_left = 0.0
		relic_bar.offset_right = 0.0
		relic_bar_wrapper.add_child(relic_bar)
	
	# Initialize run state if already set, otherwise wait for setup()
	if run_state:
		load_state_from_run()

func setup(p_state: RunState) -> void:
	run_state = p_state
	
	# Pass run_state to slots
	var all_slots: Array[ShopCardSlot] = []
	all_slots.append_array(active_slots)
	all_slots.append_array(bench_slots)
	all_slots.append_array(shop_panel.slots)
	for slot: ShopCardSlot in all_slots:
		slot.run_state = run_state
		
	# Connect signals from Model (RunState)
	run_state.gold_changed.connect(_on_gold_changed)
	run_state.lives_changed.connect(_on_lives_changed)
	run_state.day_changed.connect(_on_day_changed)
	run_state.trophies_changed.connect(_on_trophies_changed)
	run_state.shop_slot_updated.connect(_on_shop_slot_updated)
	run_state.shop_slot_freeze_changed.connect(_on_shop_slot_freeze_changed)
	run_state.relics_changed.connect(_on_relics_changed)
	
	load_state_from_run()
	
	# If this is a fresh setup with empty shop units, let's roll it!
	var has_shop_cards: bool = false
	for u: Resource in run_state.shop_cards:
		if u != null:
			has_shop_cards = true
			break
	if not has_shop_cards:
		run_state.roll_shop(true)
	
	# Instantiate and add the targeting line overlay to draw on top of everything
	var overlay: Control = Control.new()
	overlay.name = "TargetingLineOverlay"
	overlay.set_script(overlay_script)
	overlay.set("parent_scene", self)
	overlay.z_index = 10
	add_child(overlay)



## Instantiate slot scenes and arrange them inside containers
func create_slots() -> void:
	bench_panel.create_slots(slot_scene, bench_slot_count)
	team_panel.create_slots(slot_scene, active_slot_count)
	shop_panel.create_slots(slot_scene, 4)
	
	var all_slots: Array[ShopCardSlot] = []
	all_slots.append_array(active_slots)
	all_slots.append_array(bench_slots)
	all_slots.append_array(shop_panel.slots)
	
	for slot: ShopCardSlot in all_slots:
		# Connect drag hover signals for target highlighting preview
		slot.drag_hover_started.connect(_on_slot_drag_hover_started)
		slot.drag_hover_ended.connect(_on_slot_drag_hover_ended)


func check_for_unit_merges() -> void:
	if not run_state:
		return
	
	var merge: Dictionary = run_state.check_and_merge_units()
	if not merge.is_empty():
		# Animate this merge and then check again for cascade fusions recursively
		ShopMergeAnimator.animate_merge(self, merge, func() -> void:
			check_for_unit_merges()
		)


## Populate the UI based on external changes to logic data structures
func populate_ui() -> void:
	if run_state == null:
		return
		
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
		if i < run_state.active_team.size() and run_state.active_team[i] != null:
			var card: ShopCard = card_scene.instantiate()
			card.unit_instance = run_state.active_team[i]
			_connect_card_signals(card)
			active_slots[i].add_card(card)
			
	for i: int in range(bench_slot_count):
		if i < run_state.bench.size() and run_state.bench[i] != null:
			var card: ShopCard = card_scene.instantiate()
			card.unit_instance = run_state.bench[i]
			_connect_card_signals(card)
			bench_slots[i].add_card(card)

## Add a unit to the first empty slot on the bench
func add_unit_to_bench(unit: UnitInstance) -> bool:
	if run_state == null:
		return false
	for i: int in range(bench_slot_count):
		if run_state.bench[i] == null:
			run_state.bench[i] = unit
			populate_ui()
			team_state_changed.emit()
			return true
	return false # Bench is full

## Empty all team and bench slots
func clear_all() -> void:
	if run_state == null:
		return
	for i: int in range(active_slot_count):
		run_state.active_team[i] = null
	for i: int in range(bench_slot_count):
		run_state.bench[i] = null
	populate_ui()
	team_state_changed.emit()

func _on_add_monster_requested() -> void:
	if not run_state or run_state.unit_templates.is_empty():
		return
		
	# Pick random template
	var template: UnitData = run_state.unit_templates[randi() % run_state.unit_templates.size()]
	
	# Create runtime instance
	var instance: UnitInstance = UnitInstance.new()
	instance.initialize(template)
	
	# Try to add to bench
	add_unit_to_bench(instance)

func _on_add_relic_requested() -> void:
	run_state.add_random_relic()

func _on_restart_requested() -> void:
	restart_requested.emit()

func _on_team_state_changed() -> void:
	pass

func _on_roll_requested() -> void:
	if run_state:
		run_state.roll_shop(false)

func _on_sell_card_requested(card: Control, original_slot: ShopCardSlot) -> void:
	if original_slot == null or original_slot.is_shop_slot or not run_state:
		return
		
	var unit_inst: UnitInstance = null
	if card is ShopCard:
		unit_inst = (card as ShopCard).unit_instance
			
	if unit_inst == null:
		return
		
	# Execute in Model first
	run_state.sell_unit(original_slot.slot_index, original_slot.is_active_team)
	
	# Incremental UI update: remove and queue free the sold card
	original_slot.remove_card(card)
	card.queue_free()
	original_slot.update_placeholder()
	
	team_state_changed.emit()

func _on_card_dropped(dragged_card: Control, original_slot: ShopCardSlot, target_slot: ShopCardSlot) -> void:
	if not original_slot or not target_slot or not run_state:
		return
		
	if original_slot == target_slot:
		return
		
	# 1. Purchase from the Shop slot
	if original_slot.is_shop_slot:
		if dragged_card is ShopCardItem:
			var target_idx: int = target_slot.slot_index
			var target_is_active: bool = target_slot.is_active_team
			
			var applied: bool = run_state.apply_item(original_slot.slot_index, target_idx, target_is_active)
			if applied:
				# Incremental UI update: refresh the visual stats of the fed unit
				var target_card: Control = target_slot.get_card()
				if target_card and target_card.has_method("update_ui"):
					target_card.call("update_ui")
					
				team_state_changed.emit()
		return
			
	# 2. Relocate / Swap inside team & bench (non-shop slots)
	var source_idx: int = original_slot.slot_index
	var dest_idx: int = target_slot.slot_index
	var source_is_active: bool = original_slot.is_active_team
	var dest_is_active: bool = target_slot.is_active_team
	
	run_state.swap_units(source_idx, source_is_active, dest_idx, dest_is_active)
		
	# Incremental UI update: physically swap card nodes in slots
	var source_card: Control = original_slot.get_card()
	var dest_card: Control = target_slot.get_card()
	
	if source_card:
		original_slot.remove_card(source_card)
	if dest_card:
		target_slot.remove_card(dest_card)
		
	if source_card:
		target_slot.add_card(source_card)
	if dest_card:
		original_slot.add_card(dest_card)
		
	original_slot.update_placeholder()
	target_slot.update_placeholder()
		
	check_for_unit_merges()
	team_state_changed.emit()

func _on_gold_changed(new_gold: int) -> void:
	if shop_panel:
		shop_panel.gold = new_gold

func _on_lives_changed(new_lives: int) -> void:
	if shop_header_bar:
		shop_header_bar.lives = new_lives

func _on_day_changed(new_day: int) -> void:
	if shop_header_bar:
		shop_header_bar.day = new_day

func _on_trophies_changed(new_trophies: int) -> void:
	if shop_header_bar:
		shop_header_bar.trophies = new_trophies

func _on_shop_slot_updated(slot_index: int, card_instance: Resource) -> void:
	if slot_index < 0 or slot_index >= shop_panel.slots.size():
		return
	var slot: ShopCardSlot = shop_panel.slots[slot_index] as ShopCardSlot
	
	# Clear current card
	var old_card: Control = slot.get_card()
	if old_card:
		slot.remove_card(old_card)
		old_card.queue_free()
		
	# Unfreeze slot
	slot.is_frozen = false
	if slot.has_node("%FreezeButton"):
		(slot.get_node("%FreezeButton") as Button).button_pressed = false
		
	if card_instance != null:
		if card_instance is UnitInstance:
			var card: ShopCard = card_scene.instantiate() as ShopCard
			card.unit_instance = card_instance as UnitInstance
			_connect_card_signals(card)
			slot.add_card(card)
		elif card_instance is ItemInstance:
			var card: ShopCardItem = item_card_scene.instantiate() as ShopCardItem
			card.item_instance = card_instance as ItemInstance
			_connect_card_signals(card)
			slot.add_card(card)
	slot.update_placeholder()

func _on_shop_slot_freeze_changed(slot_index: int, is_frozen: bool) -> void:
	if slot_index < 0 or slot_index >= shop_panel.slots.size():
		return
	var slot: ShopCardSlot = shop_panel.slots[slot_index] as ShopCardSlot
	slot.is_frozen = is_frozen
	if slot.has_node("%FreezeButton"):
		var btn: Button = slot.get_node("%FreezeButton") as Button
		if btn.button_pressed != is_frozen:
			btn.set_pressed_no_signal(is_frozen)
		slot.update_freeze_button_style()

func _on_relics_changed(relics: Array[RelicInstance]) -> void:
	relic_bar.update_relics(relics)
	shop_panel.has_unique_potential = run_state.has_unique_potential
	shop_panel.shop_weights = run_state.shop_weights

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
	# If we are losing hover because a drag just started, do NOT clear target highlights!
	# Because the drag hover will take over immediately, avoiding the visual flicker.
	if not is_hovered and (DragManager.dragged_card == card or (card and card.get_viewport().gui_is_dragging())):
		return
		
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
			var target_indices: Array[int] = TargetResolver.get_target_indices(idx, current_target, run_state.has_magnetic_core, run_state.has_focusing_lens)
			for t_idx: int in target_indices:
				if t_idx < active_slots.size():
					active_slots[t_idx].set_target_highlight(true)

func _connect_card_signals(card: Control) -> void:
	if card is ShopCard:
		var shop_card: ShopCard = card
		shop_card.hovered.connect(_on_card_hover_changed)
		shop_card.clicked.connect(_on_card_clicked)
		shop_card.right_clicked.connect(_on_card_right_clicked)
	elif card is ShopCardItem:
		var item_card: ShopCardItem = card
		item_card.hovered.connect(_on_card_hover_changed)
		item_card.clicked.connect(_on_item_card_clicked)

func _on_card_right_clicked(card: ShopCard) -> void:
	if card.slot and card.slot.is_active_team:
		if card.unit_instance:
			card.unit_instance.level_up()
			card.update_ui()
			if preview_tooltip and preview_tooltip.visible and current_hovered_card == card:
				CardUIHelper.show_tooltip(preview_tooltip, card.unit_instance)
			check_for_unit_merges()
			team_state_changed.emit()

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
		
	var dragged_card: Control = data.get("card")
	if not (dragged_card is ShopCard):
		return
		
	var unit_card: ShopCard = dragged_card as ShopCard
	var unit: UnitInstance = unit_card.unit_instance
	if not unit or not unit.data or not unit.data.modifier:
		return
		
	var modifier: UnitModifier = unit.data.modifier
	var current_target: UnitModifier.TargetType = modifier.get_target(unit.level)
	if current_target == UnitModifier.TargetType.SELF:
		return

	var target_indices: Array[int] = TargetResolver.get_target_indices(slot.slot_index, current_target, run_state.has_magnetic_core, run_state.has_focusing_lens)
	for t_idx: int in target_indices:
		if t_idx < active_slots.size():
			active_slots[t_idx].set_target_highlight(true)

func _on_slot_drag_hover_ended(slot: ShopCardSlot) -> void:
	if current_drag_hovered_slot == slot:
		current_drag_hovered_slot = null
		_clear_all_target_highlights()

func _on_card_clicked(card: ShopCard) -> void:
	var original_slot: ShopCardSlot = card.slot
	if not original_slot or not original_slot.is_shop_slot or not run_state:
		return
		
	# Find target slot index (team first, then bench)
	var target_is_active: bool = true
	var target_idx: int = -1
	
	for i: int in range(active_slot_count):
		if run_state.active_team[i] == null:
			target_idx = i
			target_is_active = true
			break
			
	if target_idx == -1:
		for i: int in range(bench_slot_count):
			if run_state.bench[i] == null:
				target_idx = i
				target_is_active = false
				break
				
	if target_idx == -1:
		return # No room
		
	var unit_inst: UnitInstance = card.unit_instance
	
	# Execute buy in Model
	var bought: bool = run_state.buy_unit(original_slot.slot_index, target_idx, target_is_active)
	if bought:
		# Incremental UI update: instantiate and add the card to the target slot
		var target_slot: ShopCardSlot = active_slots[target_idx] if target_is_active else bench_slots[target_idx]
		var new_card: ShopCard = card_scene.instantiate() as ShopCard
		new_card.unit_instance = unit_inst
		_connect_card_signals(new_card)
		target_slot.add_card(new_card)
		target_slot.update_placeholder()
		
		check_for_unit_merges()
		team_state_changed.emit()

func _on_item_card_clicked(card: ShopCardItem) -> void:
	var original_slot: ShopCardSlot = card.slot
	if not original_slot or not original_slot.is_shop_slot or not run_state:
		return
		
	run_state.buy_clickable_item(original_slot.slot_index)
	team_state_changed.emit()

func load_state_from_run() -> void:
	if run_state == null:
		return
		
	if shop_panel:
		shop_panel.gold = run_state.gold
	shop_header_bar.lives = run_state.lives
	shop_header_bar.day = run_state.day
	shop_header_bar.trophies = run_state.trophies
	
	if relic_bar:
		relic_bar.update_relics(run_state.relics)
	
	# Update shop level and chance weights in the shop panel
	shop_panel.shop_level = run_state.shop_level
	shop_panel.has_unique_potential = run_state.has_unique_potential
	shop_panel.shop_weights = run_state.shop_weights
	
	# Ensure active team and bench size matches expectations
	if run_state.active_team.size() != active_slot_count:
		run_state.active_team.resize(active_slot_count)
	if run_state.bench.size() != bench_slot_count:
		run_state.bench.resize(bench_slot_count)
	
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
				var unit_inst: UnitInstance = item_or_unit as UnitInstance
				card.unit_instance = unit_inst
				_connect_card_signals(card)
				slot.add_card(card)
			elif item_or_unit is ItemInstance:
				var item_card: ShopCardItem = item_card_scene.instantiate() as ShopCardItem
				item_card.item_instance = item_or_unit as ItemInstance
				_connect_card_signals(item_card)
				slot.add_card(item_card)
				
		slot.update_placeholder()

func _on_battle_requested() -> void:
	battle_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not run_state:
		return
		
	var key_event: InputEventKey = event as InputEventKey
	if key_event and key_event.pressed and not key_event.echo:
		if key_event.keycode == KEY_R:
			_on_roll_requested()
			return
			
		if key_event.keycode == KEY_S:
			if current_hovered_card and current_hovered_card is ShopCard:
				var slot: ShopCardSlot = current_hovered_card.get_parent() as ShopCardSlot
				if slot and not slot.is_shop_slot:
					if preview_tooltip:
						CardUIHelper.hide_tooltip(preview_tooltip)
					_on_sell_card_requested(current_hovered_card, slot)
					current_hovered_card = null
