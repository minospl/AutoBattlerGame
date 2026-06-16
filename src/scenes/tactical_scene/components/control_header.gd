class_name ControlHeader
extends HBoxContainer

signal add_monster_requested
signal clear_requested
signal multiply_requested

@onready var add_btn: Button = %AddButton
@onready var clear_btn: Button = %ClearButton
@onready var multiply_btn: Button = %MultiplyButton

func _ready() -> void:
	# Connect local button signals
	add_btn.pressed.connect(func(): add_monster_requested.emit())
	clear_btn.pressed.connect(func(): clear_requested.emit())
	multiply_btn.pressed.connect(func(): multiply_requested.emit())
	
	# Apply visual styling programmatically to keep the presentation premium and clean
	_apply_visual_styling()

func _apply_visual_styling() -> void:
	# 1. Add Monster Button (Premium Green Action)
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = GameColors.BTN_GREEN_NORMAL # Flat emerald green
	btn_normal.corner_radius_top_left = 6
	btn_normal.corner_radius_top_right = 6
	btn_normal.corner_radius_bottom_right = 6
	btn_normal.corner_radius_bottom_left = 6
	btn_normal.content_margin_left = 16
	btn_normal.content_margin_right = 16
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_bottom = 8
	add_btn.add_theme_stylebox_override("normal", btn_normal)
	
	var btn_hover = btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = GameColors.BTN_GREEN_HOVER # Brighter green on hover
	add_btn.add_theme_stylebox_override("hover", btn_hover)
	
	var btn_pressed = btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = GameColors.BTN_GREEN_PRESSED
	add_btn.add_theme_stylebox_override("pressed", btn_pressed)
	
	# 2. Clear Button (Danger Outline Action)
	var clear_normal = StyleBoxFlat.new()
	clear_normal.bg_color = GameColors.BTN_DARK_NORMAL # Sleek dark
	clear_normal.corner_radius_top_left = 6
	clear_normal.corner_radius_top_right = 6
	clear_normal.corner_radius_bottom_right = 6
	clear_normal.corner_radius_bottom_left = 6
	clear_normal.content_margin_left = 16
	clear_normal.content_margin_right = 16
	clear_normal.content_margin_top = 8
	clear_normal.content_margin_bottom = 8
	clear_btn.add_theme_stylebox_override("normal", clear_normal)
	
	var clear_hover = clear_normal.duplicate() as StyleBoxFlat
	clear_hover.bg_color = GameColors.BTN_RED_HOVER # Red tint on hover
	clear_btn.add_theme_stylebox_override("hover", clear_hover)
	
	var clear_pressed = clear_normal.duplicate() as StyleBoxFlat
	clear_pressed.bg_color = GameColors.BTN_RED_PRESSED
	clear_btn.add_theme_stylebox_override("pressed", clear_pressed)
	
	# 3. Multiply Button (Premium Purple Action)
	var mult_normal = StyleBoxFlat.new()
	mult_normal.bg_color = GameColors.BTN_PURPLE_NORMAL # Flat purple
	mult_normal.corner_radius_top_left = 6
	mult_normal.corner_radius_top_right = 6
	mult_normal.corner_radius_bottom_right = 6
	mult_normal.corner_radius_bottom_left = 6
	mult_normal.content_margin_left = 16
	mult_normal.content_margin_right = 16
	mult_normal.content_margin_top = 8
	mult_normal.content_margin_bottom = 8
	multiply_btn.add_theme_stylebox_override("normal", mult_normal)
	
	var mult_hover = mult_normal.duplicate() as StyleBoxFlat
	mult_hover.bg_color = GameColors.BTN_PURPLE_HOVER # Brighter purple on hover
	multiply_btn.add_theme_stylebox_override("hover", mult_hover)
	
	var mult_pressed = mult_normal.duplicate() as StyleBoxFlat
	mult_pressed.bg_color = GameColors.BTN_PURPLE_PRESSED
	multiply_btn.add_theme_stylebox_override("pressed", mult_pressed)
	
