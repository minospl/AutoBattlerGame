class_name OpponentPortrait
extends Control

@onready var border_rect: ShaderBorderDecorator = $BorderRect
@onready var number_label: Label = $NumberLabel
@onready var next_badge: BaseBadge = $NextBadge as BaseBadge

func _ready() -> void:
	pass

func setup(bot_id: int, is_in_pool: bool, is_next: bool, archetype_color: Color) -> void:
	border_rect.interior_color = archetype_color
	number_label.text = str(bot_id)
	number_label.add_theme_font_size_override("font_size", 16)
	
	if next_badge:
		if is_next:
			next_badge.visible = true
			next_badge.setup(Color(0.9, 0.7, 0.2), Color(0.2, 0.1, 0.0))
		elif is_in_pool:
			next_badge.visible = true
			next_badge.setup(Color(0.7, 0.7, 0.7), Color(0.2, 0.1, 0.0))
		else:
			next_badge.visible = false
