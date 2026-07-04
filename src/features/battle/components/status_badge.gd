@tool
extends Control
class_name StatusBadge

const M5X7_FONT: Font = preload("res://src/assets/fonts/m5x7.ttf")

enum Type {
	POISON,
	BURN,
	ELECTROCUTE
}

@export var type: Type = Type.POISON:
	set(val):
		type = val
		if is_node_ready():
			queue_redraw()
			_update_styling()

@export var status_type: String = "poison":
	set(val):
		status_type = val
		match val:
			"poison": type = Type.POISON
			"burn": type = Type.BURN
			"electrocute": type = Type.ELECTROCUTE
		if is_node_ready():
			queue_redraw()
			_update_styling()

@export var value: int = 0:
	set(val):
		value = val
		if is_node_ready():
			if count_label:
				count_label.text = str(val)
			visible = val > 0

@export var cooldown_ratio: float = 0.0:
	set(val):
		cooldown_ratio = val
		if is_node_ready():
			if cooldown_fill:
				cooldown_fill.anchor_right = val
			if cooldown_bar:
				cooldown_bar.visible = (type == Type.POISON and val > 0.0)

var count_panel: PanelContainer
var count_label: Label
var cooldown_bar: Control
var cooldown_fill: ColorRect

func _ready() -> void:
	# Ensure custom size is set
	custom_minimum_size = Vector2(36.0, 36.0)
	
	count_panel = get_node_or_null("CountPanel") as PanelContainer
	if count_panel:
		count_label = count_panel.get_node_or_null("CountLabel") as Label
	else:
		# Create counter panel container at top-right
		count_panel = PanelContainer.new()
		count_panel.name = &"CountPanel"
		count_panel.custom_minimum_size = Vector2(16.0, 16.0)
		
		# Setup layout/anchors for count_panel (top right)
		count_panel.anchors_preset = PRESET_TOP_RIGHT
		count_panel.grow_horizontal = GROW_DIRECTION_BOTH
		count_panel.grow_vertical = GROW_DIRECTION_BOTH
		count_panel.offset_left = 20.0
		count_panel.offset_right = 38.0
		count_panel.offset_top = -6.0
		count_panel.offset_bottom = 10.0
		
		# Style the count panel
		var style_box: StyleBoxFlat = StyleBoxFlat.new()
		style_box.bg_color = Color(0.18, 0.18, 0.2, 1.0) # Dark charcoal background
		style_box.border_width_left = 1
		style_box.border_width_top = 1
		style_box.border_width_right = 1
		style_box.border_width_bottom = 1
		style_box.border_color = Color(0.1, 0.1, 0.1, 1.0) # Black border
		style_box.corner_radius_top_left = 3
		style_box.corner_radius_top_right = 3
		style_box.corner_radius_bottom_right = 3
		style_box.corner_radius_bottom_left = 3
		count_panel.add_theme_stylebox_override(&"panel", style_box)
		
		# Create label inside panel
		count_label = Label.new()
		count_label.name = &"CountLabel"
		count_label.text = str(value)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Font override
		if M5X7_FONT:
			count_label.add_theme_font_override(&"font", M5X7_FONT)
		count_label.add_theme_font_size_override(&"font_size", 12)
		count_label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0, 1.0))
		count_label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		count_label.add_theme_constant_override(&"outline_size", 3)
		
		count_panel.add_child(count_label)
		add_child(count_panel)
		
	cooldown_bar = get_node_or_null("CooldownBar") as Control
	if cooldown_bar:
		cooldown_fill = cooldown_bar.get_node_or_null("CooldownFill") as ColorRect
	else:
		# Create progress bar under badge for poison
		cooldown_bar = Control.new()
		cooldown_bar.name = &"CooldownBar"
		cooldown_bar.custom_minimum_size = Vector2(32.0, 4.0)
		cooldown_bar.anchors_preset = PRESET_BOTTOM_LEFT
		cooldown_bar.offset_left = 2.0
		cooldown_bar.offset_top = -6.0
		cooldown_bar.offset_right = 34.0
		cooldown_bar.offset_bottom = -2.0
		cooldown_bar.visible = (type == Type.POISON)
		
		var bar_bg: ColorRect = ColorRect.new()
		bar_bg.anchors_preset = PRESET_FULL_RECT
		bar_bg.color = Color(0.1, 0.1, 0.1, 0.5)
		cooldown_bar.add_child(bar_bg)
		
		cooldown_fill = ColorRect.new()
		cooldown_fill.name = &"CooldownFill"
		cooldown_fill.anchors_preset = PRESET_FULL_RECT
		cooldown_fill.anchor_right = cooldown_ratio
		cooldown_fill.color = Color(0.68, 0.28, 0.78, 0.85) # Purple fill
		cooldown_bar.add_child(cooldown_fill)
		
		add_child(cooldown_bar)
	
	_update_styling()
	# Set initial visibility based on stack value
	visible = value > 0

func _update_styling() -> void:
	if cooldown_bar:
		cooldown_bar.visible = (type == Type.POISON)

func _draw() -> void:
	var radius: float = 14.0
	var center: Vector2 = Vector2(18.0, 18.0)
	
	var bg_color: Color = Color()
	match type:
		Type.POISON:
			bg_color = Color(0.55, 0.27, 0.77, 1.0)
		Type.BURN:
			bg_color = Color(0.9, 0.4, 0.1, 1.0)
		Type.ELECTROCUTE:
			bg_color = Color(0.85, 0.75, 0.1, 1.0)
			
	# Draw white outer border circle
	draw_circle(center, radius + 2.0, Color(1, 1, 1, 1))
	# Draw colored background circle
	draw_circle(center, radius, bg_color)
	
	# Draw white silhouette vector icon in center
	var points: PackedVector2Array = PackedVector2Array()
	match type:
		Type.POISON:
			points = PackedVector2Array([
				center + Vector2(0.0, -9.0),
				center + Vector2(3.5, -4.0),
				center + Vector2(6.0, 0.0),
				center + Vector2(7.0, 3.5),
				center + Vector2(5.5, 7.0),
				center + Vector2(3.0, 8.5),
				center + Vector2(0.0, 9.0),
				center + Vector2(-3.0, 8.5),
				center + Vector2(-5.5, 7.0),
				center + Vector2(-7.0, 3.5),
				center + Vector2(-6.0, 0.0),
				center + Vector2(-3.5, -4.0)
			])
		Type.BURN:
			points = PackedVector2Array([
				center + Vector2(0.0, -10.0),
				center + Vector2(3.0, -5.0),
				center + Vector2(6.0, -1.0),
				center + Vector2(7.0, 4.0),
				center + Vector2(5.0, 8.0),
				center + Vector2(0.0, 9.0),
				center + Vector2(-5.0, 8.0),
				center + Vector2(-7.0, 4.0),
				center + Vector2(-6.0, -1.0),
				center + Vector2(-3.0, -5.0),
				center + Vector2(-1.5, -2.0),
				center + Vector2(0.0, -4.0),
				center + Vector2(1.5, -2.0)
			])
		Type.ELECTROCUTE:
			points = PackedVector2Array([
				center + Vector2(2.0, -9.0),
				center + Vector2(6.0, -9.0),
				center + Vector2(0.0, -1.0),
				center + Vector2(6.0, -1.0),
				center + Vector2(-4.0, 9.0),
				center + Vector2(0.0, 1.0),
				center + Vector2(-3.0, 1.0)
			])
			
	if points.size() > 0:
		draw_polygon(points, PackedColorArray([Color(1.0, 1.0, 1.0, 1.0)]))
