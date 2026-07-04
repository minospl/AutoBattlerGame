class_name ShopCardSlot
extends Control

signal drag_hover_started(slot: ShopCardSlot, data: Dictionary)
signal drag_hover_ended(slot: ShopCardSlot)
signal card_dropped(dragged_card: Control, original_slot: ShopCardSlot, target_slot: ShopCardSlot)

var is_drag_hovering: bool = false

## If true, this slot is part of the active combat team. If false, it is on the bench.
@export var is_active_team: bool = false

## Index of the slot in the respective team/bench array
@export var slot_index: int = 0

@export var is_shop_slot: bool = false
@export var price: int = 3:
	set(val):
		price = val
		if has_node("%PriceLabel"):
			var label: Label = get_node("%PriceLabel")
			label.text = str(price) + "g"
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
	
	update_placeholder()
	
	# Setup Shop Controls
	if is_shop_slot:
		custom_minimum_size.y = 160
		if has_node("%ShopControls"):
			var controls: Control = get_node("%ShopControls")
			controls.visible = true
			var price_lbl: Label = get_node("%PriceLabel")
			price_lbl.text = str(price) + "g"
			var freeze_btn: Button = get_node("%FreezeButton")
			freeze_btn.toggled.connect(func(pressed: bool) -> void:
				is_frozen = pressed
				_update_freeze_button_style()
			)
			_update_freeze_button_style()
	else:
		if has_node("%ShopControls"):
			var controls: Control = get_node("%ShopControls")
			controls.visible = false
		custom_minimum_size.y = 135

func _update_freeze_button_style() -> void:
	if not has_node("%FreezeButton"):
		return
	var btn: Button = get_node("%FreezeButton")
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
		var lbl: Control = card_container.get_node("EmptyPlaceholderLabel")
		lbl.visible = empty
		
	var border_rect: ShaderBorderDecorator = card_container.get_node_or_null("BorderRect") as ShaderBorderDecorator
	if border_rect:
		border_rect.visible = empty
		
	update_style()

func _process(_delta: float) -> void:
	if is_highlighted and get_viewport().gui_is_dragging():
		var mouse_pos: Vector2 = card_container.get_local_mouse_position()
		var rect: Rect2 = Rect2(Vector2.ZERO, card_container.size)
		if not rect.has_point(mouse_pos):
			update_style(false)
			if is_drag_hovering:
				is_drag_hovering = false
				drag_hover_ended.emit(self)

# Determine if we can drop a dragged item onto this slot
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not drag_drop_enabled:
		return false
		
	if is_shop_slot:
		return false # Cannot drop cards into shop slots!
		
	if typeof(data) == TYPE_DICTIONARY:
		var dict: Dictionary = data
		if dict.has("card") and dict.has("original_slot"):
			var dragged_card: Control = dict["card"]
			var original_slot: ShopCardSlot = dict["original_slot"]
			
			# Check if the player has enough gold for a purchase
			if original_slot and original_slot.is_shop_slot:
				if gold_provider.is_valid():
					var current_gold: int = gold_provider.call()
					if current_gold < original_slot.price:
						return false # Cannot afford this card
			
			# If the dragged card is food:
			if dragged_card is ShopCardItem:
				# Food can ONLY be dropped onto an occupied unit slot to consume it
				var target_card: Control = get_card()
				if target_card and "unit_instance" in target_card:
					update_style(true)
					if not is_drag_hovering:
						is_drag_hovering = true
						drag_hover_started.emit(self, dict)
					return true
				return false
		
			# Normal unit card
			update_style(true)
			if not is_drag_hovering:
				is_drag_hovering = true
				drag_hover_started.emit(self, dict)
			return true
			
	return false

# Handle cleanup when drag drops elsewhere, leaves the slot, or is canceled
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		# Restore proper style based on slot occupancy
		update_style(false)
		if is_drag_hovering:
			is_drag_hovering = false
			drag_hover_ended.emit(self)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	update_style(false)
	if is_drag_hovering:
		is_drag_hovering = false
		drag_hover_ended.emit(self)
	
	if typeof(data) == TYPE_DICTIONARY:
		var dict: Dictionary = data
		if dict.has("card") and dict.has("original_slot"):
			var dragged_card: Control = dict["card"]
			var original_slot: ShopCardSlot = dict["original_slot"]
			card_dropped.emit(dragged_card, original_slot, self)

func add_card(card: Control) -> void:
	if has_node("CardContainer"):
		card_container.add_child(card)
		if "slot" in card:
			card.set("slot", self)
		if is_shop_slot and "price" in card:
			price = card.get("price")

func remove_card(card: Control) -> void:
	if has_node("CardContainer") and card.get_parent() == card_container:
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

## Check if slot is empty (treats hidden cards, e.g. during dragging, as empty)
func is_empty() -> bool:
	var card: Control = get_card()
	return card == null or not card.visible

## Returns the UnitInstance from the card in this slot, or null
func get_unit_instance() -> UnitInstance:
	var card: Control = get_card()
	if card and "unit_instance" in card:
		var inst: UnitInstance = card.get("unit_instance")
		return inst
	return null
