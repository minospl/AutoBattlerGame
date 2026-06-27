class_name TargetResolver
extends Object

## Given the source index in the active team (0-5) and a TargetType,
## returns an array of target slot indices in the active team.
static func get_target_indices(source_idx: int, target_type: UnitModifier.TargetType) -> Array[int]:
	var targets: Array[int] = []
	
	# Active team is a 2x3 grid:
	# Row 0: Slots 0, 1, 2 (top)
	# Row 1: Slots 3, 4, 5 (bottom)
	var row: int = floori(source_idx / 3.0)
	var col: int = source_idx % 3
	
	var row_up: int = row - 1
	var row_down: int = row + 1
	var col_left: int = col - 1
	var col_right: int = col + 1
	
	# Helper to get slot index at (r, c)
	var get_idx: Callable = func(r: int, c: int) -> int:
		if r >= 0 and r < 2 and c >= 0 and c < 3:
			return r * 3 + c
		return -1
		
	var left: int = -1
	var right: int = -1
	var up: int = -1
	var down: int = -1
	match target_type:
		UnitModifier.TargetType.SELF:
			targets.append(source_idx)
		UnitModifier.TargetType.UP:
			up = get_idx.call(row_up, col)
		UnitModifier.TargetType.DOWN:
			down = get_idx.call(row_down, col)
		UnitModifier.TargetType.LEFT:
			left = get_idx.call(row, col_left)
		UnitModifier.TargetType.RIGHT:
			right = get_idx.call(row, col_right)
		UnitModifier.TargetType.VERTICAL:
			up = get_idx.call(row_up, col)
			down = get_idx.call(row_down, col)
		UnitModifier.TargetType.HORIZONTAL:
			left = get_idx.call(row, col_left)
			right = get_idx.call(row, col_right)
		UnitModifier.TargetType.ADJACENT:
			left = get_idx.call(row, col_left)
			right = get_idx.call(row, col_right)
			up = get_idx.call(row_up, col)
			down = get_idx.call(row_down, col)
		UnitModifier.TargetType.ALL:
			for i: int in range(6):
				if i != source_idx:
					targets.append(i)
	
	if left != -1: targets.append(left)
	if right != -1: targets.append(right)
	if up != -1: targets.append(up)
	if down != -1: targets.append(down)
					
	return targets
