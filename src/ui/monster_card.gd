class_name MonsterCard
extends PanelContainer

@export var monster_instance: MonsterInstance:
	set(val):
		monster_instance = val
		if is_inside_tree():
			update_ui()

func _ready() -> void:
	var border_rect = get_node_or_null("BorderRect")
	if not border_rect:
		border_rect = ColorRect.new()
		border_rect.name = "BorderRect"
		border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border_rect.layout_mode = 1
		border_rect.anchors_preset = Control.PRESET_FULL_RECT
		border_rect.offset_left = 0
		border_rect.offset_top = 0
		border_rect.offset_right = 0
		border_rect.offset_bottom = 0
		
		var shader = load("res://src/ui/slot_border.gdshader")
		var shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		border_rect.material = shader_material
		
		add_child(border_rect)
		move_child(border_rect, 0) # Draw behind other children (like labels and sprite)
		
	# Connect resized signal to keep shader size updated
	resized.connect(func():
		if border_rect and border_rect.material:
			border_rect.material.set_shader_parameter("size", size)
	)
	
	update_ui()

func update_ui() -> void:
	if not monster_instance:
		return
	
	%AttackLabel.text = str(monster_instance.get_attack())
	%HealthLabel.text = str(monster_instance.current_health)
	%PoisonLabel.text = str(monster_instance.poison)
	
	# Border color represents rarity
	var border_color = Color(0.4, 0.45, 0.5, 1.0) # Default gray
	if monster_instance.data and monster_instance.data.rarity:
		border_color = monster_instance.data.rarity.border_color
		
	# Card body color is clean flat white/light gray (Batamon style)
	var body_color = Color(0.98, 0.98, 0.98, 1.0)
		
	# Soft shadow style for the card container (with transparent center)
	var shadow_style: StyleBoxFlat = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0) # Completely transparent bg
	shadow_style.draw_center = false
	shadow_style.corner_radius_top_left = 8
	shadow_style.corner_radius_top_right = 8
	shadow_style.corner_radius_bottom_right = 8
	shadow_style.corner_radius_bottom_left = 8
	
	# Premium soft drop shadow
	shadow_style.shadow_color = Color(0, 0, 0, 0.15) # Softer shadow for light card
	shadow_style.shadow_size = 4
	shadow_style.shadow_offset = Vector2(0, 3)
	
	shadow_style.content_margin_left = 0
	shadow_style.content_margin_right = 0
	shadow_style.content_margin_top = 0
	shadow_style.content_margin_bottom = 0
	
	add_theme_stylebox_override("panel", shadow_style)
	
	# Configure the pixel-art border shader on the card
	var border_rect = get_node_or_null("BorderRect")
	if border_rect and border_rect.material:
		var mat = border_rect.material as ShaderMaterial
		mat.set_shader_parameter("size", size if size != Vector2.ZERO else custom_minimum_size)
		mat.set_shader_parameter("outer_border_color", border_color) # Outer border represents rarity!
		mat.set_shader_parameter("interior_color", body_color) # Solid background color for the card!

	# Determine stats block size dynamically to prevent stretching the card
	var has_poison = monster_instance.poison > 0
	var stat_width = 28 if has_poison else 32
	var stat_size = Vector2(stat_width, 16)

	# Style Stats Panels using the custom pixel-art shader
	setup_stat_panel_shader(%AttackPanel, Color(0.92, 0.22, 0.38, 1.0), stat_size) # Pink/Red
	
	# Style Poison Panel (only visible if poison > 0)
	if monster_instance.poison > 0:
		%PoisonPanel.visible = true
		setup_stat_panel_shader(%PoisonPanel, Color(0.55, 0.27, 0.77, 1.0), stat_size) # Violet/Purple
	else:
		%PoisonPanel.visible = false
	
	# Style Health Panel (Orange/Peach)
	setup_stat_panel_shader(%HealthPanel, Color(0.93, 0.50, 0.17, 1.0), stat_size) # Orange
	
	# Handle sprite texture or text fallback representation
	if monster_instance.data and monster_instance.data.sprite:
		%SpriteRect.visible = true
		%PortraitCharLabel.visible = false
		%SpriteRect.texture = monster_instance.data.sprite
		
		# Assign chroma-key shader material if not already present
		if not %SpriteRect.material:
			var shader = load("res://src/ui/chroma_key.gdshader")
			var mat = ShaderMaterial.new()
			mat.shader = shader
			%SpriteRect.material = mat
	else:
		%SpriteRect.visible = false
		%PortraitCharLabel.visible = true
		
		# Display initial character / icon on portrait (using dark color for light background)
		if monster_instance.data and not monster_instance.get_monster_name().is_empty():
			%PortraitCharLabel.text = monster_instance.get_monster_name().left(1).to_upper()
			%PortraitCharLabel.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 0.75))
		else:
			%PortraitCharLabel.text = "?"
			%PortraitCharLabel.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 0.75))

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Create a visual preview of what we are dragging
	var preview_scene = load("res://src/ui/monster_card.tscn")
	var preview = preview_scene.instantiate()
	preview.monster_instance = monster_instance
	preview.custom_minimum_size = custom_minimum_size
	
	# Semitransparent preview
	preview.modulate.a = 0.7
	set_drag_preview(preview)
	
	# Return data containing this node and its origin
	return {
		"card": self,
		"original_slot": get_parent()
	}

func setup_stat_panel_shader(panel: PanelContainer, bg_color: Color, stat_size: Vector2) -> void:
	# Set the custom minimum size dynamically to prevent stretching
	panel.custom_minimum_size = stat_size

	# Ensure StyleBoxEmpty is set so PanelContainer background is transparent
	var empty_style = StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", empty_style)
	
	# Get or create BorderRect
	var border_rect = panel.get_node_or_null("BorderRect")
	if not border_rect:
		border_rect = ColorRect.new()
		border_rect.name = "BorderRect"
		border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border_rect.layout_mode = 1
		border_rect.anchors_preset = Control.PRESET_FULL_RECT
		border_rect.offset_left = 0
		border_rect.offset_top = 0
		border_rect.offset_right = 0
		border_rect.offset_bottom = 0
		
		var shader = load("res://src/ui/stat_border.gdshader")
		var shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		border_rect.material = shader_material
		
		panel.add_child(border_rect)
		panel.move_child(border_rect, 0) # Draw behind the wrapper/label
		
		# Connect resized signal
		panel.resized.connect(func():
			if border_rect and border_rect.material:
				border_rect.material.set_shader_parameter("size", panel.size)
		)
		
	# Configure shader material
	if border_rect.material:
		var mat = border_rect.material as ShaderMaterial
		mat.set_shader_parameter("size", panel.size if panel.size != Vector2.ZERO else panel.custom_minimum_size)
		mat.set_shader_parameter("border_width", 1.0) # 1 virtual pixel (2 screen pixels) border
		mat.set_shader_parameter("corner_radius", 2.0) # 2 virtual pixels corner radius (rounded)
		mat.set_shader_parameter("pixel_scale", 2.0)
		mat.set_shader_parameter("border_color", Color(0.12, 0.12, 0.13, 1.0)) # Dark border
		mat.set_shader_parameter("bg_color", bg_color) # Background color
