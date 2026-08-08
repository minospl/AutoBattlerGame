class_name ShopScene
extends Control

## Signal emitted when the team or bench contents are reorganized
signal team_state_changed
## Signal emitted when the player wants to transition to battle
signal battle_requested
## Signal emitted when the player wants to open the game menu
signal menu_requested

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
var debug_manager: DebugManager = null

@onready var shop_header_bar: ShopHeaderBar = %ShopHeaderBar
@onready var bench_panel: BenchPanel = %BenchPanel
@onready var team_panel: TeamPanel = %TeamPanel
@onready var shop_panel: ShopPanel = %ShopPanel
@onready var relic_bag_popup: RelicBagPopup = %RelicBagPopup

var shop_slot_scene: PackedScene = preload("res://src/features/shop/components/shop_slot.tscn")
var unit_slot_scene: PackedScene = preload("res://src/features/shop/components/unit_slot.tscn")
var shop_card_unit_scene: PackedScene = preload("res://src/features/shop/components/shop_card_unit.tscn")
var item_card_scene: PackedScene = preload("res://src/features/shop/components/shop_card_item.tscn")
var unit_card_scene: PackedScene = preload("res://src/features/shop/components/unit_card.tscn")
var tooltip_scene: PackedScene = preload("res://src/shared/ui/components/card_tooltip.tscn")

var active_slots: Array[UnitSlot]:
	get:
		return team_panel.slots

var bench_slots: Array[UnitSlot]:
	get:
		return bench_panel.slots

var preview_tooltip: CardTooltip
var current_hovered_card: Control = null
var current_drag_hovered_slot: UnitSlot = null
var floating_text_manager: FloatingTextManager = null

func _ready() -> void:
	floating_text_manager = FloatingTextManager.new()
	floating_text_manager.name = "FloatingTextManager"
	floating_text_manager.z_index = 20
	add_child(floating_text_manager)
	bench_panel.item_dropped.connect(_on_item_dropped)
	bench_panel.unit_dropped.connect(_on_unit_dropped)
	team_panel.item_dropped.connect(_on_item_dropped)
	team_panel.unit_dropped.connect(_on_unit_dropped)
	team_state_changed.connect(_update_team_hp)
	
	# Connect control panel signals
	shop_header_bar.menu_requested.connect(func() -> void: menu_requested.emit())
	
	var battle_btn: Button = get_node_or_null("%StartBattleButton") as Button
	if battle_btn:
		battle_btn.pressed.connect(_on_battle_requested)

	var sim_btn: Button = get_node_or_null("%SimulateBattleButton") as Button
	if sim_btn:
		sim_btn.pressed.connect(_on_simulate_battle_pressed)
	
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
	
	relic_bag_popup.setup(preview_tooltip)
		
	# Bag setup
	shop_header_bar.bag_requested.connect(func() -> void: relic_bag_popup.toggle())
	
	# Initialize run state if already set, otherwise wait for setup()
	if run_state:
		load_state_from_run()

func setup(p_state: RunState) -> void:
	run_state = p_state
	
	# Instantiate and setup DebugManager if running in editor/debug mode
	if OS.is_debug_build():
		debug_manager = DebugManager.new()
		add_child(debug_manager)
		debug_manager.setup(run_state, self)
	
	# Re-create slots using the actual dynamic state sizes
	create_slots()
		
	# Connect signals from Model (RunState)
	run_state.gold_changed.connect(_on_gold_changed)
	run_state.lives_changed.connect(_on_lives_changed)
	run_state.day_changed.connect(_on_day_changed)
	run_state.shop_level_changed.connect(_on_shop_level_changed)
	run_state.shop_slot_updated.connect(_on_shop_slot_updated)
	run_state.shop_slot_freeze_changed.connect(_on_shop_slot_freeze_changed)
	run_state.relics_changed.connect(_on_relics_changed)
	run_state.shop_size_changed.connect(_on_shop_size_changed)
	run_state.base_health_changed.connect(func(_val: int) -> void: _update_team_hp())
	shop_panel.freeze_all_requested.connect(_on_freeze_all_requested)
	
	# Fill any empty (null) shop slots on a new day or initialization
	for i: int in range(run_state.shop_cards.size()):
		if run_state.shop_cards[i] == null:
			run_state.shop_cards[i] = run_state.roll_single_shop_card(i)
			
	run_state.prepare_next_opponent()
	shop_header_bar.setup_opponent_list(run_state)
	load_state_from_run()
	
	# Instantiate and add the targeting line overlay to draw on top of everything
	var overlay: TargetingLineOverlay = TargetingLineOverlay.new()
	overlay.name = "TargetingLineOverlay"
	overlay.z_index = 10
	add_child(overlay)

func show_floating_text_on_slot(slot: UnitSlot, text: String, color: Color) -> void:
	if not slot or not floating_text_manager:
		return
	var pos: Vector2 = slot.global_position + (slot.size * 0.5)
	floating_text_manager.show_popup(text, color, pos)

func _trigger_on_battle_end_modifiers() -> void:
	if not run_state.pending_on_battle_end:
		return
	run_state.pending_on_battle_end = false
	await get_tree().process_frame

	_check_and_execute_slime_fusion()

	for i: int in range(run_state.active_team.size()):
		var unit: UnitInstance = run_state.active_team[i]
		if not unit or not unit.data.modifier:
			continue
			
		if unit.data.modifier.trigger == UnitModifier.Trigger.ON_BATTLE_END:
			unit.data.modifier.apply_shop_modifier(i, run_state.active_team)

func _check_and_execute_slime_fusion() -> bool:
	if run_state.active_team.size() < 6:
		return false

	for u: UnitInstance in run_state.active_team + run_state.bench:
		if u and u.get_unit_name() == "Rainbow Slime":
			return false

	var unique_slimes: Dictionary[String, bool] = {}
	for i: int in range(run_state.active_team.size()):
		var unit: UnitInstance = run_state.active_team[i]
		if unit and unit.has_type("Slime"):
			unique_slimes[unit.data.display_name] = true

	if unique_slimes.size() < 6:
		return false

	var rainbow_template: UnitData = load("res://src/features/units/templates/rainbow_slime.tres")
	var rainbow_inst: UnitInstance = UnitInstance.new()
	rainbow_inst.initialize(rainbow_template)

	var absorbed_list: Array[Dictionary] = []
	for i: int in range(run_state.active_team.size()):
		var slime_inst: UnitInstance = run_state.active_team[i]
		rainbow_inst.absorb_bonus_stats_from(slime_inst)
		absorbed_list.append({
			"unit_data": slime_inst.data,
			"level": slime_inst.level
		})

	var custom_mod: RainbowSlimeModifier = rainbow_inst.data.modifier.duplicate() as RainbowSlimeModifier
	if custom_mod:
		custom_mod.absorbed_units = absorbed_list
		rainbow_inst.data = rainbow_inst.data.duplicate() as UnitData
		rainbow_inst.data.modifier = custom_mod

	var merge_anim_data: Dictionary = {
		"main": {"is_bench": false, "idx": 0},
		"removed": [
			{"is_bench": false, "idx": 1},
			{"is_bench": false, "idx": 2},
			{"is_bench": false, "idx": 3},
			{"is_bench": false, "idx": 4},
			{"is_bench": false, "idx": 5}
		]
	}

	run_state.active_team[0] = rainbow_inst
	for i: int in range(1, run_state.active_team.size()):
		run_state.active_team[i] = null

	ShopMergeAnimator.animate_merge(self, merge_anim_data, func() -> void:
		load_state_from_run()
	, rainbow_inst)
	return true

## Instantiate slot scenes and arrange them inside containers
func create_slots() -> void:
	bench_panel.create_slots(unit_slot_scene, bench_slot_count)
	team_panel.create_slots(unit_slot_scene, active_slot_count)
	
	var shop_size: int = run_state.shop_cards.size() if run_state else RunState.MAX_SHOP_CARDS_SIZE
	shop_panel.create_slots(shop_slot_scene, shop_size)
	
	var all_slots: Array[UnitSlot] = []
	all_slots.append_array(active_slots)
	all_slots.append_array(bench_slots)
	
	for slot: UnitSlot in all_slots:
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
		
	if shop_panel:
		shop_panel.gold = run_state.gold
		shop_panel.shop_level = run_state.shop_level
		shop_panel.shop_weights = run_state.shop_weights
		shop_panel.unique_chance = run_state.unique_chance
		
	# Clear existing cards immediately
	for slot: UnitSlot in active_slots:
		var card: UnitCard = slot.get_card()
		if card:
			slot.remove_card(card)
			card.queue_free()
			
	for slot: UnitSlot in bench_slots:
		var card: UnitCard = slot.get_card()
		if card:
			slot.remove_card(card)
			card.queue_free()
			
	# Instantiate cards according to the data state
	for i: int in range(active_slot_count):
		if i < run_state.active_team.size() and run_state.active_team[i] != null:
			var unit_inst: UnitInstance = run_state.active_team[i]
			_connect_unit_signals(unit_inst, active_slots[i])
			var card: UnitCard = unit_card_scene.instantiate() as UnitCard
			card.unit_instance = unit_inst
			_connect_card_signals(card)
			active_slots[i].add_card(card)
			
	for i: int in range(bench_slot_count):
		if i < run_state.bench.size() and run_state.bench[i] != null:
			var unit_inst: UnitInstance = run_state.bench[i]
			_connect_unit_signals(unit_inst, bench_slots[i])
			var card: UnitCard = unit_card_scene.instantiate() as UnitCard
			card.unit_instance = unit_inst
			_connect_card_signals(card)
			bench_slots[i].add_card(card)
			
	_update_team_hp()

func _connect_unit_signals(unit: UnitInstance, slot: UnitSlot) -> void:
	if not unit:
		return

	if not unit.stat_buffed.is_connected(_on_unit_stat_buffed.bind(slot)):
		unit.stat_buffed.connect(_on_unit_stat_buffed.bind(slot))

func _on_unit_stat_buffed(stat_type: StatType.Type, amount: int, slot: UnitSlot) -> void:
	show_floating_text_on_slot(slot, "+" + NumberFormatter.format_large_number(amount) + " " + StatType.get_stat_name(stat_type), StatType.get_stat_color(stat_type))
	var card: UnitCard = slot.get_card()
	card.update_ui()

	if stat_type == StatType.Type.HP:
		_update_team_hp()

func _calculate_total_team_hp() -> int:
	var total_hp: int = run_state.base_health
	for unit: UnitInstance in run_state.active_team:
		if unit:
			total_hp += unit.get_max_health()
	return total_hp

func _update_team_hp() -> void:
	team_panel.update_team_hp(_calculate_total_team_hp())

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

func _on_roll_requested() -> void:
	run_state.request_shop_roll()

func _on_sell_card_requested(card: UnitCard, original_slot: UnitSlot) -> void:
	# Execute in Model first
	run_state.sell_unit(original_slot.slot_index, original_slot.is_active_team)
	
	# Incremental UI update: remove and queue free the sold card
	original_slot.remove_card(card)
	card.queue_free()
	original_slot.update_placeholder()
	
	team_state_changed.emit()

func _on_item_dropped(_item_card: ShopCardItem, original_slot: ShopSlot, target_slot: UnitSlot) -> void:
	if original_slot == target_slot:
		return
		
	# Purchase and apply item from the Shop slot
	var target_idx: int = target_slot.slot_index
	var target_is_active: bool = target_slot.is_active_team
	
	var applied: bool = run_state.apply_item(original_slot.slot_index, target_idx, target_is_active)
	if applied:
		team_state_changed.emit()

func _on_unit_dropped(unit_card: UnitCard, original_slot: UnitSlot, target_slot: UnitSlot) -> void:
	if original_slot == target_slot:
		return
			
	# 2. Relocate / Swap inside team & bench (non-shop slots)
	var source_idx: int = original_slot.slot_index
	var dest_idx: int = target_slot.slot_index
	var source_is_active: bool = original_slot.is_active_team
	var dest_is_active: bool = target_slot.is_active_team
	
	run_state.swap_units(source_idx, source_is_active, dest_idx, dest_is_active)
		
	# Incremental UI update: physically swap card nodes in slots
	var dest_card: UnitCard = target_slot.get_card()
	
	original_slot.remove_card(unit_card)
	if dest_card:
		target_slot.remove_card(dest_card)
		
	target_slot.add_card(unit_card)
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
	if shop_panel and run_state:
		shop_panel.shop_level = run_state.shop_level
		shop_panel.shop_weights = run_state.shop_weights

func _on_shop_level_changed(new_level: int) -> void:
	if shop_panel and run_state:
		shop_panel.shop_level = new_level
		shop_panel.shop_weights = run_state.shop_weights

func _on_shop_slot_updated(slot_index: int, card_instance: Resource) -> void:
	if slot_index < 0 or slot_index >= shop_panel.slots.size():
		return
	var slot: ShopSlot = shop_panel.slots[slot_index] as ShopSlot
	
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
			var card: ShopCardUnit = shop_card_unit_scene.instantiate() as ShopCardUnit
			card.unit_instance = card_instance as UnitInstance
			_connect_card_signals(card)
			slot.add_card(card)
		elif card_instance is ItemInstance:
			var card: ShopCardItem = item_card_scene.instantiate() as ShopCardItem
			card.item_instance = card_instance as ItemInstance
			card.affordability_validator = func() -> bool: return run_state.gold >= card.price
			_connect_card_signals(card)
			slot.add_card(card)
	slot.update_placeholder()

func _on_shop_slot_freeze_changed(slot_index: int, is_frozen: bool) -> void:
	if slot_index < 0 or slot_index >= shop_panel.slots.size():
		return
	var slot: ShopSlot = shop_panel.slots[slot_index] as ShopSlot
	slot.is_frozen = is_frozen
	
	# Update shop panel's freeze all button state
	var all_frozen: bool = true
	for i: int in range(run_state.shop_frozen_statuses.size()):
		if not run_state.shop_frozen_statuses[i]:
			all_frozen = false
			break
	shop_panel.is_shop_frozen = all_frozen

func _on_freeze_all_requested(freeze: bool) -> void:
	for i: int in range(run_state.shop_frozen_statuses.size()):
		if run_state.shop_frozen_statuses[i] != freeze:
			run_state.toggle_freeze_shop_slot(i)

func _on_relics_changed(relics: Array[RelicInstance]) -> void:
	relic_bag_popup.update_relics(relics)
	shop_header_bar.update_bag_count(relics.size())
	if shop_panel and run_state:
		shop_panel.unique_chance = run_state.unique_chance
		shop_panel.shop_level = run_state.shop_level
		shop_panel.shop_weights = run_state.shop_weights
	_update_team_hp()

func _on_shop_size_changed(new_size: int) -> void:
	shop_panel.create_slots(shop_slot_scene, new_size)
	load_state_from_run()

func set_preview_card(card: Control) -> void:
	if not preview_tooltip:
		return
		
	current_hovered_card = card
	
	if card is ShopCardUnit:
		var shop_card: ShopCardUnit = card
		if shop_card.unit_instance:
			CardUIHelper.show_tooltip(preview_tooltip, shop_card.unit_instance)
	elif card is UnitCard:
		var unit_card: UnitCard = card
		if unit_card.unit_instance:
			CardUIHelper.show_tooltip(preview_tooltip, unit_card.unit_instance)
			_on_unit_hovered(unit_card, true)
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
	if card is UnitCard:
		_on_unit_hovered(card as UnitCard, false)

func _clear_all_target_highlights() -> void:
	for slot: UnitSlot in active_slots:
		slot.set_target_highlight(false)
	for slot: UnitSlot in bench_slots:
		slot.set_target_highlight(false)

func _on_unit_hovered(card: UnitCard, is_hovered: bool) -> void:
	# If we are losing hover because a drag just started, do NOT clear target highlights!
	# Because the drag hover will take over immediately, avoiding the visual flicker.
	if not is_hovered and (DragManager.dragged_card == card or (card and card.get_viewport().gui_is_dragging())):
		return
		
	# Clear all target highlights first
	_clear_all_target_highlights()
		
	if not is_hovered or card == null or card.unit_instance == null:
		return
		
	# Find which slot contains the hovered card
	var source_slot: UnitSlot = null
	for slot: UnitSlot in active_slots:
		if slot.get_card() == card:
			source_slot = slot
			break
	if not source_slot:
		for slot: UnitSlot in bench_slots:
			if slot.get_card() == card:
				source_slot = slot
				break
				
	if not source_slot or not source_slot.is_active_team:
		return # Card is in bench or not placed in active team
		
	var idx: int = source_slot.slot_index
	if card.unit_instance.data and card.unit_instance.data.modifier:
		var modifier: UnitModifier = card.unit_instance.data.modifier
		# Skip SELF target highlighting as we only want to highlight other targets
		var current_target: UnitModifier.TargetType = modifier.get_target(card.unit_instance.level)
		if current_target != UnitModifier.TargetType.SELF:
			var target_indices: Array[int] = TargetResolver.get_target_indices(idx, current_target, run_state.has_magnetic_core, run_state.has_focusing_lens)
			for t_idx: int in target_indices:
				if t_idx < active_slots.size():
					active_slots[t_idx].set_target_highlight(true)

func _connect_card_signals(card: Control) -> void:
	if card is ShopCardUnit:
		var shop_card: ShopCardUnit = card
		shop_card.hovered.connect(_on_card_hover_changed)
		shop_card.clicked.connect(_on_card_clicked)
	elif card is UnitCard:
		var unit_card: UnitCard = card
		unit_card.hovered.connect(_on_card_hover_changed)
		if debug_manager:
			unit_card.gui_input.connect(debug_manager.on_card_gui_input.bind(unit_card))
	elif card is ShopCardItem:
		var item_card: ShopCardItem = card
		item_card.hovered.connect(_on_card_hover_changed)
		item_card.clicked.connect(_on_item_card_clicked)

func _on_card_hover_changed(card: Control, is_hovered: bool) -> void:
	if is_hovered:
		set_preview_card(card)
	else:
		clear_preview_card(card)

func _on_slot_drag_hover_started(slot: UnitSlot, data: Dictionary) -> void:
	current_drag_hovered_slot = slot
	_clear_all_target_highlights()
	
	if not slot.is_active_team:
		return
		
	var dragged_card: Control = data.get("card")
	var unit_inst: UnitInstance = null
	if dragged_card is UnitCard:
		unit_inst = (dragged_card as UnitCard).unit_instance
		
	if not unit_inst:
		return
		
	if not unit_inst.data or not unit_inst.data.modifier:
		return
		
	var modifier: UnitModifier = unit_inst.data.modifier
	var current_target: UnitModifier.TargetType = modifier.get_target(unit_inst.level)
	if current_target == UnitModifier.TargetType.SELF:
		return

	var target_indices: Array[int] = TargetResolver.get_target_indices(slot.slot_index, current_target, run_state.has_magnetic_core, run_state.has_focusing_lens)
	for t_idx: int in target_indices:
		if t_idx < active_slots.size():
			active_slots[t_idx].set_target_highlight(true)

func _on_slot_drag_hover_ended(slot: UnitSlot) -> void:
	if current_drag_hovered_slot == slot:
		current_drag_hovered_slot = null
		_clear_all_target_highlights()

func _on_card_clicked(card: ShopCardUnit) -> void:
	var original_slot: ShopSlot = card.slot
	if not original_slot or not run_state:
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
		var target_slot: UnitSlot = active_slots[target_idx] if target_is_active else bench_slots[target_idx]
		var new_card: UnitCard = unit_card_scene.instantiate() as UnitCard
		new_card.unit_instance = unit_inst
		_connect_card_signals(new_card)
		target_slot.add_card(new_card)
		target_slot.update_placeholder()
		
		check_for_unit_merges()
		team_state_changed.emit()

func _on_item_card_clicked(card: ShopCardItem) -> void:
	var original_slot: ShopSlot = card.slot
	if not original_slot or not run_state:
		return
		
	run_state.buy_clickable_item(original_slot.slot_index)
	team_state_changed.emit()

func load_state_from_run() -> void:
	if run_state == null:
		return
		
	shop_panel.gold = run_state.gold
	shop_header_bar.lives = run_state.lives
	shop_header_bar.day = run_state.day
	shop_header_bar.max_rounds = run_state.max_rounds
	shop_header_bar.is_deathmatch = run_state.is_deathmatch
	
	relic_bag_popup.update_relics(run_state.relics)
	shop_header_bar.update_bag_count(run_state.relics.size())
	
	# Update shop level and chance weights in the shop panel
	shop_panel.shop_level = run_state.shop_level
	shop_panel.unique_chance = run_state.unique_chance
	shop_panel.shop_weights = run_state.shop_weights
	
	# Ensure active team and bench size matches expectations
	if run_state.active_team.size() != active_slot_count:
		run_state.active_team.resize(active_slot_count)
	if run_state.bench.size() != bench_slot_count:
		run_state.bench.resize(bench_slot_count)
	
	populate_ui()
	_trigger_on_battle_end_modifiers()
	
	# Recreate cards in shop slots
	for i: int in range(shop_panel.slots.size()):
		var slot: ShopSlot = shop_panel.slots[i] as ShopSlot
		
		# Clear current card
		var old_card: Control = slot.get_card()
		if old_card:
			slot.remove_card(old_card)
			old_card.queue_free()
			
		var item_or_unit: Resource = run_state.shop_cards[i]
		slot.is_frozen = run_state.shop_frozen_statuses[i]
			
		if item_or_unit != null:
			if item_or_unit is UnitInstance:
				var card: ShopCardUnit = shop_card_unit_scene.instantiate() as ShopCardUnit
				var unit_inst: UnitInstance = item_or_unit as UnitInstance
				card.unit_instance = unit_inst
				_connect_card_signals(card)
				slot.add_card(card)
			elif item_or_unit is ItemInstance:
				var item_card: ShopCardItem = item_card_scene.instantiate() as ShopCardItem
				item_card.item_instance = item_or_unit as ItemInstance
				item_card.affordability_validator = func() -> bool: return run_state.gold >= item_card.price
				_connect_card_signals(item_card)
				slot.add_card(item_card)
				
		slot.update_placeholder()
			
	var all_frozen: bool = true
	for i: int in range(run_state.shop_frozen_statuses.size()):
		if not run_state.shop_frozen_statuses[i]:
			all_frozen = false
			break
	shop_panel.is_shop_frozen = all_frozen

func _on_battle_requested() -> void:
	battle_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
		
	var key_event: InputEventKey = event as InputEventKey
	match key_event.keycode:
		KEY_R:
			_on_roll_requested()
		KEY_S:
			if current_hovered_card and current_hovered_card is UnitCard:
				var unit_card: UnitCard = current_hovered_card as UnitCard
				var slot: UnitSlot = unit_card.slot
				CardUIHelper.hide_tooltip(preview_tooltip)
				_on_sell_card_requested(unit_card, slot)
				current_hovered_card = null

func _on_simulate_battle_pressed() -> void:
	if run_state == null:
		return

	# Prepare player units (cloned)
	var player_units: Array[UnitInstance] = []
	for i: int in range(RunState.MAX_ACTIVE_TEAM_SIZE):
		var inst: UnitInstance = run_state.active_team[i]
		if inst:
			player_units.append(inst.clone())
		else:
			player_units.append(null)

	# Prepare player relics (cloned)
	var player_relics: Array[RelicInstance] = []
	for relic: RelicInstance in run_state.relics:
		player_relics.append(relic.clone())

	# Prepare enemy units & relics (cloned)
	var enemy_units: Array[UnitInstance] = []
	enemy_units.resize(RunState.MAX_ACTIVE_TEAM_SIZE)
	var enemy_relics: Array[RelicInstance] = []

	var opponent: OpponentProfile = run_state.next_opponent
	if opponent and not opponent.active_team.is_empty():
		for i: int in range(RunState.MAX_ACTIVE_TEAM_SIZE):
			if i < opponent.active_team.size() and opponent.active_team[i] != null:
				enemy_units[i] = opponent.active_team[i].clone()
		if "relics" in opponent:
			enemy_relics = opponent.relics

	# Run simulation via BattleEngine
	var result: Dictionary[String, Variant] = BattleEngine.simulate_battle(
		player_units,
		run_state.base_health,
		player_relics,
		enemy_units,
		RunState.STARTING_BASE_HEALTH,
		enemy_relics
	)

	_print_simulation_report(result, run_state.active_team, opponent)

func _print_simulation_report(result: Dictionary[String, Variant], original_player_units: Array[UnitInstance], opponent: OpponentProfile) -> void:
	var outcome: String = str(result.get("outcome", "UNKNOWN")).to_upper()
	var total_time: float = result.get("total_time", 0.0)
	var p_hp: int = result.get("player_final_health", 0)
	var e_hp: int = result.get("enemy_final_health", 0)
	var sim_p_units: Array = result.get("player_units", [])
	var sim_e_units: Array = result.get("enemy_units", [])

	var outcome_color: String = "gold"
	if outcome == "DEFEAT":
		outcome_color = "red"
	elif outcome == "DRAW":
		outcome_color = "gray"

	print_rich("[color=cyan]===========================================================[/color]")
	print_rich("[color=cyan]            🧪 BATTLE SIMULATION REPORT 🧪[/color]")
	print_rich("[color=cyan]===========================================================[/color]")
	print_rich("[b]OUTCOME:[/b] [color=%s][b]%s[/b][/color]" % [outcome_color, outcome])
	print_rich("[b]ESTIMATED DURATION:[/b] %.1fs" % total_time)
	print_rich("[b]PLAYER TEAM FINAL HP:[/b] %d" % p_hp)
	print_rich("[b]ENEMY TEAM FINAL HP:[/b]  %d" % e_hp)
	print_rich("-----------------------------------------------------------")
	
	# Player Team Table
	print_rich("[color=yellow][b]--- PLAYER TEAM STATS (BEFORE ➔ AFTER) ---[/b][/color]")
	for i: int in range(RunState.MAX_ACTIVE_TEAM_SIZE):
		var orig: UnitInstance = original_player_units[i] if i < original_player_units.size() else null
		var sim_unit: UnitInstance = sim_p_units[i] if i < sim_p_units.size() else null
		_print_unit_stats(i, orig, sim_unit)

	print_rich("-----------------------------------------------------------")
	# Enemy Team Table
	var opp_name: String = opponent.name if opponent else "Enemy"
	print_rich("[color=orange][b]--- ENEMY TEAM (%s) STATS (BEFORE ➔ AFTER) ---[/b][/color]" % opp_name)
	var orig_enemy_units: Array[UnitInstance] = opponent.active_team if opponent else []
	for i: int in range(RunState.MAX_ACTIVE_TEAM_SIZE):
		var orig: UnitInstance = orig_enemy_units[i] if i < orig_enemy_units.size() else null
		var sim_unit: UnitInstance = sim_e_units[i] if i < sim_e_units.size() else null
		_print_unit_stats(i, orig, sim_unit)

	print_rich("[color=cyan]===========================================================[/color]\n")

func _print_unit_stats(i: int, orig: UnitInstance, sim_unit: UnitInstance) -> void:
	if orig:
		print_rich(" Slot %d | [b]%s[/b] (★%d) %s" % [i, orig.data.display_name, orig.level, _format_unit_all_stats(orig, sim_unit)])
	else:
		print_rich(" Slot %d | [color=gray][EMPTY][/color]" % i)

func _format_unit_all_stats(orig: UnitInstance, sim: UnitInstance) -> String:
	var parts: Array[String] = []
	var extra_stats: Array[Dictionary] = [
		{"name": "CD", "o": orig.get_cast_speed(), "s": sim.get_cast_speed()},
		{"name": "ATK", "o": orig.get_attack(), "s": sim.get_attack()},
		{"name": "HP", "o": orig.health, "s": sim.health},
		{"name": "HEAL", "o": orig.heal, "s": sim.heal},
		{"name": "SHIELD", "o": orig.shield, "s": sim.shield},
		{"name": "POISON", "o": orig.poison, "s": sim.poison},
		{"name": "BURN", "o": orig.burn, "s": sim.burn},
		{"name": "ELEC", "o": orig.electrocute, "s": sim.electrocute}
	]

	for stat_info: Dictionary in extra_stats:
		var s_name: String = stat_info["name"]
		var o_val: Variant = stat_info["o"]
		var s_val: Variant = stat_info["s"]
		var diff: Variant = s_val - o_val
		var val_str: String = "%s➔%s" % [o_val, s_val]
		if s_val > o_val: val_str += " [color=green](+%s)[/color]" % diff
		elif s_val < o_val: val_str += " [color=red](%s)[/color]" % diff
		parts.append("%s: %s" % [s_name, val_str])

	return " | ".join(parts)
