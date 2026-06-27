class_name ShopCardSlot
extends Control

## Signal emitted when the card inside this slot changes (added, removed, swapped)
signal slot_changed(slot: ShopCardSlot)

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
var is_targeted: bool = false

@export var drag_drop_enabled: bool = true

# Dependency Injection callbacks to avoid tight coupling to ShopScene
var gold_provider: Callable
var gold_deductor: Callable
var shop_refiller: Callable

@onready var card_container: Control = $CardContainer

func _ready() -> void:
	# Connect tree notifications to toggle placeholder visibility and border visibility
	card_container.child_entered_tree.connect(func(_node: Node) -> void: update_placeholder.call_deferred())
	card_container.child_exiting_tree.connect(func(_node: Node) -> void: update_placeholder.call_deferred())
	
	# Load and assign the health bar shader material
	var hp_shader: Shader = load("res://src/shared/shaders/hp_border.gdshader") as Shader
	var hp_material: ShaderMaterial = ShaderMaterial.new()
	hp_material.shader = hp_shader
	hp_material.set_shader_parameter("fill_percentage", 1.0)
	%HealthBarRect.material = hp_material
	
	%HealthBarRect.resized.connect(func() -> void:
		if %HealthBarRect.material:
			%HealthBarRect.material.set_shader_parameter("size", %HealthBarRect.size)
	)
	
	# Set initial size uniform to actual size or fallback to custom minimum size
	if %HealthBarRect.material:
		var initial_hp_size: Vector2 = %HealthBarRect.size
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
	var btn: Button = %FreezeButton as Button
	if is_frozen:
		btn.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0)) # Ice blue
		btn.text = "❄"
	else:
		btn.remove_theme_color_override("font_color")
		btn.text = "❄"

func update_style(is_hovered: bool = false) -> void:
	is_highlighted = is_hovered
	var card: Control = get_card()
	if card:
		if card.has_method("set_highlight"):
			card.call("set_highlight", is_hovered)
		if card.has_method("set_target_highlight"):
			card.call("set_target_highlight", is_targeted)
		
	var border_rect: ShaderBorderDecorator = card_container.get_node_or_null("BorderRect") as ShaderBorderDecorator
	if not border_rect:
		return
		
	if is_hovered:
		border_rect.border_color = GameColors.SLOT_HOVER_OUTER_BORDER
		border_rect.inner_border_color = GameColors.SLOT_HOVER_INNER_BORDER
	elif is_targeted:
		border_rect.border_color = Color(0.9, 0.15, 0.15, 1.0)
		border_rect.inner_border_color = Color(0.5, 0.05, 0.05, 1.0)
	else:
		border_rect.border_color = GameColors.BORDER_OUTER_DEFAULT
		border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
	border_rect.update_shader_parameters()

func set_target_highlight(active: bool) -> void:
	is_targeted = active
	update_style(is_highlighted)

func update_placeholder() -> void:
	var empty: bool = is_empty()
	if card_container.has_node("EmptyPlaceholderLabel"):
		card_container.get_node("EmptyPlaceholderLabel").visible = empty
		
	var border_rect: ShaderBorderDecorator = card_container.get_node_or_null("BorderRect") as ShaderBorderDecorator
	if border_rect:
		border_rect.visible = empty
		
	update_style()
	update_health_bar()

func update_health_bar() -> void:
	# HP bar is disabled in the shop scene to keep card visuals clean.
	%HealthBarContainer.visible = false

func _process(_delta: float) -> void:
	if is_highlighted and get_viewport().gui_is_dragging():
		var mouse_pos: Vector2 = card_container.get_local_mouse_position()
		var rect: Rect2 = Rect2(Vector2.ZERO, card_container.size)
		if not rect.has_point(mouse_pos):
			update_style(false)

# Determine if we can drop a dragged item onto this slot
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not drag_drop_enabled:
		return false
		
	if is_shop_slot:
		return false # Cannot drop cards into shop slots!
		
	if typeof(data) == TYPE_DICTIONARY and data.has("card"):
		var dragged_card: Control = data["card"] as Control
		var original_slot: ShopCardSlot = data["original_slot"] as ShopCardSlot
		
		# Check if the player has enough gold for a purchase
		if original_slot and original_slot.is_shop_slot:
			if gold_provider.is_valid():
				var current_gold: int = gold_provider.call() as int
				if current_gold < original_slot.price:
					return false # Cannot afford this card
		
		# If the dragged card is food:
		if dragged_card.has_method("apply_food_effect"):
			# Food can ONLY be dropped onto an occupied unit slot to consume it
			var target_card: Control = get_card()
			if target_card and "unit_instance" in target_card:
				update_style(true)
				return true
			return false
		else:
			# Normal unit card
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
	
	var dragged_card: Control = data["card"] as Control
	var original_slot: ShopCardSlot = data["original_slot"] as ShopCardSlot
	
	if original_slot == self:
		add_card(dragged_card)
		slot_changed.emit(self)
		return
		
	var current_card: Control = get_card()
	
	# 1. If dragged card is food:
	if dragged_card.has_method("apply_food_effect"):
		if current_card and "unit_instance" in current_card:
			# Apply food stats directly to unit in this slot
			dragged_card.apply_food_effect(current_card)
			current_card.update_ui()
			update_health_bar()
			
			# Deduct gold if purchased
			if original_slot and original_slot.is_shop_slot:
				if gold_deductor.is_valid():
					gold_deductor.call(original_slot.price)
				if shop_refiller.is_valid():
					shop_refiller.call(original_slot.slot_index)
			
			# Consume food item
			if dragged_card.get_parent() != null:
				dragged_card.get_parent().remove_child(dragged_card)
			if not dragged_card.is_queued_for_deletion():
				dragged_card.queue_free()
			
			slot_changed.emit(self)
			if original_slot:
				original_slot.slot_changed.emit(original_slot)
			return
			
	# 2. Normal unit card move/swap:
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
		if gold_deductor.is_valid():
			gold_deductor.call(original_slot.price)
		if shop_refiller.is_valid():
			shop_refiller.call(original_slot.slot_index)
			
	# Emit signals
	slot_changed.emit(self)
	original_slot.slot_changed.emit(original_slot)

func add_card(card: Control) -> void:
	if has_node("CardContainer"):
		card_container.add_child(card)
		if "slot" in card:
			card.set("slot", self)
		if is_shop_slot and "price" in card:
			price = card.get("price") as int

func remove_card(card: Control) -> void:
	if has_node("CardContainer"):
		card_container.remove_child(card)
		if "slot" in card:
			card.set("slot", null)

## Returns the Card child node of this slot, if any. Otherwise returns null.
func get_card() -> Control:
	if not has_node("CardContainer"):
		return null
	for child: Node in card_container.get_children():
		if child.has_method("update_ui"):
			return child as Control
	return null

## Check if slot is empty
func is_empty() -> bool:
	return get_card() == null

## Returns the UnitInstance from the card in this slot, or null
func get_unit_instance() -> UnitInstance:
	var card: Control = get_card()
	if card and "unit_instance" in card:
		return card.get("unit_instance") as UnitInstance
	return null
