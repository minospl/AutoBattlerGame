class_name ShopCardItem
extends PanelContainer

signal hovered(card: ShopCardItem, is_hovered: bool)

@export var item_instance: ShopItemInstance:
	set(val):
		item_instance = val
		if is_inside_tree():
			update_ui()

@onready var portrait_label: Label = %PortraitCharLabel
@onready var sprite_rect: TextureRect = %SpriteRect
@onready var attack_label: Label = %AttackLabel
@onready var hp_label: Label = %HpLabel
@onready var attack_panel: PanelContainer = %AttackPanel
@onready var hp_panel: PanelContainer = %HpPanel

func _ready() -> void:
	update_ui()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	tree_exiting.connect(_on_mouse_exited)

func update_ui() -> void:
	if not item_instance:
		return
		
	# Delegate visual setup to shared CardUIHelper
	CardUIHelper.setup_item_visuals(
		item_instance.item_name,
		item_instance.stat_boost_attack,
		item_instance.stat_boost_hp,
		portrait_label,
		sprite_rect,
		attack_panel,
		attack_label,
		hp_panel,
		hp_label,
		get_node_or_null("BorderRect") as ShaderBorderDecorator
	)

func apply_food_effect(card: Control) -> void:
	if not item_instance:
		return
	var inst = card.unit_instance
	if inst:
		inst.current_attack += item_instance.stat_boost_attack
		inst.max_health_bonus += item_instance.stat_boost_hp
		inst.current_health += item_instance.stat_boost_hp

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Keep the card in place but dim it visually
	modulate.a = 0.5
	
	# Create an empty transparent preview so no card visual is dragged under the mouse
	var preview_wrapper = Control.new()
	set_drag_preview(preview_wrapper)
	
	var original_slot = get_parent()
	while original_slot and not original_slot.has_method("add_card"):
		original_slot = original_slot.get_parent()
		
	# Notify about the drag starting using DragManager
	DragManager.notify_drag_started(self, original_slot)
		
	# Restore normal modulate when drag ends
	preview_wrapper.tree_exiting.connect(func():
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
