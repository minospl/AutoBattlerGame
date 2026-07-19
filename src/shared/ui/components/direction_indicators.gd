class_name DirectionIndicators
extends Control

@onready var left_indicator: Control = %TriggerTargetLeftIndicator
@onready var right_indicator: Control = %TriggerTargetRightIndicator
@onready var top_indicator: Control = %TriggerTargetTopIndicator
@onready var bottom_indicator: Control = %TriggerTargetBottomIndicator

## Configures the direction indicators using the CardUIHelper static method
func setup_indicators(unit_inst: UnitInstance) -> void:
	CardUIHelper.setup_indicators(
		unit_inst,
		left_indicator,
		right_indicator,
		top_indicator,
		bottom_indicator
	)
