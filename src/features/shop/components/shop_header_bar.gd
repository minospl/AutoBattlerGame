class_name ShopHeaderBar
extends PanelContainer

signal add_monster_requested
signal add_relic_requested
signal restart_requested
signal battle_requested
signal compendium_requested

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

@onready var add_btn: Button = %AddUnitButton
@onready var add_relic_btn: Button = %AddRelicButton
@onready var restart_btn: Button = %RestartButton
@onready var battle_btn: Button = %StartBattleButton
@onready var compendium_btn: Button = %CompendiumButton
@onready var lives_label: Label = %LivesLabel
@onready var day_label: Label = %DayLabel
@onready var trophies_label: Label = %TrophiesLabel

func _ready() -> void:	
	# Connect local button signals
	add_btn.pressed.connect(func() -> void: add_monster_requested.emit())
	add_relic_btn.pressed.connect(func() -> void: add_relic_requested.emit())
	restart_btn.pressed.connect(func() -> void: restart_requested.emit())
	battle_btn.pressed.connect(func() -> void: battle_requested.emit())
	compendium_btn.pressed.connect(func() -> void: compendium_requested.emit())
	
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
	var header_content: PanelContainer = get_node_or_null("VBox/HeaderContent") as PanelContainer
	if not header_content:
		return
		
	# 1. Apply background shader to HeaderContent instead of root
	var panel_mat: ShaderMaterial = ShaderMaterial.new()
	panel_mat.shader = load("res://src/shared/shaders/shop_header_bar_bg.gdshader")
	
	# Connect to resized of HeaderContent to update shader size uniform
	header_content.resized.connect(func() -> void:
		if panel_mat: panel_mat.set_shader_parameter("size", header_content.size)
	)
	
	# Force initial size update
	var initial_size: Vector2 = header_content.size if header_content.size != Vector2.ZERO else Vector2(1280, 40)
	panel_mat.set_shader_parameter("size", initial_size)
		
	header_content.material = panel_mat
	
	# 2. Transparent panel stylebox to let shader draw cleanly on HeaderContent
	var transparent_style: StyleBoxFlat = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	header_content.add_theme_stylebox_override("panel", transparent_style)
