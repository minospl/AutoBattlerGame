class_name MonsterCard
extends PanelContainer

@export var price: int = 3

@export var monster_instance: MonsterInstance:
	set(val):
		monster_instance = val
		if monster_instance and monster_instance.data:
			price = monster_instance.data.price
		if is_inside_tree():
			update_ui()

func _ready() -> void:
	var border_rect = get_node_or_null("BorderRect")
	var is_new = false
	if not border_rect:
		is_new = true
		border_rect = ColorRect.new()
		border_rect.name = "BorderRect"
		border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border_rect.anchors_preset = Control.PRESET_FULL_RECT
		border_rect.offset_left = 0
		border_rect.offset_top = 0
		border_rect.offset_right = 0
		border_rect.offset_bottom = 0
		
		var shader = load("res://src/shared/shaders/double_border.gdshader")
		var shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		border_rect.material = shader_material
		
	# Connect resized signal to keep shader size updated
	border_rect.resized.connect(func():
		if border_rect.material:
			border_rect.material.set_shader_parameter("size", border_rect.size)
	)
	
	if is_new:
		add_child(border_rect)
		move_child(border_rect, 0) # Draw behind other children (like labels and sprite)
		
	if border_rect.material:
		var initial_size = border_rect.size if border_rect.size != Vector2.ZERO else (size if size != Vector2.ZERO else custom_minimum_size)
		border_rect.material.set_shader_parameter("size", initial_size)
	
	update_ui()

func update_ui() -> void:
	if not monster_instance:
		return
	
	%AttackLabel.text = str(monster_instance.get_attack())
	%PoisonLabel.text = str(monster_instance.poison)
		
	# Empty style for the card container to prevent drawing any default panel background or shadow
	var card_style = StyleBoxEmpty.new()
	card_style.content_margin_left = 0
	card_style.content_margin_right = 0
	card_style.content_margin_top = 0
	card_style.content_margin_bottom = 0
	
	add_theme_stylebox_override("panel", card_style)
	
	# Configure the pixel-art border shader on the card
	var border_rect = get_node_or_null("BorderRect")
	if border_rect and border_rect.material:
		var mat = border_rect.material as ShaderMaterial
		mat.set_shader_parameter("size", size if size != Vector2.ZERO else custom_minimum_size)
		mat.set_shader_parameter("outer_border_width", 3)
		mat.set_shader_parameter("inner_border_width", 3)
		mat.set_shader_parameter("outer_border_color", monster_instance.data.rarity.border_color) # Outer border represents rarity!
		mat.set_shader_parameter("interior_color", GameColors.WHITE_COLOR) # Solid background color for the card!
		mat.set_shader_parameter("corner_color", GameColors.TRANSPARENT) # Transparent color for the corner

	# Set stats block size to a clean, constant 32px width
	var stat_size = Vector2(32, 16)

	# Style Stats Panels using the custom pixel-art shader
	
	if monster_instance.current_attack > 0:
		%AttackPanel.visible = true
		setup_stat_panel_shader(%AttackPanel, GameColors.STAT_ATTACK_BG, stat_size) # Pink/Red
	else:
		%AttackPanel.visible = false
	
	# Style Poison Panel (only visible if poison > 0)
	if monster_instance.poison > 0:
		%PoisonPanel.visible = true
		setup_stat_panel_shader(%PoisonPanel, GameColors.STAT_POISON_BG, stat_size) # Violet/Purple
	else:
		%PoisonPanel.visible = false
	
	# Handle sprite texture or text fallback representation
	if monster_instance.data and monster_instance.data.sprite:
		%SpriteRect.visible = true
		%PortraitCharLabel.visible = false
		%SpriteRect.texture = monster_instance.data.sprite
		
		# Assign chroma-key shader material if not already present
		if not %SpriteRect.material:
			var shader = load("res://src/shared/shaders/chroma_key.gdshader")
			var mat = ShaderMaterial.new()
			mat.shader = shader
			%SpriteRect.material = mat
	else:
		%SpriteRect.visible = false
		%PortraitCharLabel.visible = true
		
		# Display initial character / icon on portrait (using dark color for light background)
		if monster_instance.data and not monster_instance.get_monster_name().is_empty():
			%PortraitCharLabel.text = monster_instance.get_monster_name().left(1).to_upper()
			%PortraitCharLabel.add_theme_color_override("font_color", GameColors.PORTRAIT_FALLBACK_TEXT)
		else:
			%PortraitCharLabel.text = "?"
			%PortraitCharLabel.add_theme_color_override("font_color", GameColors.PORTRAIT_FALLBACK_TEXT)

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Create a visual preview of what we are dragging
	var preview_scene = load("res://src/shared/components/monster_card.tscn")
	var preview = preview_scene.instantiate()
	preview.monster_instance = monster_instance
	preview.custom_minimum_size = custom_minimum_size
	
	# Semitransparent preview
	preview.modulate.a = 0.7
	
	# Create a wrapper control to center the preview under the mouse cursor
	var preview_wrapper = Control.new()
	preview_wrapper.add_child(preview)
	preview.position = -custom_minimum_size / 2.0
	
	set_drag_preview(preview_wrapper)
	
	# Find original MonsterSlot ancestor
	var original_slot = get_parent()
	while original_slot and not original_slot.has_method("add_card"):
		original_slot = original_slot.get_parent()
		
	# Temporarily remove the card from the original slot (deferred to avoid event propagation issues)
	if original_slot:
		original_slot.remove_card.call_deferred(self)
		original_slot.slot_changed.emit.call_deferred(original_slot)
		
	# Notify ShopScene about the drag starting
	var shop_scene = get_tree().current_scene
	if shop_scene and shop_scene.has_method("notify_drag_started"):
		shop_scene.notify_drag_started(self, original_slot)
		
	var viewport = get_viewport()
	# Connect to the preview wrapper's tree_exiting signal (which runs when the drag session ends)
	preview_wrapper.tree_exiting.connect(func():
		# If the drag was not successful, return the card to its original slot
		if viewport and not viewport.gui_is_drag_successful():
			if original_slot:
				original_slot.add_card(self)
				original_slot.slot_changed.emit(original_slot)
	)
	
	# Return data containing this node and its origin
	return {
		"card": self,
		"original_slot": original_slot
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
		border_rect.anchors_preset = Control.PRESET_FULL_RECT
		border_rect.offset_left = 0
		border_rect.offset_top = 0
		border_rect.offset_right = 0
		border_rect.offset_bottom = 0
		
		var shader = load("res://src/shared/shaders/single_border.gdshader")
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
		mat.set_shader_parameter("border_width", 2)
		mat.set_shader_parameter("border_indentation", 1)
		mat.set_shader_parameter("border_color", bg_color.lightened(.2)) # Dark border
		mat.set_shader_parameter("interior_color", bg_color) # Background color
		mat.set_shader_parameter("corner_color", GameColors.TRANSPARENT) # Transparent corners
