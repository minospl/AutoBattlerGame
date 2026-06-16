class_name TeamPanel
extends PanelContainer

signal slot_changed(slot: MonsterSlot)

@onready var frontline_hbox: HBoxContainer = %FrontlineHBox
@onready var backline_hbox: HBoxContainer = %BacklineHBox
@onready var team_header: PanelContainer = %TeamHeader
@onready var team_label: Label = %TeamLabel

var slots: Array[MonsterSlot] = []

func _ready() -> void:
	# Team Section Container Style (Transparent base panel to allow corners to be cut out cleanly)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = GameColors.TRANSPARENT
	add_theme_stylebox_override("panel", bg_style)
	
	var border_shader = load("res://src/shared/shaders/double_border.gdshader")
	
	# 1. Background Rect (draws solid white with cut corners, placed at the bottom)
	var bg_rect = ColorRect.new()
	bg_rect.name = "BackgroundRect"
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_rect.layout_mode = 1
	bg_rect.anchors_preset = Control.PRESET_FULL_RECT
	bg_rect.offset_left = 0
	bg_rect.offset_top = 0
	bg_rect.offset_right = 0
	bg_rect.offset_bottom = 0
	
	var bg_mat = ShaderMaterial.new()
	bg_mat.shader = load("res://src/shared/shaders/single_border.gdshader")
	bg_mat.set_shader_parameter("border_color", GameColors.WHITE_COLOR)
	bg_mat.set_shader_parameter("border_width", 3)
	bg_mat.set_shader_parameter("border_indentation", 3)
	bg_mat.set_shader_parameter("interior_color", GameColors.WHITE_COLOR)
	bg_mat.set_shader_parameter("corner_color", GameColors.TRANSPARENT)
	bg_rect.material = bg_mat
	
	add_child(bg_rect)
	move_child(bg_rect, 0)
	
	bg_rect.resized.connect(func():
		if bg_rect.material:
			bg_rect.material.set_shader_parameter("size", bg_rect.size)
	)
	
	# 2. Border Rect (draws only the borders, placed at the top to overlay headers/slots)
	var border_rect = ColorRect.new()
	border_rect.name = "BorderRect"
	border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_rect.layout_mode = 1
	border_rect.anchors_preset = Control.PRESET_FULL_RECT
	border_rect.offset_left = 0
	border_rect.offset_top = 0
	border_rect.offset_right = 0
	border_rect.offset_bottom = 0
	
	var border_mat = ShaderMaterial.new()
	border_mat.shader = border_shader
	border_mat.set_shader_parameter("outer_border_color", GameColors.PANEL_BORDER_DEFAULT)
	border_mat.set_shader_parameter("inner_border_color", GameColors.WHITE_COLOR)
	border_mat.set_shader_parameter("inner_border_width", 3)
	border_mat.set_shader_parameter("inner_border_indentation", 3)
	border_mat.set_shader_parameter("interior_color", GameColors.TRANSPARENT)
	border_mat.set_shader_parameter("corner_color", GameColors.TRANSPARENT)
	border_rect.material = border_mat
	
	add_child(border_rect)
	# Drawn last (no move_child to 0) to overlay header/content corners
	
	border_rect.resized.connect(func():
		if border_rect.material:
			border_rect.material.set_shader_parameter("size", border_rect.size)
	)
	
	# Force initial sizes
	var initial_size = size if size != Vector2.ZERO else custom_minimum_size
	if bg_rect.material:
		bg_rect.material.set_shader_parameter("size", initial_size)
	if border_rect.material:
		border_rect.material.set_shader_parameter("size", initial_size)
	
	var team_header_style = StyleBoxFlat.new()
	var team_color = GameColors.TEAM_HEADER_BG
	team_header_style.bg_color = team_color
	team_header_style.border_width_bottom = 3
	team_header_style.border_color = team_color.lightened(0.5)
	team_header_style.content_margin_bottom = 2
	team_header_style.content_margin_left = 2
	team_header.add_theme_stylebox_override("panel", team_header_style)
	
	# Label outline styling
	team_label.add_theme_color_override("font_outline_color", GameColors.LABEL_OUTLINE)
	team_label.add_theme_constant_override("outline_size", 5)

func create_slots(slot_scene: PackedScene, slot_count: int) -> void:
	for child in frontline_hbox.get_children():
		child.queue_free()
	for child in backline_hbox.get_children():
		child.queue_free()
	slots.clear()
	
	for i in range(slot_count):
		var slot = slot_scene.instantiate() as MonsterSlot
		slot.is_active_team = true
		slot.slot_index = i
		slot.slot_changed.connect(func(_slot): slot_changed.emit(_slot))
		
		if i < 3:
			backline_hbox.add_child(slot) # Slots 0, 1, 2 are backline
		else:
			frontline_hbox.add_child(slot) # Slots 3, 4, 5 are frontline
			
		slots.append(slot)
