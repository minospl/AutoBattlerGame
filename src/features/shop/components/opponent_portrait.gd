class_name OpponentPortrait
extends Control

@onready var border_rect: ShaderBorderDecorator = $BorderRect
@onready var number_label: Label = $NumberLabel
@onready var next_badge: Panel = $NextBadge

func _ready() -> void:
	pass

func setup(day_num: int, is_next: bool, archetype_color: Color) -> void:
	border_rect.interior_color = archetype_color
	number_label.text = str(day_num)
	next_badge.visible = is_next
	
	number_label.add_theme_font_size_override("font_size", 16)
