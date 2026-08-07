class_name BaseBadge
extends Panel

@export var border_color: Color = Color(0.2, 0.1, 0.0, 1.0):
	set(val):
		border_color = val
		if border_rect:
			border_rect.border_color = border_color
			border_rect.update_shader_parameters()

@export var interior_color: Color = Color(0.9, 0.7, 0.2, 1.0):
	set(val):
		interior_color = val
		if border_rect:
			border_rect.interior_color = interior_color
			border_rect.update_shader_parameters()

@export var badge_size: Vector2 = Vector2(8, 8):
	set(val):
		badge_size = val
		custom_minimum_size = badge_size
		size = badge_size

@onready var border_rect: ShaderBorderDecorator = $BadgeBorderRect

func setup(p_interior_color: Color = interior_color, p_border_color: Color = border_color) -> void:
	interior_color = p_interior_color
	border_color = p_border_color
	if border_rect:
		border_rect.border_color = border_color
		border_rect.interior_color = interior_color
		border_rect.update_shader_parameters()
