class_name ShopMergeAnimator
extends Object

## Animates matching cards merging into a higher tier card in the center.
static func animate_merge(shop: ShopScene, merge: Dictionary, callback: Callable, new_unit_instance: UnitInstance = null) -> void:
	var main_info: Dictionary = merge.get("main", {})
	var removed_list: Array = merge.get("removed", [])
	
	if main_info.is_empty():
		callback.call()
		return
		
	var main_is_bench: bool = main_info.get("is_bench", false)
	var main_idx: int = main_info.get("idx", 0)
	
	var main_slot: UnitSlot = shop.bench_slots[main_idx] if main_is_bench else shop.active_slots[main_idx]
	var main_card: UnitCard = main_slot.get_card() as UnitCard
	
	if main_card == null:
		shop.populate_ui()
		callback.call()
		return

	# 1. Full-screen dimming overlay
	var dim_rect: ColorRect = ColorRect.new()
	dim_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	dim_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.z_index = 998
	shop.add_child(dim_rect)
	
	var dim_tween: Tween = shop.create_tween()
	dim_tween.tween_property(dim_rect, "color", Color(0.0, 0.0, 0.0, 0.6), 0.3)

	# 2. Collect removed cards onto overlay
	var removed_cards: Array[UnitCard] = []
	for rem_val: Variant in removed_list:
		if not (rem_val is Dictionary):
			continue
		var rem: Dictionary = rem_val
		var rem_is_bench: bool = rem.get("is_bench", false)
		var rem_idx: int = rem.get("idx", 0)
		var rem_slot: UnitSlot = shop.bench_slots[rem_idx] if rem_is_bench else shop.active_slots[rem_idx]
		
		var rem_card: UnitCard = rem_slot.get_card() as UnitCard
		if rem_card:
			var start_pos: Vector2 = rem_card.global_position
			var rem_container: Node = rem_slot.get_node_or_null("CardContainer")
			if rem_container and rem_container is Control:
				start_pos = (rem_container as Control).global_position
				
			rem_slot.remove_card(rem_card)
			shop.add_child(rem_card)
			rem_card.global_position = start_pos
			rem_card.z_index = 999
			rem_card.pivot_offset = CardUIHelper.CARD_SIZE / 2.0
			rem_card.rotation = 0.0
			rem_card.scale = Vector2.ONE
			rem_card.update_ui()
			removed_cards.append(rem_card)

	# 3. Setup main card on overlay
	var main_start_pos: Vector2 = main_card.global_position
	var main_container: Node = main_slot.get_node_or_null("CardContainer")
	if main_container and main_container is Control:
		main_start_pos = (main_container as Control).global_position
		
	var main_size: Vector2 = CardUIHelper.CARD_SIZE
	main_card.custom_minimum_size = main_size
	main_card.size = main_size
	main_slot.remove_card(main_card)

	shop.add_child(main_card)
	main_card.global_position = main_start_pos
	main_card.z_index = 999
	main_card.pivot_offset = main_size / 2.0
	main_card.rotation = 0.0
	main_card.scale = Vector2.ONE

	var screen_center: Vector2 = shop.size / 2.0
	var center_main_pos: Vector2 = screen_center - main_size / 2.0

	# --- PHASE 1: Fly to center and merge ---
	var tween_in: Tween = shop.create_tween().set_parallel(true)
	tween_in.tween_property(main_card, "global_position", center_main_pos, 0.4)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(main_card, "scale", Vector2(1.35, 1.35), 0.4)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	for card: UnitCard in removed_cards:
		tween_in.tween_property(card, "global_position", screen_center, 0.4)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween_in.tween_property(card, "scale", Vector2.ZERO, 0.4)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween_in.tween_property(card, "rotation", 3.14159, 0.4)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween_in.tween_property(card, "modulate:a", 0.0, 0.4)

	await tween_in.finished

	# Remove absorbed cards
	for card: UnitCard in removed_cards:
		card.queue_free()

	# --- PHASE 2: Impact / Pop effect in center and replace unit instance ---
	if is_instance_valid(main_card):
		if new_unit_instance:
			main_card.unit_instance = new_unit_instance
		main_card.update_ui()
		var pop_tween: Tween = shop.create_tween()
		pop_tween.tween_property(main_card, "scale", Vector2(1.5, 1.5), 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(main_card, "scale", Vector2(1.35, 1.35), 0.2)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await pop_tween.finished

	# Short pause
	await shop.get_tree().create_timer(0.3).timeout

	if not is_instance_valid(main_card) or not is_instance_valid(main_slot):
		dim_rect.queue_free()
		callback.call()
		return

	# --- PHASE 3: Fly back to slot ---
	var tween_out: Tween = shop.create_tween().set_parallel(true)
	tween_out.tween_property(main_card, "global_position", main_start_pos, 0.4)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween_out.tween_property(main_card, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween_out.tween_property(dim_rect, "color", Color(0.0, 0.0, 0.0, 0.0), 0.4)

	await tween_out.finished

	if is_instance_valid(main_card) and is_instance_valid(main_slot):
		var parent: Node = main_card.get_parent()
		if parent:
			parent.remove_child(main_card)

		main_card.scale = Vector2.ONE
		main_card.rotation = 0.0
		main_card.pivot_offset = Vector2.ZERO
		main_card.custom_minimum_size = CardUIHelper.CARD_SIZE
		main_card.z_index = 0

		main_slot.add_card(main_card)
		main_card.update_ui()
		main_slot.update_placeholder()

	dim_rect.queue_free()
	callback.call()
