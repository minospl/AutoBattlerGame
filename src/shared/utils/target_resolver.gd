class_name TargetResolver
extends Object

## Given the source index in the active team (0-5) and a TargetType,
## returns an array of target slot indices in the active team.
static func get_target_indices(source_idx: int, target_type: UnitModifier.TargetType, has_magnetic_core: bool = false, has_focusing_lens: bool = false) -> Array[int]:
	if has_magnetic_core and target_type == UnitModifier.TargetType.ADJACENT:
		target_type = UnitModifier.TargetType.ALL
		
	if has_focusing_lens:
		if target_type == UnitModifier.TargetType.LEFT:
			target_type = UnitModifier.TargetType.LEFT_PLUS
		elif target_type == UnitModifier.TargetType.RIGHT:
			target_type = UnitModifier.TargetType.RIGHT_PLUS
		elif target_type == UnitModifier.TargetType.HORIZONTAL:
			target_type = UnitModifier.TargetType.HORIZONTAL_PLUS
			
	var targets: Array[int] = []
	
	var row: int = floori(source_idx / 3.0)
	var col: int = source_idx % 3
	
	match target_type:
		UnitModifier.TargetType.SELF:
			targets.append(source_idx)
			
		UnitModifier.TargetType.UP:
			_append_if_valid(targets, _get_idx(row - 1, col))
			
		UnitModifier.TargetType.DOWN:
			_append_if_valid(targets, _get_idx(row + 1, col))
			
		UnitModifier.TargetType.VERTICAL:
			_append_if_valid(targets, _get_idx(row - 1, col))
			_append_if_valid(targets, _get_idx(row + 1, col))
			
		UnitModifier.TargetType.LEFT:
			_append_if_valid(targets, _get_idx(row, col - 1))
			
		UnitModifier.TargetType.LEFT_PLUS:
			for c: int in range(col):
				_append_if_valid(targets, _get_idx(row, c))
				
		UnitModifier.TargetType.RIGHT:
			_append_if_valid(targets, _get_idx(row, col + 1))
			
		UnitModifier.TargetType.RIGHT_PLUS:
			for c: int in range(col + 1, 3):
				_append_if_valid(targets, _get_idx(row, c))
				
		UnitModifier.TargetType.HORIZONTAL:
			_append_if_valid(targets, _get_idx(row, col - 1))
			_append_if_valid(targets, _get_idx(row, col + 1))
			
		UnitModifier.TargetType.HORIZONTAL_PLUS:
			for c: int in range(3):
				if c != col:
					_append_if_valid(targets, _get_idx(row, c))
					
		UnitModifier.TargetType.ADJACENT:
			_append_if_valid(targets, _get_idx(row, col - 1))
			_append_if_valid(targets, _get_idx(row, col + 1))
			_append_if_valid(targets, _get_idx(row - 1, col))
			_append_if_valid(targets, _get_idx(row + 1, col))
			
		UnitModifier.TargetType.ALL:
			for i: int in range(6):
				if i != source_idx:
					targets.append(i)
					
	return targets

static func _append_if_valid(targets: Array[int], slot_idx: int) -> void:
	if slot_idx != -1:
		targets.append(slot_idx)

## Helper to get slot index at grid coordinate (r, c) on a 2x3 active team grid.
## Returns -1 if coordinates are out of bounds.
static func _get_idx(r: int, c: int) -> int:
	if r >= 0 and r < 2 and c >= 0 and c < 3:
		return r * 3 + c
	return -1
