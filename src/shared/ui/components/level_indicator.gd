class_name LevelIndicator
extends Control

## Indicates unit level/stars using pixel-art diamonds above the card portrait.
@export var level: int = 1:
	set(val):
		if level != val:
			level = val
			queue_redraw()

@export var max_level: int = 3:
	set(val):
		if max_level != val:
			max_level = val
			queue_redraw()

@export var diamond_size: int = 12
@export var half_size: int = 6
@export var diamond_spacing: int = 3
@export var x_offset: float = 8.0
@export var y_offset: float = 8.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 10
	z_as_relative = true

## Configures level indicator for a card.
func setup(p_level: int, p_max_level: int = 3) -> void:
	max_level = p_max_level
	level = clampi(p_level, 0, max_level)
	queue_redraw()

func _draw() -> void:
	if level <= 0 or diamond_size <= 0:
		return

	for i: int in range(level):
		var diamond_x: float = x_offset + float(i * (diamond_size + diamond_spacing))
		_draw_diamond(diamond_x, y_offset, true)

func _draw_diamond(p_x_offset: float, p_y_offset: float, is_filled: bool) -> void:
	var border_color: Color = Color.WHITE if is_filled else Color(0.32, 0.32, 0.36, 0.95)
	var center_color: Color = Color.WHITE
	var max_idx: int = diamond_size - 1

	for r: int in range(diamond_size):
		var dist: int = abs(r - half_size)
		var left_x: int = dist
		var right_x: int = max_idx - dist

		# 1. Solid opaque black background inside the diamond
		if right_x > left_x:
			draw_rect(Rect2(p_x_offset + float(left_x + 1), p_y_offset + float(r), float(right_x - left_x - 1), 1.0), Color.BLACK)

		# 2. Outer diamond border
		draw_rect(Rect2(p_x_offset + float(left_x), p_y_offset + float(r), 1.0, 1.0), border_color)
		if right_x != left_x:
			draw_rect(Rect2(p_x_offset + float(right_x), p_y_offset + float(r), 1.0, 1.0), border_color)

		# 3. Inner center diamond for active/filled level
		if is_filled and dist <= half_size - 2:
			var center_left: int = left_x + 2
			var center_right: int = right_x - 2
			if center_right >= center_left:
				draw_rect(Rect2(p_x_offset + float(center_left), p_y_offset + float(r), float(center_right - center_left + 1), 1.0), center_color)
