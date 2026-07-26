class_name NumberFormatter
extends RefCounted

const SUFFIXES: Array[Dictionary] = [
	{"threshold": 1_000_000_000, "divisor": 1_000_000_000.0, "suffix": "B"},
	{"threshold": 1_000_000, "divisor": 1_000_000.0, "suffix": "M"},
	{"threshold": 1_000, "divisor": 1_000.0, "suffix": "k"}
]

## Helper to format large numbers (e.g. 5012 -> 5.01k, 15070 -> 15.1k, 902040 -> 902k)
static func format_large_number(value: int) -> String:
	var abs_val: int = abs(value)
	if abs_val < 1000:
		return str(value)
		
	for entry: Dictionary in SUFFIXES:
		var threshold: int = entry["threshold"]
		if abs_val >= threshold:
			var divisor: float = entry["divisor"]
			var suffix: String = entry["suffix"]
			var divided: float = float(value) / divisor
			var abs_divided: float = abs(divided)
			var formatted: String
			
			if abs_divided < 10.0:
				formatted = "%.2f" % divided
			elif abs_divided < 100.0:
				formatted = "%.1f" % divided
			else:
				formatted = "%.0f" % divided
				
			if formatted.contains("."):
				formatted = formatted.rstrip("0").rstrip(".")
				
			return formatted + suffix
			
	return str(value)
