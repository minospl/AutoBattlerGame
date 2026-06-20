class_name ShopHeaderBar
extends PanelContainer

signal add_monster_requested
signal restart_requested

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
@onready var restart_btn: Button = %RestartButton

@onready var lives_label: Label = %LivesLabel

@onready var day_label: Label = %DayLabel
@onready var trophies_label: Label = %TrophiesLabel

func _ready() -> void:
	# Connect local button signals
	add_btn.pressed.connect(func(): add_monster_requested.emit())
	restart_btn.pressed.connect(func(): restart_requested.emit())
	
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
	panel_mat.shader = load("res://src/shared/shaders/shop_header_bar_bg.gdshader")
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
