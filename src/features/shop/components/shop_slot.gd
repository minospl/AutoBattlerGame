class_name ShopSlot
extends Control

@export var slot_index: int = 0

var is_frozen: bool = false:
	set(val):
		is_frozen = val
		_update_frozen_ui()

@onready var card_container: PanelContainer = %CardContainer

func _ready() -> void:
	custom_minimum_size = CardUIHelper.CARD_SLOT_SIZE_SHOP
	card_container.custom_minimum_size = CardUIHelper.CARD_SLOT_SIZE_SHOP
	card_container.offset_top = 0
	card_container.offset_bottom = card_container.custom_minimum_size.y
	card_container.offset_right = card_container.custom_minimum_size.x
	
	# Connect tree notifications to toggle border visibility
	card_container.child_entered_tree.connect(func(_node: Node) -> void: update_placeholder.call_deferred())
	card_container.child_exiting_tree.connect(func(_node: Node) -> void: update_placeholder.call_deferred())
	
	update_placeholder()

func update_placeholder() -> void:
	var empty: bool = is_empty()
	var border_rect: ShaderBorderDecorator = card_container.get_node_or_null("BorderRect") as ShaderBorderDecorator
	if border_rect:
		border_rect.visible = empty
		if empty:
			border_rect.border_color = GameColors.BORDER_OUTER_DEFAULT
			border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
			border_rect.update_shader_parameters()
	_update_frozen_ui()

func _update_frozen_ui() -> void:
	var card: Control = get_card()
	if card and card.has_method("set_frozen"):
		card.call("set_frozen", is_frozen)

func add_card(card: Control) -> void:
	if has_node("CardContainer"):
		card_container.add_child(card)
		if "slot" in card:
			card.set("slot", self)
		_update_frozen_ui.call_deferred()

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
