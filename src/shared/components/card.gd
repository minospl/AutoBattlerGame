class_name Card
extends PanelContainer

@export var price: int

@export var unit_instance: UnitInstance:
	set(val):
		unit_instance = val
		if unit_instance and unit_instance.data:
			price = unit_instance.data.price
		if is_inside_tree():
			update_ui()

func _ready() -> void:
	update_ui()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	tree_exiting.connect(_on_mouse_exited)

func update_ui() -> void:
	if not unit_instance:
		return
	
	%AttackLabel.text = str(unit_instance.get_attack())
	%PoisonLabel.text = str(unit_instance.poison)
	
	# Configure the pixel-art border shader on the card
	var border_rect = get_node_or_null("BorderRect") as ShaderBorderDecorator
	if border_rect:
		border_rect.border_color = unit_instance.data.rarity.border_color if (unit_instance.data and unit_instance.data.rarity) else GameColors.BORDER_OUTER_DEFAULT
		border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
		border_rect.interior_color = GameColors.WHITE_COLOR
		border_rect.update_shader_parameters()

	# Set stats block size to a clean, constant 32px width
	var stat_size = Vector2(32, 16)

	# Style Stats Panels using the custom pixel-art shader
	if unit_instance.current_attack > 0:
		%AttackPanel.visible = true
		setup_stat_panel_shader(%AttackPanel, GameColors.STAT_ATTACK_BG, stat_size) # Pink/Red
	else:
		%AttackPanel.visible = false
	
	# Style Poison Panel (only visible if poison > 0)
	if unit_instance.poison > 0:
		%PoisonPanel.visible = true
		setup_stat_panel_shader(%PoisonPanel, GameColors.STAT_POISON_BG, stat_size) # Violet/Purple
	else:
		%PoisonPanel.visible = false
	
	# Handle sprite texture or text fallback representation
	if unit_instance.data and unit_instance.data.sprite:
		%SpriteRect.visible = true
		%PortraitCharLabel.visible = false
		%SpriteRect.texture = unit_instance.data.sprite
		
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
		if unit_instance.data and not unit_instance.get_unit_name().is_empty():
			%PortraitCharLabel.text = unit_instance.get_unit_name().left(1).to_upper()
			%PortraitCharLabel.add_theme_color_override("font_color", GameColors.PORTRAIT_FALLBACK_TEXT)
		else:
			%PortraitCharLabel.text = "?"
			%PortraitCharLabel.add_theme_color_override("font_color", GameColors.PORTRAIT_FALLBACK_TEXT)

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Create a visual preview of what we are dragging
	var preview_scene = load("res://src/shared/components/card.tscn")
	var preview = preview_scene.instantiate()
	preview.unit_instance = unit_instance
	preview.custom_minimum_size = custom_minimum_size
	
	# Semitransparent preview
	preview.modulate.a = 0.7
	
	# Create a wrapper control to center the preview under the mouse cursor
	var preview_wrapper = Control.new()
	preview_wrapper.add_child(preview)
	preview.position = -custom_minimum_size / 2.0
	
	set_drag_preview(preview_wrapper)
	
	# Find original CardSlot ancestor
	var original_slot = get_parent()
	while original_slot and not original_slot.has_method("add_card"):
		original_slot = original_slot.get_parent()
		
	# Temporarily remove the card from the original slot (deferred to avoid event propagation issues)
	if original_slot:
		original_slot.remove_card.call_deferred(self)
		original_slot.slot_changed.emit.call_deferred(original_slot)
		
	# Notify about the drag starting using DragManager
	DragManager.notify_drag_started(self, original_slot)
		
	var viewport = get_viewport()
	# Connect to the preview wrapper's tree_exiting signal (which runs when the drag session ends)
	preview_wrapper.tree_exiting.connect(func():
		# If the drag was not successful, return the card to its original slot
		if viewport and not viewport.gui_is_drag_successful():
			if original_slot:
				original_slot.add_card(self)
				original_slot.slot_changed.emit(original_slot)
		DragManager.notify_drag_ended()
	)
	
	# Return data containing this node and its origin
	return {
		"card": self,
		"original_slot": original_slot
	}

func setup_stat_panel_shader(panel: PanelContainer, bg_color: Color, stat_size: Vector2) -> void:
	panel.custom_minimum_size = stat_size
	
	var border_rect = panel.get_node_or_null("BorderRect") as ShaderBorderDecorator
	if border_rect:
		border_rect.border_color = bg_color.lightened(.2)
		border_rect.interior_color = bg_color
		border_rect.update_shader_parameters()

func set_highlight(active: bool) -> void:
	var border_rect = get_node_or_null("BorderRect") as ShaderBorderDecorator
	if border_rect:
		if active:
			border_rect.border_color = GameColors.SLOT_HOVER_OUTER_BORDER
			border_rect.inner_border_color = GameColors.SLOT_HOVER_INNER_BORDER
		else:
			var rarity_color = unit_instance.data.rarity.border_color if (unit_instance and unit_instance.data and unit_instance.data.rarity) else GameColors.BORDER_OUTER_DEFAULT
			border_rect.border_color = rarity_color
			border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
		border_rect.update_shader_parameters()

func _on_mouse_entered() -> void:
	if DragManager.dragged_card:
		return
	var shop_scene = get_tree().current_scene
	if shop_scene and shop_scene.has_method("set_preview_card"):
		shop_scene.set_preview_card(self)

func _on_mouse_exited() -> void:
	var shop_scene = get_tree().current_scene
	if shop_scene and shop_scene.has_method("clear_preview_card"):
		shop_scene.clear_preview_card()
