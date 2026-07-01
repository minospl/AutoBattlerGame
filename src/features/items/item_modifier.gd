class_name ItemModifier
extends Resource

## Called when an item is clicked/activated directly in the shop
func apply_shop_effect(_run_state: RunState) -> void:
	pass

## Called when an item is dragged and dropped onto a unit in the shop/bench
func apply_unit_effect(_target_unit: UnitInstance) -> void:
	pass

## Returns the item modifier description for the card tooltip
func get_description() -> String:
	return ""


