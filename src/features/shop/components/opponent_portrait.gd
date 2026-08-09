class_name OpponentPortrait
extends Control

signal portrait_clicked(bot_id: int)

@onready var border_rect: ShaderBorderDecorator = $BorderRect
@onready var number_label: Label = $NumberLabel
@onready var next_badge: BaseBadge = $NextBadge as BaseBadge

var bot_id: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if border_rect: border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if number_label: number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if next_badge: next_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _gui_input(event: InputEvent) -> void:
	var mb_event: InputEventMouseButton = event as InputEventMouseButton
	if mb_event and mb_event.pressed and mb_event.button_index == MOUSE_BUTTON_LEFT:
		if bot_id != -1:
			portrait_clicked.emit(bot_id)

func setup(p_bot_id: int, is_in_pool: bool, is_next: bool, archetype_color: Color) -> void:
	bot_id = p_bot_id
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
