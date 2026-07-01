class_name ShopCardItem
extends PanelContainer

signal hovered(card: ShopCardItem, is_hovered: bool)

@export var item_instance: ItemInstance:
	set(val):
		item_instance = val
		if is_inside_tree():
			update_ui()

@onready var portrait_label: Label = %PortraitCharLabel
@onready var sprite_rect: TextureRect = %SpriteRect
var slot: ShopCardSlot = null

func _ready() -> void:
	update_ui()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	tree_exiting.connect(_on_mouse_exited)

func update_ui() -> void:
	if not item_instance or not item_instance.data:
		return
		
	# Delegate visual setup to shared CardUIHelper
	CardUIHelper.setup_item_visuals(
		item_instance,
		portrait_label,
		sprite_rect,
		get_node_or_null("BorderRect") as ShaderBorderDecorator
	)

func apply_food_effect(card: Control) -> void:
	if not item_instance or not item_instance.data:
		return
	if card is ShopCard:
		var shop_card: ShopCard = card
		var inst: UnitInstance = shop_card.unit_instance
		if inst and item_instance.data.modifier:
			item_instance.data.modifier.apply_unit_effect(inst)

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Keep the card in place but dim it visually
	modulate.a = 0.5
	
	# Create an empty transparent preview so no card visual is dragged under the mouse
	var preview_wrapper: Control = Control.new()
	set_drag_preview(preview_wrapper)
	
	var original_slot: ShopCardSlot = slot
		
	# Notify about the drag starting using DragManager
	DragManager.notify_drag_started(self, original_slot)
		
	# Restore normal modulate when drag ends
	preview_wrapper.tree_exiting.connect(func() -> void:
		modulate.a = 1.0
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
