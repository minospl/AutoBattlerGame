class_name ShopHelper
extends RefCounted

static func get_random_unit_template_by_rarity(p_run_state: RunState, rarity_type: Rarity.Type) -> UnitData:
	var matching: Array[UnitData] = []
	for template: UnitData in p_run_state.unit_templates:
		if not template.can_appear_in_shop:
			continue
		var r_type: Rarity.Type = template.rarity.rarity_type

		if r_type == Rarity.Type.UNIQUE:
			if rarity_type == Rarity.Type.UNIQUE:
				matching.append(template)
			continue

		if r_type == rarity_type:
			matching.append(template)

	if matching.is_empty():
		for template: UnitData in p_run_state.unit_templates:
			if not template.can_appear_in_shop:
				continue
			var r_type: Rarity.Type = template.rarity.rarity_type
			if r_type != Rarity.Type.UNIQUE:
				matching.append(template)
				
	if matching.is_empty():
		return null
		
	return matching[randi() % matching.size()]

static func get_random_item_template_by_rarity(p_run_state: RunState, rarity_type: Rarity.Type) -> ItemData:
	var matching: Array[ItemData] = []
	for template: ItemData in p_run_state.item_templates:
		var r_type: Rarity.Type = template.rarity.rarity_type
			
		if r_type == rarity_type:
			matching.append(template)
			
	if matching.is_empty():
		for template: ItemData in p_run_state.item_templates:
			var r_type: Rarity.Type = template.rarity.rarity_type
			if r_type != Rarity.Type.UNIQUE:
				matching.append(template)
				
	if matching.is_empty():
		return null
		
	return matching[randi() % matching.size()]

static func roll_single_shop_card(p_run_state: RunState, slot_idx: int) -> Resource:
	var rolled_rarity: Rarity.Type = p_run_state.roll_rarity()
	if p_run_state.unique_chance > 0.0 and randf() < p_run_state.unique_chance:
		rolled_rarity = Rarity.Type.UNIQUE
		
	var spawn_item: bool = false
	var last_slot_idx: int = p_run_state.shop_cards.size() - 1
	if slot_idx == last_slot_idx and p_run_state.item_purchase_count < p_run_state.item_purchase_limit:
		if not p_run_state.item_templates.is_empty():
			spawn_item = true
		
	var rolled_card: Resource = null
	if spawn_item:
		var template: ItemData = get_random_item_template_by_rarity(p_run_state, rolled_rarity)
		if template:
			var instance: ItemInstance = ItemInstance.new()
			instance.initialize(template)
			rolled_card = instance
	else:
		if p_run_state.unit_templates.is_empty():
			return null
			
		var template: UnitData = get_random_unit_template_by_rarity(p_run_state, rolled_rarity)
		if template:
			var instance: UnitInstance = UnitInstance.new()
			instance.initialize(template)
			rolled_card = instance
			
	if rolled_card:
		p_run_state.notify_shop_card_generated(rolled_card)
		
	return rolled_card

static func buy_unit(p_run_state: RunState, shop_slot_idx: int, target_idx: int, target_is_active: bool) -> bool:
	if shop_slot_idx < 0 or shop_slot_idx >= p_run_state.shop_cards.size():
		return false
		
	var item_or_unit: Resource = p_run_state.shop_cards[shop_slot_idx]
	if not (item_or_unit is UnitInstance):
		return false
		
	var unit: UnitInstance = item_or_unit as UnitInstance
	var cost: int = unit.data.price if unit.data else 3
	if p_run_state.gold < cost:
		return false
		
	var target_array: Array[UnitInstance] = p_run_state.active_team if target_is_active else p_run_state.bench
	if target_idx < 0 or target_idx >= target_array.size():
		return false
		
	if target_array[target_idx] != null:
		return false # Slot is occupied
		
	# Execute purchase
	p_run_state.gold -= cost
	target_array[target_idx] = unit
	
	# Refill shop slot immediately
	p_run_state.shop_cards[shop_slot_idx] = roll_single_shop_card(p_run_state, shop_slot_idx)
	p_run_state.shop_frozen_statuses[shop_slot_idx] = false
	
	# Emit updates
	p_run_state.notify_shop_slot_updated(shop_slot_idx, p_run_state.shop_cards[shop_slot_idx])
	p_run_state.notify_shop_slot_freeze_changed(shop_slot_idx, false)
	
	return true

static func apply_item(p_run_state: RunState, shop_slot_idx: int, target_idx: int, target_is_active: bool) -> bool:
	if shop_slot_idx < 0 or shop_slot_idx >= p_run_state.shop_cards.size():
		return false
		
	var item_or_unit: Resource = p_run_state.shop_cards[shop_slot_idx]
	if not (item_or_unit is ItemInstance):
		return false
		
	var item: ItemInstance = item_or_unit as ItemInstance
	var cost: int = item.data.price if item.data else 2
	if p_run_state.gold < cost:
		return false
		
	var target_array: Array[UnitInstance] = p_run_state.active_team if target_is_active else p_run_state.bench
	if target_idx < 0 or target_idx >= target_array.size():
		return false
		
	var target_unit: UnitInstance = target_array[target_idx]
	if target_unit == null:
		return false # No unit to feed
		
	# Apply effect
	if item.data and item.data.modifier:
		item.data.modifier.apply_unit_effect(target_unit)
		
	# Execute purchase
	p_run_state.gold -= cost
	p_run_state.item_purchase_count += 1
	
	# Refill shop slot immediately
	p_run_state.shop_cards[shop_slot_idx] = null
	p_run_state.shop_cards[shop_slot_idx] = roll_single_shop_card(p_run_state, shop_slot_idx)
	p_run_state.shop_frozen_statuses[shop_slot_idx] = false
	
	# Emit updates
	p_run_state.notify_shop_slot_updated(shop_slot_idx, p_run_state.shop_cards[shop_slot_idx])
	p_run_state.notify_shop_slot_freeze_changed(shop_slot_idx, false)
	
	return true

static func buy_clickable_item(p_run_state: RunState, shop_slot_idx: int) -> bool:
	if shop_slot_idx < 0 or shop_slot_idx >= p_run_state.shop_cards.size():
		return false
		
	var item_or_unit: Resource = p_run_state.shop_cards[shop_slot_idx]
	if not (item_or_unit is ItemInstance):
		return false
		
	var item: ItemInstance = item_or_unit as ItemInstance
	var cost: int = item.data.price if item.data else 2
	if p_run_state.gold < cost:
		return false
		
	# Apply effect
	if item.data and item.data.modifier:
		item.data.modifier.apply_shop_effect(p_run_state)
		
	# Execute purchase
	p_run_state.gold -= cost
	p_run_state.item_purchase_count += 1
	
	# Refill shop slot immediately
	p_run_state.shop_cards[shop_slot_idx] = null
	p_run_state.shop_cards[shop_slot_idx] = roll_single_shop_card(p_run_state, shop_slot_idx)
	p_run_state.shop_frozen_statuses[shop_slot_idx] = false
	
	# Emit updates
	p_run_state.notify_shop_slot_updated(shop_slot_idx, p_run_state.shop_cards[shop_slot_idx])
	p_run_state.notify_shop_slot_freeze_changed(shop_slot_idx, false)
	
	return true

static func toggle_freeze_shop_slot(p_run_state: RunState, slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= p_run_state.shop_frozen_statuses.size():
		return
	var next_status: bool = not p_run_state.shop_frozen_statuses[slot_idx]
	p_run_state.shop_frozen_statuses[slot_idx] = next_status
	p_run_state.notify_shop_slot_freeze_changed(slot_idx, next_status)

static func is_shop_frozen(p_run_state: RunState) -> bool:
	return not p_run_state.shop_frozen_statuses.has(false)

static func request_shop_roll(p_run_state: RunState) -> void:
	if is_shop_frozen(p_run_state):
		return

	if p_run_state.gold < 1:
		return
	p_run_state.gold -= 1
	roll_shop(p_run_state)

static func roll_shop(p_run_state: RunState) -> void:
	p_run_state.notify_shop_rolled()
		
	for i: int in range(p_run_state.shop_cards.size()):
		if not p_run_state.shop_frozen_statuses[i]:
			p_run_state.shop_cards[i] = roll_single_shop_card(p_run_state, i)
			p_run_state.notify_shop_slot_updated(i, p_run_state.shop_cards[i])

static func change_shop_size(p_run_state: RunState, p_diff: int) -> void:
	if p_diff == 0:
		return
		
	var new_size: int = clampi(p_run_state.shop_cards.size() + p_diff, 1, 10)
	var old_size: int = p_run_state.shop_cards.size()
	if new_size == old_size:
		return

	# Add slot to the first
	if new_size > old_size:
		var diff: int = new_size - old_size
		var new_cards: Array[Resource] = []
		var new_frozen: Array[bool] = []
		new_cards.resize(new_size)
		new_frozen.resize(new_size)
		
		for i: int in range(old_size):
			new_cards[i + diff] = p_run_state.shop_cards[i]
			new_frozen[i + diff] = p_run_state.shop_frozen_statuses[i]
			
		for i: int in range(diff):
			new_cards[i] = null
			new_frozen[i] = false
			
		p_run_state.shop_cards = new_cards
		p_run_state.shop_frozen_statuses = new_frozen
		
		for i: int in range(diff):
			p_run_state.shop_cards[i] = roll_single_shop_card(p_run_state, i)
	else:
		p_run_state.shop_cards.resize(new_size)
		p_run_state.shop_frozen_statuses.resize(new_size)
			
	p_run_state.notify_shop_size_changed(new_size)

static func handle_unit_evolution(p_run_state: RunState, p_old_data: UnitData, p_new_data: UnitData) -> void:
	if p_old_data:
		for t: UnitData in p_run_state.unit_templates:
			if t.display_name == p_old_data.display_name:
				t.can_appear_in_shop = false
				break
				
	if p_new_data:
		for t: UnitData in p_run_state.unit_templates:
			if t.display_name == p_new_data.display_name:
				t.can_appear_in_shop = true
				break
				
	reroll_slots_with_unit_data(p_run_state, p_old_data)

static func reroll_slots_with_unit_data(p_run_state: RunState, p_old_data: UnitData) -> void:
	for i: int in range(p_run_state.shop_cards.size()):
		if p_run_state.shop_cards[i] is not UnitInstance:
			continue
			
		var card: UnitInstance = p_run_state.shop_cards[i]
		if card.data.display_name == p_old_data.display_name:
			p_run_state.shop_cards[i] = roll_single_shop_card(p_run_state, i)
			p_run_state.notify_shop_slot_updated(i, p_run_state.shop_cards[i])
