class_name TeamPanel
extends PanelContainer

signal slot_changed(slot: MonsterSlot)

@onready var frontline_hbox: HBoxContainer = %FrontlineHBox
@onready var backline_hbox: HBoxContainer = %BacklineHBox
@onready var team_header: PanelContainer = %TeamHeader
@onready var team_label: Label = %TeamLabel

var slots: Array[MonsterSlot] = []

func _ready() -> void:
	# Team Section Container Style (White Box under everything)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(1.0, 1.0, 1.0, 1.0) # Solid white
	add_theme_stylebox_override("panel", bg_style)
	
	var team_border = ColorRect.new()
	team_border.name = "BorderRect"
	team_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	team_border.layout_mode = 1
	team_border.anchors_preset = Control.PRESET_FULL_RECT
	team_border.offset_left = 0
	team_border.offset_top = 0
	team_border.offset_right = 0
	team_border.offset_bottom = 0
	
	var border_shader = load("res://src/shared/shaders/single_border.gdshader")
	var border_color = Color(0.57, 0.58, 0.65, 1.0)
	
	var team_mat = ShaderMaterial.new()
	team_mat.shader = border_shader
	team_mat.set_shader_parameter("border_color", border_color)
	team_mat.set_shader_parameter("interior_color", Color(1.0, 1.0, 1.0, 0.0)) # Transparent interior
	team_mat.set_shader_parameter("corner_color", Color(1.0, 1.0, 1.0, 1.0)) # Solid white corners to overlay top header corners
	
	team_border.material = team_mat
	team_border.resized.connect(func():
		if team_border.material:
			team_border.material.set_shader_parameter("size", team_border.size)
	)
	
	add_child(team_border)
	# Drawn last (no move_child to 0) to overlay top header corners
	
	if team_border.material:
		var initial_size = team_border.size if team_border.size != Vector2.ZERO else (size if size != Vector2.ZERO else custom_minimum_size)
		team_border.material.set_shader_parameter("size", initial_size)
	
	# Team Header Style (Pink Banner)
	var team_header_style = StyleBoxFlat.new()
	var team_color = Color(0.89, 0.31, 0.44, 1.0) # Pink (#e24f70)
	team_header_style.bg_color = team_color
	team_header_style.border_width_bottom = 3
	team_header_style.border_color = team_color.lightened(0.5) # Lighter pink border
	team_header_style.content_margin_bottom = 2
	team_header_style.content_margin_left = 2
	team_header.add_theme_stylebox_override("panel", team_header_style)
	
	# Label outline styling
	var label_outline_color = Color(0.1, 0.1, 0.1, 1.0)
	team_label.add_theme_color_override("font_outline_color", label_outline_color)
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
