class_name ShopMergeAnimator
extends Object

## Animates three matching cards merging into a higher tier card in the center.
static func animate_merge(shop: ShopScene, merge: Dictionary, callback: Callable, new_unit_instance: UnitInstance = null) -> void:
	var main_info: Dictionary = merge.get("main", {})
	var removed_list: Array = merge.get("removed", [])
	
	if main_info.is_empty():
		callback.call()
		return
		
	var main_is_bench: bool = main_info.get("is_bench", false)
	var main_idx: int = main_info.get("idx", 0)
	
	# Get main slot and main card from shop
	var main_slot: UnitSlot = shop.bench_slots[main_idx] if main_is_bench else shop.active_slots[main_idx]
	var main_card: UnitCard = main_slot.get_card() as UnitCard
	
	if main_card == null:
		shop.populate_ui()
		callback.call()
		return
		
	# 1. Create full-screen dimming overlay blocking mouse inputs
	var dim_rect: ColorRect = ColorRect.new()
	dim_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	dim_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.z_index = 998
	shop.add_child(dim_rect)
	
	var dim_tween: Tween = shop.create_tween()
	dim_tween.tween_property(dim_rect, "color", Color(0.0, 0.0, 0.0, 0.6), 0.3)
	
	# 2. Get the two removed cards and their starting details
	var animating_removed: Array[Dictionary] = []
	for rem_val: Variant in removed_list:
		if not (rem_val is Dictionary):
			continue
		var rem: Dictionary = rem_val
		var rem_is_bench: bool = rem.get("is_bench", false)
		var rem_idx: int = rem.get("idx", 0)
		var rem_slot: UnitSlot = shop.bench_slots[rem_idx] if rem_is_bench else shop.active_slots[rem_idx]
		
		var rem_card: UnitCard = rem_slot.get_card() as UnitCard
		if rem_card:
			# Use the slot's CardContainer global position if layout hasn't run yet
			var start_pos: Vector2 = rem_card.global_position
			var rem_container: Node = rem_slot.get_node_or_null("CardContainer")
			start_pos = (rem_container as Control).global_position
				
			var card_size: Vector2 = rem_card.size
			if card_size == Vector2.ZERO:
				card_size = rem_card.custom_minimum_size
			if card_size == Vector2.ZERO:
				card_size = CardUIHelper.CARD_SIZE
				
			rem_slot.remove_card(rem_card)
			animating_removed.append({
				"card": rem_card,
				"start_pos": start_pos,
				"size": card_size
			})
			
	# Cache main card details and resting/target positions before detaching
	var main_start_pos: Vector2 = main_card.global_position
	var main_container: Node = main_slot.get_node_or_null("CardContainer")
	if main_container and main_container is Control:
		main_start_pos = (main_container as Control).global_position
	var main_size: Vector2 = main_card.size
	if main_size == Vector2.ZERO:
		main_size = main_card.custom_minimum_size
	if main_size == Vector2.ZERO:
		main_size = CardUIHelper.CARD_SIZE
		
	# Lock custom_minimum_size to preserve the exact starting dimensions
	main_card.custom_minimum_size = main_size
	main_card.size = main_size
		
	# Since the card starts in main_slot and returns to main_slot,
	# target position is identical to the exact starting global position.
	var main_slot_target_pos: Vector2 = main_start_pos
	
	main_slot.remove_card(main_card)
		
	# Add all 3 cards as overlay child nodes
	shop.add_child(main_card)
	main_card.global_position = main_start_pos
	main_card.z_index = 999
	main_card.pivot_offset = main_size / 2.0
	main_card.rotation = 0.0
	main_card.scale = Vector2(1.0, 1.0)
	
	var overlay_removed: Array[Dictionary] = []
	for info_val: Variant in animating_removed:
		if not (info_val is Dictionary):
			continue
		var info: Dictionary = info_val
		var card: UnitCard = info.get("card")
		var start_pos: Vector2 = info.get("start_pos", Vector2.ZERO)
		var card_size: Vector2 = info.get("size", Vector2.ZERO)
		
		shop.add_child(card)
		card.global_position = start_pos
		card.z_index = 999
		card.pivot_offset = card_size / 2.0
		card.rotation = 0.0
		card.scale = Vector2(1.0, 1.0)
		card.update_ui()
		
		overlay_removed.append({
			"card": card,
			"start_pos": start_pos,
			"size": card_size
		})
		
	# 3. Calculate Center Position and Triangle Points
	var screen_center: Vector2 = shop.size / 2.0
	var center_main_pos: Vector2 = screen_center - main_size / 2.0
	
	# Assign points to our 3 cards
	var all_animating: Array[Dictionary] = []
	all_animating.append({
		"card": main_card,
		"start_pos": main_start_pos,
		"target_rotation": 0,
		"size": main_size
	})
	
	for i: int in range(overlay_removed.size()):
		var info: Dictionary = overlay_removed[i]
		var rot: float = 0.2
		var info_card: UnitCard = info.get("card")
		var info_start_pos: Vector2 = info.get("start_pos", Vector2.ZERO)
		var info_card_size: Vector2 = info.get("size", Vector2.ZERO)
		
		all_animating.append({
			"card": info_card,
			"start_pos": info_start_pos,
			"target_rotation": rot,
			"size": info_card_size
		})
		
	# --- PHASE 1: Pull to Center ---
	var p1_tween: Tween = shop.create_tween().set_parallel(true)
	for item_val: Variant in all_animating:
		var item: Dictionary = item_val
		var card: UnitCard = item.get("card")
		var target_rot: float = item.get("target_rotation", 0.0)
		
		p1_tween.tween_property(card, "global_position", center_main_pos, 0.45)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
		p1_tween.tween_property(card, "rotation", target_rot, 0.45)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_OUT)
			
	# --- PHASE 2: Spin and Merge to Center ---
	var merge_tween: Tween = p1_tween.chain().set_parallel(true)
	merge_tween.tween_property(main_card, "scale", Vector2(1.35, 1.35), 0.35)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN_OUT)
	merge_tween.tween_property(main_card, "rotation", 0, 0.35)
	
	# Tween the removed cards to center, rotating, fading out and shrinking to zero
	for i: int in range(overlay_removed.size()):
		var info: Dictionary = overlay_removed[i]
		var card: UnitCard = info["card"]
		var final_pos: Vector2 = screen_center
		
		merge_tween.tween_property(card, "global_position", final_pos, 0.35)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN)
		merge_tween.tween_property(card, "scale", Vector2.ZERO, 0.35)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN)
		merge_tween.tween_property(card, "rotation", 3.14159, 0.35)\
			.set_trans(Tween.TRANS_QUAD)\
			.set_ease(Tween.EASE_IN)
		merge_tween.tween_property(card, "modulate:a", 0.0, 0.35)
		
	# Callback to clean up removed cards and reveal updated main card immediately in center
	var clean_chain: Tween = merge_tween.chain()
	clean_chain.tween_callback(func() -> void:
		for info_clean: Dictionary in overlay_removed:
			var card_clean: UnitCard = info_clean.get("card")
			if card_clean:
				card_clean.queue_free()
		
		if is_instance_valid(main_card):
			if new_unit_instance:
				main_card.unit_instance = new_unit_instance
			main_card.update_ui()
			var pop_tween: Tween = shop.create_tween()
			pop_tween.tween_property(main_card, "scale", Vector2(1.5, 1.5), 0.1)\
				.set_trans(Tween.TRANS_BACK)\
				.set_ease(Tween.EASE_OUT)
			pop_tween.tween_property(main_card, "scale", Vector2(1.35, 1.35), 0.15)\
				.set_trans(Tween.TRANS_QUAD)\
				.set_ease(Tween.EASE_IN_OUT)
	)

	# 0.5s Timer
	clean_chain.finished.connect(func() -> void:
		var timer: SceneTreeTimer = shop.get_tree().create_timer(0.5)
		timer.timeout.connect(func() -> void:
			if not is_instance_valid(main_card) or not is_instance_valid(main_slot):
				dim_rect.queue_free()
				callback.call()
				return
				
			# --- PHASE 3: Fly Back to Slot ---
			var fly_back_tween: Tween = shop.create_tween().set_parallel(true)
			fly_back_tween.tween_property(main_card, "global_position", main_slot_target_pos, 0.5)\
				.set_trans(Tween.TRANS_QUAD)\
				.set_ease(Tween.EASE_IN_OUT)
			fly_back_tween.tween_property(main_card, "scale", Vector2(1.0, 1.0), 0.5)\
				.set_trans(Tween.TRANS_QUAD)\
				.set_ease(Tween.EASE_IN_OUT)
				
			# Fade out dim overlay
			fly_back_tween.tween_property(dim_rect, "color", Color(0.0, 0.0, 0.0, 0.0), 0.5)
			
			fly_back_tween.finished.connect(func() -> void:
				if not is_instance_valid(main_card) or not is_instance_valid(main_slot):
					dim_rect.queue_free()
					callback.call()
					return
					
				var parent: Node = main_card.get_parent()
				if parent:
					parent.remove_child(main_card)
				
				# Reset card transformations and minimum size
				main_card.scale = Vector2.ONE
				main_card.rotation = 0.0
				main_card.pivot_offset = Vector2.ZERO
				main_card.custom_minimum_size = CardUIHelper.CARD_SIZE
				main_card.z_index = 0
		
				# Re-add card to slot before update_ui so it is inside the scene tree
				main_slot.add_card(main_card)	
				main_card.update_ui()
				main_slot.update_placeholder()
				
				dim_rect.queue_free()
				
				# Invoke the callback to trigger next pending fusions
				callback.call()
			)
		)
	)
