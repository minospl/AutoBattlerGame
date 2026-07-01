class_name NumberFormatter
extends RefCounted

const SUFFIXES: Array[Dictionary] = [
	{"threshold": 1_000_000_000, "divisor": 1_000_000_000.0, "suffix": "B"},
	{"threshold": 1_000_000, "divisor": 1_000_000.0, "suffix": "M"},
	{"threshold": 1_000, "divisor": 1_000.0, "suffix": "k"}
]

## Helper to format large numbers (e.g. 15029 -> 15k, 1000 -> 1k, 1500000 -> 1.5M)
static func format_large_number(value: int) -> String:
	var abs_val: int = abs(value)
	if abs_val < 1000:
		return str(value)
		
	for entry: Dictionary in SUFFIXES:
		if abs_val >= entry.threshold:
			var divided: float = value / entry.divisor
			var formatted: String = "%.1f" % divided
			if formatted.ends_with(".0"):
				formatted = str(roundi(divided))
			return formatted + entry.suffix
			
	return str(value)
