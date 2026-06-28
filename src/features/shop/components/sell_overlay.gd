class_name SellOverlay
extends MarginContainer

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var parent: Node = get_parent()
	if parent and parent.has_method("_can_drop_data"):
		var result: bool = parent.call("_can_drop_data", at_position, data)
		return result
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var parent: Node = get_parent()
	if parent and parent.has_method("_drop_data"):
		parent.call("_drop_data", at_position, data)
