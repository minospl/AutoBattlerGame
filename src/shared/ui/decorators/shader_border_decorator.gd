class_name ShaderBorderDecorator
extends ColorRect

enum BorderType { SINGLE, DOUBLE }

@export var border_type: BorderType = BorderType.DOUBLE
@export var border_color: Color = GameColors.PANEL_BORDER_DEFAULT
@export var inner_border_color: Color = GameColors.BORDER_INNER_DEFAULT
@export var interior_color: Color = GameColors.TRANSPARENT
@export var outer_border_width: int = 3
@export var inner_border_width: int = 3
@export var border_indentation: int = 3
@export var corner_color: Color = GameColors.TRANSPARENT

var shader_material: ShaderMaterial

func _ready() -> void:
	var parent: Node = get_parent()
	if parent and parent is Control:
		# Make parent panel background stylebox transparent
		var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
		(parent as Control).add_theme_stylebox_override("panel", empty_style)
		
		# Set full rect anchors
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		anchors_preset = Control.PRESET_FULL_RECT
		offset_left = 0
		offset_top = 0
		offset_right = 0
		offset_bottom = 0
		
		# Load the proper shader
		var shader: Shader = null
		if border_type == BorderType.SINGLE:
			shader = load("res://src/shared/shaders/single_border.gdshader") as Shader
		else:
			shader = load("res://src/shared/shaders/double_border.gdshader") as Shader
			
		shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		material = shader_material
		
		# Set parameters
		update_shader_parameters()
		
		# Connect resized signal to follow size changes dynamically
		resized.connect(func() -> void:
			if shader_material:
				shader_material.set_shader_parameter("size", size)
		)
		
		# Set initial size uniform
		call_deferred("_setup_initial_size")

func _setup_initial_size() -> void:
	if shader_material:
		var parent: Node = get_parent()
		var parent_ctrl: Control = parent as Control
		var initial_size: Vector2 = size
		if initial_size == Vector2.ZERO and parent_ctrl:
			initial_size = parent_ctrl.size if parent_ctrl.size != Vector2.ZERO else parent_ctrl.custom_minimum_size
		shader_material.set_shader_parameter("size", initial_size)

func update_shader_parameters() -> void:
	if not shader_material:
		return
	if border_type == BorderType.SINGLE:
		shader_material.set_shader_parameter("border_color", border_color)
		shader_material.set_shader_parameter("border_width", outer_border_width)
		shader_material.set_shader_parameter("border_indentation", border_indentation)
		shader_material.set_shader_parameter("interior_color", interior_color)
		shader_material.set_shader_parameter("corner_color", corner_color)
	else:
		shader_material.set_shader_parameter("outer_border_color", border_color)
		shader_material.set_shader_parameter("inner_border_color", inner_border_color)
		shader_material.set_shader_parameter("outer_border_width", outer_border_width)
		shader_material.set_shader_parameter("outer_border_indentation", border_indentation)
		shader_material.set_shader_parameter("inner_border_width", inner_border_width)
		shader_material.set_shader_parameter("inner_border_indentation", border_indentation)
		shader_material.set_shader_parameter("interior_color", interior_color)
		shader_material.set_shader_parameter("corner_color", corner_color)
