class_name PanelHeaderDecorator
extends Node

# Umożliwia łatwą konfigurację tła nagłówka bezpośrednio w Inspektorze Godota
@export var header_color: Color = Color(0.2, 0.55, 0.85, 1.0) # Domyślnie niebieski dla Shop
@export var border_width_bottom: int = 3
@export var outline_size: int = 5

func _ready() -> void:
	var parent = get_parent()
	if not parent or not (parent is PanelContainer):
		push_error("PanelHeaderDecorator musi być bezpośrednim dzieckiem PanelContainer!")
		return
		
	# 1. Tworzenie i przypisanie stylu tła nagłówka
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = header_color
	header_style.border_width_bottom = border_width_bottom
	header_style.border_color = header_color.lightened(0.5)
	header_style.content_margin_bottom = 2
	header_style.content_margin_left = 2
	parent.add_theme_stylebox_override("panel", header_style)
	
	# 2. Automatyczna konfiguracja obrysu napisów (Label) wewnątrz nagłówka
	_apply_label_styles(parent)

func _apply_label_styles(node: Node) -> void:
	if node is Label:
		node.add_theme_color_override("font_outline_color", GameColors.LABEL_OUTLINE)
		node.add_theme_constant_override("outline_size", outline_size)
	
	# Rekurencyjne przeszukanie dzieci (np. w HBox, MarginContainer itp.)
	for child in node.get_children():
		_apply_label_styles(child)
