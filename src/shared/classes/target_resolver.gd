class_name TargetResolver
extends Object

## Given the source index in the active team (0-5) and a TargetType,
## returns an array of target slot indices in the active team.
static func get_target_indices(source_idx: int, target_type: UnitModifier.TargetType) -> Array[int]:
	var targets: Array[int] = []
	
	# Active team is a 2x3 grid:
	# Row 0: Slots 0, 1, 2 (top)
	# Row 1: Slots 3, 4, 5 (bottom)
	var row = floori(source_idx / 3.0)
	var col = source_idx % 3
	
	var row_up = row - 1
	var row_down = row + 1
	var col_left = col - 1
	var col_right = col + 1
	
	# Helper to get slot index at (r, c)
	var get_idx = func(r: int, c: int) -> int:
		if r >= 0 and r < 2 and c >= 0 and c < 3:
			return r * 3 + c
		return -1
		
	var left = -1
	var right = -1
	var up = -1
	var down = -1
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
			for i in range(6):
				if i != source_idx:
					targets.append(i)
	
	if left != -1: targets.append(left)
	if right != -1: targets.append(right)
	if up != -1: targets.append(up)
	if down != -1: targets.append(down)
					
	return targets
