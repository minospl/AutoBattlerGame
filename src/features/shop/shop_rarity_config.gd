class_name ShopRarityConfig
extends Resource

const BASE_WEIGHTS_BY_DAY: Dictionary[int, Array] = {
	1: [1.00, 0.00, 0.00, 0.00],
	2: [0.85, 0.15, 0.00, 0.00],
	3: [0.70, 0.30, 0.00, 0.00],
	4: [0.60, 0.35, 0.05, 0.00],
	5: [0.50, 0.40, 0.10, 0.00],
	6: [0.40, 0.40, 0.20, 0.00],
	7: [0.30, 0.40, 0.25, 0.05],
	8: [0.20, 0.40, 0.30, 0.10],
	9: [0.15, 0.35, 0.35, 0.15],
	10: [0.10, 0.30, 0.40, 0.20],
	11: [0.10, 0.25, 0.40, 0.25],
	12: [0.10, 0.20, 0.40, 0.30],
	13: [0.10, 0.15, 0.40, 0.35],
	14: [0.05, 0.15, 0.40, 0.40],
	15: [0.05, 0.10, 0.40, 0.45],
}

func get_weights_for_day(p_day: int, disabled_rarities: Array[Rarity.Type] = []) -> Array[float]:
	var day_clamped: int = clampi(p_day, 1, 15)
	var raw_weights: Variant = BASE_WEIGHTS_BY_DAY.get(day_clamped, [0.05, 0.10, 0.40, 0.45])
	var typed_weights: Array[float] = []
	if raw_weights is Array:
		for val: Variant in raw_weights:
			if val is float:
				typed_weights.append(val)

	if typed_weights.size() < 4:
		typed_weights = [1.0, 0.0, 0.0, 0.0]

	for r: Rarity.Type in disabled_rarities:
		var idx: int = int(r)
		if idx >= 0 and idx < typed_weights.size():
			typed_weights[idx] = 0.0

	return normalize_weights(typed_weights)

func normalize_weights(p_weights: Array[float]) -> Array[float]:
	var normalized: Array[float] = p_weights.duplicate()
	var total: float = 0.0
	for w: float in normalized:
		total += w

	if total > 0.0:
		for i: int in range(normalized.size()):
			normalized[i] /= total
	else:
		normalized = [1.0, 0.0, 0.0, 0.0]

	return normalized
