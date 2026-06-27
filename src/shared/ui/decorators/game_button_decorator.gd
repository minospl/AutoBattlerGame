class_name GameButtonDecorator
extends Node

@export var outer_width: int = 2
@export var inner_width: int = 1
@export var indentation: int = 1

@export var margin_left: int = 12
@export var margin_right: int = 12
@export var margin_top: int = 6
@export var margin_bottom: int = 6

@export var color_normal: Color = Color(0.15, 0.50, 0.30, 1.0) # BTN_GREEN_NORMAL
@export var color_hover: Color = Color(0.18, 0.60, 0.36, 1.0) # BTN_GREEN_HOVER
@export var color_pressed: Color = Color(0.12, 0.40, 0.24, 1.0) # BTN_GREEN_PRESSED

@export var color_outer_border: Color = Color(0.29, 0.251, 0.255, 1.0) # PANEL_BORDER_DEFAULT
@export var color_inner_border: Color = Color(1.0, 1.0, 1.0, 1.0) # WHITE

var parent_button: Button
var border_rect: ColorRect
var mat: ShaderMaterial

var normal_color: Color
var hover_color: Color
var pressed_color: Color
var outer_border_color: Color
var inner_border_color: Color

func _ready() -> void:
	parent_button = get_parent() as Button
	if not parent_button:
		push_error("GameButtonDecorator musi być bezpośrednim dzieckiem węzła typu Button!")
		return
		
	# Wymuszenie poziomego centrowania tekstu przycisku
	parent_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		
	# 1. Przezroczyste styleboxy przycisku z odpowiednimi marginesami
	var transparent_style: StyleBoxFlat = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	transparent_style.content_margin_left = margin_left
	transparent_style.content_margin_right = margin_right
	transparent_style.content_margin_top = margin_top
	transparent_style.content_margin_bottom = margin_bottom
	
	parent_button.add_theme_stylebox_override("normal", transparent_style)
	parent_button.add_theme_stylebox_override("hover", transparent_style)
	parent_button.add_theme_stylebox_override("pressed", transparent_style)
	parent_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# Określenie kolorów na bazie eksportowanych zmiennych
	outer_border_color = color_outer_border
	inner_border_color = color_inner_border
	normal_color = color_normal
	hover_color = color_hover
	pressed_color = color_pressed
			
	# 2. Tworzenie ColorRect z shaderem double_border
	border_rect = ColorRect.new()
	border_rect.name = "ButtonBorderShader"
	border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_rect.anchors_preset = Control.PRESET_FULL_RECT
	
	mat = ShaderMaterial.new()
	mat.shader = load("res://src/shared/shaders/double_border.gdshader")
	mat.set_shader_parameter("outer_border_color", outer_border_color)
	mat.set_shader_parameter("inner_border_color", inner_border_color)
	mat.set_shader_parameter("outer_border_width", outer_width)
	mat.set_shader_parameter("outer_border_indentation", indentation)
	mat.set_shader_parameter("inner_border_width", inner_width)
	mat.set_shader_parameter("inner_border_indentation", indentation)
	mat.set_shader_parameter("corner_color", GameColors.TRANSPARENT)
	
	# Początkowy stan tła (normal)
	mat.set_shader_parameter("interior_color", normal_color)
	border_rect.material = mat
	
	# Podpięcie zmiany rozmiaru samej ramki (która automatycznie śledzi rodzica dzięki kotwicom)
	border_rect.resized.connect(func() -> void:
		if mat:
			mat.set_shader_parameter("size", border_rect.size)
	)
	
	# 3. Podpięcie sygnałów interakcji do zmiany stanu shadera
	parent_button.mouse_entered.connect(_on_hover)
	parent_button.mouse_exited.connect(_on_normal)
	parent_button.button_down.connect(_on_pressed)
	parent_button.button_up.connect(func() -> void:
		if parent_button.get_global_rect().has_point(parent_button.get_global_mouse_position()):
			_on_hover()
		else:
			_on_normal()
	)
	
	# Odroczenie dodania ColorRect na spód, aby nie zasłaniał tekstu przycisku
	call_deferred("_deferred_setup")

func _deferred_setup() -> void:
	if not parent_button:
		return
	parent_button.add_child(border_rect)
	parent_button.move_child(border_rect, 0)
	
	# Ustawienie kotwic i reset marginesów po dodaniu do drzewa rodzica (Button)
	border_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	border_rect.offset_left = 0
	border_rect.offset_top = 0
	border_rect.offset_right = 0
	border_rect.offset_bottom = 0
	border_rect.show_behind_parent = true
	
	if mat:
		mat.set_shader_parameter("size", border_rect.size if border_rect.size != Vector2.ZERO else parent_button.size)
		
	# Upewnienie się, że inne elementy potomne (np. RichTextLabel z tekstem) nie przechwytują myszy
	for child: Node in parent_button.get_children():
		if child is Control and child != border_rect:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_normal() -> void:
	if mat:
		mat.set_shader_parameter("interior_color", normal_color)

func _on_hover() -> void:
	if mat:
		mat.set_shader_parameter("interior_color", hover_color)

func _on_pressed() -> void:
	if mat:
		mat.set_shader_parameter("interior_color", pressed_color)
