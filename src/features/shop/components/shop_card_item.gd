class_name ShopCardItem
extends VBoxContainer

signal hovered(card: ShopCardItem, is_hovered: bool)
signal clicked(card: ShopCardItem)

@export var price: int

@export var item_instance: ItemInstance:
	set(val):
		item_instance = val
		if item_instance and item_instance.data:
			price = item_instance.data.price
		if is_inside_tree():
			update_ui()

@onready var card_portrait: CardPortrait = %CardPortrait
var slot: ShopSlot = null
var affordability_validator: Callable = func() -> bool: return true

func _ready() -> void:
	custom_minimum_size = CardUIHelper.CARD_SLOT_SIZE_SHOP
	update_ui()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func update_ui() -> void:
	if not item_instance:
		return
		
	card_portrait.setup_visuals(item_instance.data)
	card_portrait.border_rect.interior_color = GameColors.WHITE_COLOR
	card_portrait.border_rect.update_shader_parameters()
	
	var texture_rect: TextureRect = card_portrait.find_child("TextureRect", true, false)
	if texture_rect:
		texture_rect.offset_top = -20.0
	
	# Configure name and price footer
	var name_label: Label = %NameLabel as Label
	if name_label and item_instance.data:
		name_label.text = item_instance.data.display_name
		
	var price_label: Label = %PriceLabel as Label
	if price_label:
		price_label.text = str(price) + "G"

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_instance.data.is_clickable:
		return null
		
	if not affordability_validator.call():
		return null
		
	# Keep the card in place but dim it visually so we can see the item while targeting
	modulate.a = 0.5
	
	# Create an empty transparent preview so no card visual is dragged under the mouse
	var preview_wrapper: Control = Control.new()
	set_drag_preview(preview_wrapper)
	
	var original_slot: ShopSlot = slot
		
	# Notify about the drag starting using DragManager
	DragManager.notify_drag_started(self, original_slot)
		
	# Restore normal appearance when drag ends
	preview_wrapper.tree_exiting.connect(func() -> void:
		if is_instance_valid(self):
			modulate.a = 1.0
			if original_slot:
				original_slot.update_placeholder()
		DragManager.notify_drag_ended()
	)
	
	return {
		"card": self,
		"original_slot": original_slot
	}

func _on_mouse_entered() -> void:
	if DragManager.dragged_card:
		return
	hovered.emit(self, true)

func _on_mouse_exited() -> void:
	hovered.emit(self, false)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if item_instance and item_instance.data and item_instance.data.is_clickable:
				clicked.emit(self)
				accept_event()
