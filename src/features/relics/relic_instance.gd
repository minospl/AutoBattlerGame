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

static func has_relic(relic_list: Array[RelicInstance], p_name: String) -> bool:
	for r: RelicInstance in relic_list:
		if r and r.data and r.data.relic_name == p_name:
			return true
	return false

func clone() -> RelicInstance:
	var new_inst: RelicInstance = RelicInstance.new()
	new_inst.data = data
	new_inst.stacks = stacks
	return new_inst
