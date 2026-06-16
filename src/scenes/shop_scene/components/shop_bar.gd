class_name ShopBar
extends PanelContainer

signal add_monster_requested
signal clear_requested

@export var lives: int = 10:
	set(value):
		lives = value
		_update_labels()

@export var day: int = 4:
	set(value):
		day = value
		_update_labels()

@export var trophies: int = 3:
	set(value):
		trophies = value
		_update_labels()

@export var max_trophies: int = 10:
	set(value):
		max_trophies = value
		_update_labels()

@onready var add_btn: Button = %AddButton
@onready var clear_btn: Button = %ClearButton

@onready var lives_label: Label = %LivesLabel
@onready var day_label: Label = %DayLabel
@onready var trophies_label: Label = %TrophiesLabel

func _ready() -> void:
	# Connect local button signals
	add_btn.pressed.connect(func(): add_monster_requested.emit())
	clear_btn.pressed.connect(func(): clear_requested.emit())
	
	# Apply visual styling programmatically to keep the presentation premium and clean
	_apply_visual_styling()
	_update_labels()

func _update_labels() -> void:
	if is_inside_tree():
		if lives_label:
			lives_label.text = str(lives)
		if day_label:
			day_label.text = "DAY " + str(day)
		if trophies_label:
			trophies_label.text = str(trophies) + "/" + str(max_trophies)

func _apply_visual_styling() -> void:
	# 1. Apply background shader
	var panel_mat = ShaderMaterial.new()
	panel_mat.shader = load("res://src/shared/shaders/shop_bar_bg.gdshader")
	self.material = panel_mat
	
	# Connect to resized to update shader size uniform
	self.resized.connect(func():
		if self.material:
			self.material.set_shader_parameter("size", self.size)
	)
	
	# Force initial size update
	if self.material:
		var initial_size = self.size if self.size != Vector2.ZERO else (custom_minimum_size if custom_minimum_size != Vector2.ZERO else Vector2(1280, 50))
		self.material.set_shader_parameter("size", initial_size)
		
	# 2. Transparent panel stylebox to let shader draw cleanly
	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	add_theme_stylebox_override("panel", transparent_style)
	
	# 3. Add Monster Button (Premium Green Action)
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = GameColors.BTN_GREEN_NORMAL # Flat emerald green
	btn_normal.corner_radius_top_left = 6
	btn_normal.corner_radius_top_right = 6
	btn_normal.corner_radius_bottom_right = 6
	btn_normal.corner_radius_bottom_left = 6
	btn_normal.content_margin_left = 12
	btn_normal.content_margin_right = 12
	btn_normal.content_margin_top = 6
	btn_normal.content_margin_bottom = 6
	add_btn.add_theme_stylebox_override("normal", btn_normal)
	
	var btn_hover = btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = GameColors.BTN_GREEN_HOVER # Brighter green on hover
	add_btn.add_theme_stylebox_override("hover", btn_hover)
	
	var btn_pressed = btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = GameColors.BTN_GREEN_PRESSED
	add_btn.add_theme_stylebox_override("pressed", btn_pressed)
	
	# 4. Clear Button (Danger Outline Action)
	var clear_normal = StyleBoxFlat.new()
	clear_normal.bg_color = GameColors.BTN_DARK_NORMAL # Sleek dark
	clear_normal.corner_radius_top_left = 6
	clear_normal.corner_radius_top_right = 6
	clear_normal.corner_radius_bottom_right = 6
	clear_normal.corner_radius_bottom_left = 6
	clear_normal.content_margin_left = 12
	clear_normal.content_margin_right = 12
	clear_normal.content_margin_top = 6
	clear_normal.content_margin_bottom = 6
	clear_btn.add_theme_stylebox_override("normal", clear_normal)
	
	var clear_hover = clear_normal.duplicate() as StyleBoxFlat
	clear_hover.bg_color = GameColors.BTN_RED_HOVER # Red tint on hover
	clear_btn.add_theme_stylebox_override("hover", clear_hover)
	
	var clear_pressed = clear_normal.duplicate() as StyleBoxFlat
	clear_pressed.bg_color = GameColors.BTN_RED_PRESSED
	clear_btn.add_theme_stylebox_override("pressed", clear_pressed)
