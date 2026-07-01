class_name ItemInstance
extends Resource

## Reference to the base item template
@export var data: ItemData

## Copied fields for runtime modification
@export var item_name: String
@export var price: int
@export var rarity: Rarity
@export var is_draggable: bool = false
@export var is_clickable: bool = false

## Initialize instance from template
func initialize(p_data: ItemData) -> void:
	data = p_data
	if p_data:
		item_name = p_data.item_name
		price = p_data.price
		rarity = p_data.rarity
		is_draggable = p_data.is_draggable
		is_clickable = p_data.is_clickable

## Clone this item instance
func clone() -> ItemInstance:
	var new_inst: ItemInstance = ItemInstance.new()
	new_inst.data = data
	new_inst.item_name = item_name
	new_inst.price = price
	new_inst.rarity = rarity
	new_inst.is_draggable = is_draggable
	new_inst.is_clickable = is_clickable
	return new_inst
