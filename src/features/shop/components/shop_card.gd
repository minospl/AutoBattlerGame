class_name ShopCard
extends PanelContainer

signal hovered(card: ShopCard, is_hovered: bool)
signal clicked(card: ShopCard)

@export var price: int

@export var unit_instance: UnitInstance:
	set(val):
		unit_instance = val
		if unit_instance and unit_instance.data:
			price = unit_instance.data.price
		if is_inside_tree():
			update_ui()

@onready var left_indicator: Panel = %TriggerTargetLeftIndicator
@onready var right_indicator: Panel = %TriggerTargetRightIndicator
@onready var top_indicator: Panel = %TriggerTargetTopIndicator
@onready var bottom_indicator: Panel = %TriggerTargetBottomIndicator

var is_highlighted: bool = false
var is_targeted: bool = false
var slot: ShopCardSlot = null

func _ready() -> void:
	update_ui()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	tree_exiting.connect(_on_mouse_exited)

func update_ui() -> void:
	if not unit_instance:
		return
		
	# Delegate visual rendering to shared helper
	CardUIHelper.setup_card_visuals(
		unit_instance,
		%StatsHBox as HBoxContainer,
		%SpriteRect as TextureRect,
		%PortraitCharLabel as Label,
		left_indicator,
		right_indicator,
		top_indicator,
		bottom_indicator
	)
	
	# Set background styling to white inside the slot
	var border_rect = get_node_or_null("BorderRect") as ShaderBorderDecorator
	if border_rect:
		border_rect.interior_color = GameColors.WHITE_COLOR
		border_rect.update_shader_parameters()
		
	update_border_colors()

func set_highlight(active: bool) -> void:
	is_highlighted = active
	update_border_colors()

func set_target_highlight(active: bool) -> void:
	is_targeted = active
	update_border_colors()

func update_border_colors() -> void:
	var border_rect = get_node_or_null("BorderRect") as ShaderBorderDecorator
	if not border_rect:
		return
		
	if is_highlighted:
		border_rect.border_color = GameColors.SLOT_HOVER_OUTER_BORDER
		border_rect.inner_border_color = GameColors.SLOT_HOVER_INNER_BORDER
	elif is_targeted:
		border_rect.border_color = Color(0.9, 0.15, 0.15, 1.0)
		border_rect.inner_border_color = Color(0.5, 0.05, 0.05, 1.0)
	else:
		var rarity_color = unit_instance.data.rarity.border_color if (unit_instance and unit_instance.data and unit_instance.data.rarity) else GameColors.BORDER_OUTER_DEFAULT
		border_rect.border_color = rarity_color
		border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
	border_rect.update_shader_parameters()

func _on_mouse_entered() -> void:
	if DragManager.dragged_card:
		return
	hovered.emit(self, true)

func _on_mouse_exited() -> void:
	hovered.emit(self, false)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if slot and slot.is_shop_slot:
		return null
		
	# Create a visual preview of what we are dragging
	var preview_scene = load("res://src/features/shop/components/shop_card.tscn")
	var preview = preview_scene.instantiate()
	preview.unit_instance = unit_instance
	preview.custom_minimum_size = custom_minimum_size
	
	# Semitransparent preview
	preview.modulate.a = 0.7
	
	# Create a wrapper control to center the preview under the mouse cursor
	var preview_wrapper = Control.new()
	preview_wrapper.add_child(preview)
	preview.position = -custom_minimum_size / 2.0
	
	set_drag_preview(preview_wrapper)
	
	# Find original CardSlot ancestor using the slot reference
	var original_slot := slot
		
	# Temporarily remove the card from the original slot
	if original_slot:
		original_slot.remove_card.call_deferred(self)
		original_slot.slot_changed.emit.call_deferred(original_slot)
		
	# Notify about the drag starting using DragManager
	DragManager.notify_drag_started(self, original_slot)
		
	var viewport: Viewport = get_viewport()
	preview_wrapper.tree_exiting.connect(func() -> void:
		# If the drag was not successful, return the card to its original slot
		if viewport and not viewport.gui_is_drag_successful():
			if original_slot:
				original_slot.add_card(self)
				original_slot.slot_changed.emit(original_slot)
		DragManager.notify_drag_ended()
	)
	
	return {
		"card": self,
		"original_slot": original_slot
	}

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if slot and slot.is_shop_slot:
				clicked.emit(self)
				accept_event()
