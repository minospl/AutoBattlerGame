class_name BenchPanel
extends PanelContainer

signal slot_changed(slot: MonsterSlot)

@onready var bench_hbox: HBoxContainer = %BenchHBox
@onready var bench_header: PanelContainer = %BenchHeader
@onready var bench_label: Label = %BenchLabel

var slots: Array[MonsterSlot] = []

func _ready() -> void:
	# Bench Section Container Style (White Box under everything)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(1.0, 1.0, 1.0, 1.0) # Solid white
	add_theme_stylebox_override("panel", bg_style)
	
	var bench_border = ColorRect.new()
	bench_border.name = "BorderRect"
	bench_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bench_border.layout_mode = 1
	bench_border.anchors_preset = Control.PRESET_FULL_RECT
	bench_border.offset_left = 0
	bench_border.offset_top = 0
	bench_border.offset_right = 0
	bench_border.offset_bottom = 0
	
	var border_shader = load("res://src/shared/shaders/single_border.gdshader")
	var border_color = Color(0.57, 0.58, 0.65, 1.0)
	
	var bench_mat = ShaderMaterial.new()
	bench_mat.shader = border_shader
	bench_mat.set_shader_parameter("border_color", border_color)
	bench_mat.set_shader_parameter("interior_color", Color(1.0, 1.0, 1.0, 0.0)) # Transparent interior
	bench_mat.set_shader_parameter("corner_color", Color(1.0, 1.0, 1.0, 1.0)) # Solid white corners to overlay top header corners
	
	bench_border.material = bench_mat
	bench_border.resized.connect(func():
		if bench_border.material:
			bench_border.material.set_shader_parameter("size", bench_border.size)
	)
	
	add_child(bench_border)
	# Drawn last (no move_child to 0) to overlay top header corners
	
	if bench_border.material:
		var initial_size = bench_border.size if bench_border.size != Vector2.ZERO else (size if size != Vector2.ZERO else custom_minimum_size)
		bench_border.material.set_shader_parameter("size", initial_size)
	
	# Bench Header Style (Yellow Banner)
	var bench_header_style = StyleBoxFlat.new()
	var bench_color = Color(0.95, 0.72, 0.18, 1.0) # Yellow (#f1b82d)
	bench_header_style.bg_color = bench_color
	bench_header_style.border_width_bottom = 3
	bench_header_style.border_color = bench_color.lightened(0.5) # Lighter yellow border
	bench_header_style.content_margin_bottom = 2
	bench_header_style.content_margin_left = 2
	bench_header.add_theme_stylebox_override("panel", bench_header_style)
	
	# Label outline styling
	var label_outline_color = Color(0.1, 0.1, 0.1, 1.0)
	bench_label.add_theme_color_override("font_outline_color", label_outline_color)
	bench_label.add_theme_constant_override("outline_size", 5)

func create_slots(slot_scene: PackedScene, slot_count: int) -> void:
	for child in bench_hbox.get_children():
		child.queue_free()
	slots.clear()
	
	for i in range(slot_count):
		var slot = slot_scene.instantiate() as MonsterSlot
		slot.is_active_team = false
		slot.slot_index = i
		slot.slot_changed.connect(func(_slot): slot_changed.emit(_slot))
		bench_hbox.add_child(slot)
		slots.append(slot)
