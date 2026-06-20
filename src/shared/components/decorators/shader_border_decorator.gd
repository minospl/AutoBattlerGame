class_name ShaderBorderDecorator
extends ColorRect

enum BorderType { SINGLE, DOUBLE }

@export var border_type: BorderType = BorderType.DOUBLE
@export var border_color: Color = Color(0.29, 0.251, 0.255, 1.0) # GameColors.PANEL_BORDER_DEFAULT
@export var inner_border_color: Color = Color(1.0, 1.0, 1.0, 1.0) # GameColors.WHITE_COLOR
@export var interior_color: Color = Color(0, 0, 0, 0)
@export var outer_border_width: int = 3
@export var inner_border_width: int = 3
@export var border_indentation: int = 0
@export var corner_color: Color = Color(0, 0, 0, 0) # GameColors.TRANSPARENT

func _ready() -> void:
	var parent = get_parent()
	if parent and parent is Control:
		# Make parent panel background stylebox transparent
		var empty_style = StyleBoxEmpty.new()
		parent.add_theme_stylebox_override("panel", empty_style)
		
		# Set full rect anchors
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		anchors_preset = Control.PRESET_FULL_RECT
		offset_left = 0
		offset_top = 0
		offset_right = 0
		offset_bottom = 0
		
		# Load the proper shader
		var shader
		if border_type == BorderType.SINGLE:
			shader = load("res://src/shared/shaders/single_border.gdshader")
		else:
			shader = load("res://src/shared/shaders/double_border.gdshader")
			
		var mat = ShaderMaterial.new()
		mat.shader = shader
		material = mat
		
		# Set parameters
		update_shader_parameters()
		
		# Connect resized signal to follow size changes dynamically
		resized.connect(func():
			if material:
				material.set_shader_parameter("size", size)
		)
		
		# Set initial size uniform
		call_deferred("_setup_initial_size")

func _setup_initial_size() -> void:
	if material:
		var parent = get_parent()
		var initial_size = size if size != Vector2.ZERO else (parent.size if parent.size != Vector2.ZERO else parent.custom_minimum_size)
		material.set_shader_parameter("size", initial_size)

func update_shader_parameters() -> void:
	if not material:
		return
	var mat = material as ShaderMaterial
	if border_type == BorderType.SINGLE:
		mat.set_shader_parameter("border_color", border_color)
		mat.set_shader_parameter("border_width", outer_border_width)
		mat.set_shader_parameter("border_indentation", border_indentation)
		mat.set_shader_parameter("interior_color", interior_color)
		mat.set_shader_parameter("corner_color", corner_color)
	else:
		mat.set_shader_parameter("outer_border_color", border_color)
		mat.set_shader_parameter("inner_border_color", inner_border_color)
		mat.set_shader_parameter("outer_border_width", outer_border_width)
		mat.set_shader_parameter("outer_border_indentation", border_indentation)
		mat.set_shader_parameter("inner_border_width", inner_border_width)
		mat.set_shader_parameter("inner_border_indentation", border_indentation)
		mat.set_shader_parameter("interior_color", interior_color)
		mat.set_shader_parameter("corner_color", corner_color)
