class_name MonsterSlot
extends Control

## Signal emitted when the card inside this slot changes (added, removed, swapped)
signal slot_changed(slot: MonsterSlot)

## If true, this slot is part of the active combat team. If false, it is on the bench.
@export var is_active_team: bool = false

## Index of the slot in the respective team/bench array
@export var slot_index: int = 0

@export var is_shop_slot: bool = false
@export var price: int = 3:
	set(val):
		price = val
		if has_node("%PriceLabel"):
			%PriceLabel.text = str(price) + "g"
var is_frozen: bool = false

var is_highlighted: bool = false

func _ready() -> void:
	# Remove Godot's default panel borders from CardContainer
	var empty_style = StyleBoxEmpty.new()
	$CardContainer.add_theme_stylebox_override("panel", empty_style)
	
	# Create and add a ColorRect to draw our custom pixel-perfect slot borders via shader
	var border_rect = ColorRect.new()
	border_rect.name = "BorderRect"
	border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Full rect layout
	border_rect.layout_mode = 1
	border_rect.anchors_preset = Control.PRESET_FULL_RECT
	border_rect.offset_left = 0
	border_rect.offset_top = 0
	border_rect.offset_right = 0
	border_rect.offset_bottom = 0
	
	# Load and assign the shader material
	var shader = load("res://src/shared/shaders/double_border.gdshader")
	var shader_material: ShaderMaterial = ShaderMaterial.new()
	shader_material.shader = shader
	
	# Colors matching the reference image:
	shader_material.set_shader_parameter("outer_border_width", 3)
	shader_material.set_shader_parameter("inner_border_width", 3)
	shader_material.set_shader_parameter("outer_border_color", GameColors.BORDER_OUTER_DEFAULT)
	shader_material.set_shader_parameter("inner_border_color", GameColors.BORDER_INNER_DEFAULT)
	shader_material.set_shader_parameter("corner_color", GameColors.TRANSPARENT)
	
	border_rect.material = shader_material
	
	# Support dynamic resizing for scaling/monitors - connect before add_child to ensure we capture initial layout resizing
	border_rect.resized.connect(func():
		if border_rect.material:
			border_rect.material.set_shader_parameter("size", border_rect.size)
	)
	
	$CardContainer.add_child(border_rect)
	$CardContainer.move_child(border_rect, 0) # Make sure it is drawn behind other elements (like the card)
	
	# Set size uniform to match our actual size or fallback to custom minimum size
	if border_rect.material:
		var initial_size = border_rect.size if border_rect.size != Vector2.ZERO else $CardContainer.custom_minimum_size
		border_rect.material.set_shader_parameter("size", initial_size)
	
	# Connect tree notifications to toggle placeholder visibility and border visibility
	$CardContainer.child_entered_tree.connect(func(_node): update_placeholder.call_deferred())
	$CardContainer.child_exiting_tree.connect(func(_node): update_placeholder.call_deferred())
	
	# Load and assign the health bar shader material
	var hp_shader = load("res://src/shared/shaders/hp_border.gdshader")
	var hp_material = ShaderMaterial.new()
	hp_material.shader = hp_shader
	hp_material.set_shader_parameter("fill_percentage", 1.0)
	%HealthBarRect.material = hp_material
	
	%HealthBarRect.resized.connect(func():
		if %HealthBarRect.material:
			%HealthBarRect.material.set_shader_parameter("size", %HealthBarRect.size)
	)
	
	# Set initial size uniform to actual size or fallback to custom minimum size
	if %HealthBarRect.material:
		var initial_hp_size = %HealthBarRect.size
		if initial_hp_size.x == 0.0:
			initial_hp_size = Vector2(84, 20)
		%HealthBarRect.material.set_shader_parameter("size", initial_hp_size)
	
	update_placeholder()
	
	# Setup Shop Controls
	if is_shop_slot:
		custom_minimum_size.y = 160
		if has_node("%ShopControls"):
			%ShopControls.visible = true
			%PriceLabel.text = str(price) + "g"
			%FreezeButton.toggled.connect(func(pressed: bool):
				is_frozen = pressed
				_update_freeze_button_style()
			)
			_update_freeze_button_style()
	else:
		if has_node("%ShopControls"):
			%ShopControls.visible = false
		custom_minimum_size.y = 135

func _update_freeze_button_style() -> void:
	if not has_node("%FreezeButton"):
		return
	var btn = %FreezeButton as Button
	if is_frozen:
		btn.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0)) # Ice blue
		btn.text = "❄"
	else:
		btn.remove_theme_color_override("font_color")
		btn.text = "❄"

func update_style(is_hovered: bool = false) -> void:
	is_highlighted = is_hovered
	var border_rect = $CardContainer.get_node_or_null("BorderRect")
	if not border_rect or not border_rect.material:
		return
		
	var mat = border_rect.material as ShaderMaterial
	if is_hovered:
		mat.set_shader_parameter("outer_border_color", GameColors.SLOT_HOVER_OUTER_BORDER) # blue border
		mat.set_shader_parameter("inner_border_color", GameColors.SLOT_HOVER_INNER_BORDER) # light gray inner border
	else:
		mat.set_shader_parameter("outer_border_color", GameColors.BORDER_OUTER_DEFAULT) # gray-blue border
		mat.set_shader_parameter("inner_border_color", GameColors.BORDER_INNER_DEFAULT) # light gray inner border

func update_placeholder() -> void:
	var empty = is_empty()
	if $CardContainer.has_node("EmptyPlaceholderLabel"):
		$CardContainer.get_node("EmptyPlaceholderLabel").visible = empty
		
	var border_rect = $CardContainer.get_node_or_null("BorderRect")
	if border_rect:
		border_rect.visible = empty
		
	update_style()
	update_health_bar()

func update_health_bar() -> void:
	var card = get_card()
	if card and "monster_instance" in card and card.monster_instance:
		%HealthBarContainer.visible = true
		var inst = card.monster_instance
		var fill = float(inst.current_health) / float(inst.get_max_health())
		var mat = %HealthBarRect.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("fill_percentage", fill)
			var current_hp_size = %HealthBarRect.size
			if current_hp_size.x == 0.0:
				current_hp_size = Vector2(84, 20)
			mat.set_shader_parameter("size", current_hp_size)
		%HealthLabel.text = str(inst.current_health)
	else:
		%HealthBarContainer.visible = false

func _process(_delta: float) -> void:
	if is_highlighted and get_viewport().gui_is_dragging():
		var mouse_pos = $CardContainer.get_local_mouse_position()
		var rect = Rect2(Vector2.ZERO, $CardContainer.size)
		if not rect.has_point(mouse_pos):
			update_style(false)

# Determine if we can drop a dragged item onto this slot
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if is_shop_slot:
		return false # Cannot drop cards into shop slots!
		
	if typeof(data) == TYPE_DICTIONARY and data.has("card"):
		var dragged_card = data["card"]
		var original_slot = data["original_slot"] as MonsterSlot
		
		# Check if the player has enough gold for a purchase
		if original_slot and original_slot.is_shop_slot:
			var shop_scene = get_tree().current_scene
			if shop_scene and shop_scene.has_method("get_gold"):
				if shop_scene.get_gold() < original_slot.price:
					return false # Cannot afford this card
		
		# If the dragged card is food:
		if dragged_card.has_method("apply_food_effect"):
			# Food can ONLY be dropped onto an occupied monster slot to consume it
			var target_card = get_card()
			if target_card and "monster_instance" in target_card:
				update_style(true)
				return true
			return false
		else:
			# Normal monster card
			update_style(true)
			return true
	return false

# Handle cleanup when drag drops elsewhere, leaves the slot, or is canceled
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		# Restore proper style based on slot occupancy
		update_style(false)

# Handle drop execution
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	update_style(false)
	
	var dragged_card = data["card"]
	var original_slot: MonsterSlot = data["original_slot"]
	

		
	if original_slot == self:
		add_card(dragged_card)
		slot_changed.emit(self)
		return
		
	var current_card = get_card()
	
	# 1. If dragged card is food:
	if dragged_card.has_method("apply_food_effect"):
		if current_card and "monster_instance" in current_card:
			# Apply food stats directly to monster in this slot
			dragged_card.apply_food_effect(current_card)
			current_card.update_ui()
			update_health_bar()
			
			# Deduct gold if purchased
			if original_slot and original_slot.is_shop_slot:
				var shop_scene = get_tree().current_scene
				if shop_scene and shop_scene.has_method("deduct_gold"):
					shop_scene.deduct_gold(original_slot.price)
					if shop_scene.has_method("refill_shop_slot"):
						shop_scene.refill_shop_slot(original_slot.slot_index)
			
			# Consume food item
			dragged_card.queue_free()
			
			slot_changed.emit(self)
			if original_slot:
				original_slot.slot_changed.emit(original_slot)
			return
			
	# 2. Normal monster card move/swap:
	if current_card:
		# SWAP logic: Swap the parent slots of the two cards
		remove_card(current_card)
		add_card(dragged_card)
		original_slot.add_card(current_card)
	else:
		# MOVE logic: Move card from original slot to this empty slot
		add_card(dragged_card)
		
	# Deduct gold if purchased from the shop
	if original_slot and original_slot.is_shop_slot:
		var shop_scene = get_tree().current_scene
		if shop_scene and shop_scene.has_method("deduct_gold"):
			shop_scene.deduct_gold(original_slot.price)
			if shop_scene.has_method("refill_shop_slot"):
				shop_scene.refill_shop_slot(original_slot.slot_index)
			
	# Emit signals
	slot_changed.emit(self)
	original_slot.slot_changed.emit(original_slot)

func add_card(card: Control) -> void:
	if has_node("CardContainer"):
		$CardContainer.add_child(card)
		if is_shop_slot and "price" in card:
			price = card.price

func remove_card(card: Control) -> void:
	if has_node("CardContainer"):
		$CardContainer.remove_child(card)

## Returns the MonsterCard child node of this slot, if any. Otherwise returns null.
func get_card() -> Control:
	if not has_node("CardContainer"):
		return null
	for child in $CardContainer.get_children():
		if child.has_method("update_ui"):
			return child
	return null

## Check if slot is empty
func is_empty() -> bool:
	return get_card() == null

## Returns the MonsterInstance from the card in this slot, or null
func get_monster_instance() -> MonsterInstance:
	var card = get_card()
	if card and "monster_instance" in card:
		return card.monster_instance
	return null
