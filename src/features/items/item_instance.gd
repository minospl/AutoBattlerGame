class_name ItemInstance
extends Resource

## Reference to the base item template
@export var data: ItemData

## Initialize instance from template
func initialize(p_data: ItemData) -> void:
	data = p_data

func get_item_name() -> String:
	return data.display_name

## Clone this item instance
func clone() -> ItemInstance:
	var new_inst: ItemInstance = ItemInstance.new()
	new_inst.data = data
	return new_inst
