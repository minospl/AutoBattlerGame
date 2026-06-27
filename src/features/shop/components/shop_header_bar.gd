class_name ShopHeaderBar
extends PanelContainer

signal add_monster_requested
signal restart_requested
signal battle_requested

@export var lives: int:
	set(value):
		lives = value
		_update_labels()

@export var day: int:
	set(value):
		day = value
		_update_labels()

@export var trophies: int:
	set(value):
		trophies = value
		_update_labels()

@export var max_trophies: int:
	set(value):
		max_trophies = value
		_update_labels()

@onready var add_btn: Button = %AddButton
@onready var restart_btn: Button = %RestartButton
@onready var battle_btn: Button = %BattleButton

@onready var lives_label: Label = %LivesLabel

@onready var day_label: Label = %DayLabel
@onready var trophies_label: Label = %TrophiesLabel

func _ready() -> void:
	# Connect local button signals
	add_btn.pressed.connect(func() -> void: add_monster_requested.emit())
	restart_btn.pressed.connect(func() -> void: restart_requested.emit())
	battle_btn.pressed.connect(func() -> void: battle_requested.emit())
	
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
	var panel_mat: ShaderMaterial = ShaderMaterial.new()
	panel_mat.shader = load("res://src/shared/shaders/shop_header_bar_bg.gdshader")
	
	# Connect to resized to update shader size uniform
	self.resized.connect(func() -> void:
		if panel_mat: panel_mat.set_shader_parameter("size", self.size)
	)
	
	# Force initial size update
	if panel_mat:
		var initial_size: Vector2 = self.size if self.size != Vector2.ZERO else (custom_minimum_size if custom_minimum_size != Vector2.ZERO else Vector2(1280, 50))
		panel_mat.set_shader_parameter("size", initial_size)
		
	self.material = panel_mat
	# 2. Transparent panel stylebox to let shader draw cleanly
	var transparent_style: StyleBoxFlat = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	add_theme_stylebox_override("panel", transparent_style)
