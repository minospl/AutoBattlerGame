class_name RelicBar
extends MarginContainer

var tooltip: CardTooltip = null
var icons_container: HBoxContainer = null

func setup(p_tooltip: CardTooltip) -> void:
	tooltip = p_tooltip
	
	# Setup margins directly on ourselves since we extend MarginContainer
	add_theme_constant_override("margin_left", 20)
	add_theme_constant_override("margin_right", 20)
	add_theme_constant_override("margin_top", 4)
	add_theme_constant_override("margin_bottom", 4)
	
	# Setup icons container (no prefix label!)
	icons_container = HBoxContainer.new()
	icons_container.add_theme_constant_override("separation", 6)
	icons_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(icons_container)
	
	# Initially hide since there are no relics
	visible = false

func update_relics(relic_list: Array[RelicInstance]) -> void:
	# Clear old icons
	for child: Node in icons_container.get_children():
		child.queue_free()
		
	var active_count: int = 0
	for relic: RelicInstance in relic_list:
		if relic:
			active_count += 1
			var icon: Control = _create_relic_icon(relic)
			icons_container.add_child(icon)
			
	# Only show the bar if we have active relics
	visible = active_count > 0

func _create_relic_icon(relic: RelicInstance) -> Control:
	var container: Control = Control.new()
	container.custom_minimum_size = Vector2(28, 28)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var relic_data: RelicData = relic.data
	
	# Icon inside
	if relic_data and relic_data.sprite:
		var tex: TextureRect = TextureRect.new()
		tex.texture = relic_data.sprite
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex.custom_minimum_size = Vector2(24, 24)
		tex.set_anchors_preset(Control.PRESET_CENTER)
		container.add_child(tex)
	else:
		var label: Label = Label.new()
		# Use chest icon as a default fallback
		label.text = "📦"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		container.add_child(label)
		
	# Stacks badge
	if relic.stacks > 1:
		var badge_control: Control = Control.new()
		badge_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(badge_control)
		
		var badge_label: Label = Label.new()
		badge_label.text = str(relic.stacks)
		badge_label.custom_minimum_size = Vector2(14, 14)
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_label.add_theme_font_size_override("font_size", 10)
		
		var badge_style: StyleBoxFlat = StyleBoxFlat.new()
		badge_style.bg_color = Color(0.12, 0.12, 0.14, 1.0) # Dark charcoal
		badge_style.corner_radius_top_left = 8
		badge_style.corner_radius_top_right = 8
		badge_style.corner_radius_bottom_left = 8
		badge_style.corner_radius_bottom_right = 8
		badge_label.add_theme_stylebox_override("normal", badge_style)
		
		# Position the badge in the bottom-right corner
		badge_label.position = Vector2(14, 14)
		badge_control.add_child(badge_label)
		
	# Hover/Tooltip logic
	container.mouse_entered.connect(func() -> void:
		if tooltip:
			CardUIHelper.show_relic_tooltip(tooltip, relic)
	)
	container.mouse_exited.connect(func() -> void:
		if tooltip:
			CardUIHelper.hide_tooltip(tooltip)
	)
	
	return container
