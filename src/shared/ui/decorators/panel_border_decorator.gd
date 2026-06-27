class_name PanelBorderDecorator
extends Control

# Umożliwia łatwą konfigurację kolorów i grubości ramek bezpośrednio w Inspektorze Godota
@export var border_color: Color = Color(0.29, 0.251, 0.255, 1.0) # PANEL_BORDER_DEFAULT
@export var outer_width: int = 3
@export var inner_width: int = 3
@export var indentation: int = 3

var bg_rect: ColorRect
var border_rect: ColorRect

func _ready() -> void:
	var parent: Node = get_parent()
	if not parent or not (parent is Control):
		push_error("PanelBorderDecorator musi być dzieckiem węzła typu Control!")
		return
		
	# 1. Automatyczne uczynienie tła rodzica przezroczystym, aby ramka z shaderem przejęła rysowanie
	var transparent_style: StyleBoxFlat = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	(parent as Control).add_theme_stylebox_override("panel", transparent_style)
	
	# Wczytanie uniwersalnych shaderów
	var single_shader: Shader = load("res://src/shared/shaders/single_border.gdshader") as Shader
	var double_shader: Shader = load("res://src/shared/shaders/double_border.gdshader") as Shader
	
	# 2. Warstwa Tła (single_border, spód - indeks 0)
	bg_rect = ColorRect.new()
	bg_rect.name = "BackgroundRect"
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_rect.anchors_preset = Control.PRESET_FULL_RECT
	bg_rect.offset_left = 0
	bg_rect.offset_top = 0
	bg_rect.offset_right = 0
	bg_rect.offset_bottom = 0
	
	var bg_mat: ShaderMaterial = ShaderMaterial.new()
	bg_mat.shader = single_shader
	bg_mat.set_shader_parameter("border_color", GameColors.WHITE_COLOR)
	bg_mat.set_shader_parameter("border_width", outer_width)
	bg_mat.set_shader_parameter("border_indentation", indentation)
	bg_mat.set_shader_parameter("interior_color", GameColors.WHITE_COLOR)
	bg_mat.set_shader_parameter("corner_color", GameColors.TRANSPARENT)
	bg_rect.material = bg_mat
	
	# Po dodaniu do drzewa, automatycznie synchronizuj rozmiar shadera przy każdej zmianie wymiarów
	bg_rect.resized.connect(func() -> void:
		if bg_rect.material:
			bg_rect.material.set_shader_parameter("size", bg_rect.size)
	)
	
	# 3. Warstwa Ramek (double_border, wierzch - rysowana na końcu)
	border_rect = ColorRect.new()
	border_rect.name = "BorderRect"
	border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_rect.anchors_preset = Control.PRESET_FULL_RECT
	border_rect.offset_left = 0
	border_rect.offset_top = 0
	border_rect.offset_right = 0
	border_rect.offset_bottom = 0
	
	var border_mat: ShaderMaterial = ShaderMaterial.new()
	border_mat.shader = double_shader
	border_mat.set_shader_parameter("outer_border_color", border_color)
	border_mat.set_shader_parameter("inner_border_color", GameColors.WHITE_COLOR)
	border_mat.set_shader_parameter("outer_border_width", outer_width)
	border_mat.set_shader_parameter("outer_border_indentation", indentation)
	border_mat.set_shader_parameter("inner_border_width", inner_width)
	border_mat.set_shader_parameter("inner_border_indentation", indentation)
	border_mat.set_shader_parameter("interior_color", GameColors.TRANSPARENT)
	border_mat.set_shader_parameter("corner_color", GameColors.TRANSPARENT)
	border_rect.material = border_mat
	
	# Po dodaniu do drzewa, automatycznie synchronizuj rozmiar shadera przy każdej zmianie wymiarów
	border_rect.resized.connect(func() -> void:
		if border_rect.material:
			border_rect.material.set_shader_parameter("size", border_rect.size)
	)
	
	# Odroczenie podpięcia dzieci do rodzica, aby uniknąć błędów modyfikacji w trakcie _ready
	call_deferred("_deferred_setup")

func _deferred_setup() -> void:
	var parent: Node = get_parent()
	if not parent or not (parent is Control):
		return
		
	# Dodanie tła na sam spód
	parent.add_child(bg_rect)
	parent.move_child(bg_rect, 0)
	
	# Dodanie ramki na sam wierzch (rysowane jako ostatnie)
	parent.add_child(border_rect)
	
	# Wymuszenie początkowego rozmiaru z rodzica, na wypadek gdyby sygnał 'resized' nie wystrzelił od razu
	if bg_rect.material:
		bg_rect.material.set_shader_parameter("size", parent.size)
	if border_rect.material:
		border_rect.material.set_shader_parameter("size", parent.size)

func set_border_color(new_color: Color) -> void:
	border_color = new_color
	if border_rect and border_rect.material:
		border_rect.material.set_shader_parameter("outer_border_color", new_color)
