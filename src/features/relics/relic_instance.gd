class_name RelicInstance
extends Resource

## Reference to the base relic template
@export var data: RelicData

## Number of stacks of this relic
@export var stacks: int = 1

## Initialize instance from template
func initialize(p_data: RelicData) -> void:
	data = p_data
	stacks = 1

## Clone this relic instance
func clone() -> RelicInstance:
	var new_inst: RelicInstance = RelicInstance.new()
	new_inst.data = data
	new_inst.stacks = stacks
	return new_inst
