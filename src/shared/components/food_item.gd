class_name FoodItem
extends PanelContainer

@export var food_name: String = "Apple"
@export var stat_boost_attack: int = 0
@export var stat_boost_hp: int = 0
@export var price: int = 2

@onready var portrait_label: Label = %PortraitCharLabel
@onready var sprite_rect: TextureRect = %SpriteRect
@onready var attack_label: Label = %AttackLabel
@onready var poison_label: Label = %PoisonLabel
@onready var attack_panel: PanelContainer = %AttackPanel
@onready var poison_panel: PanelContainer = %PoisonPanel

func _ready() -> void:
	# Add custom double border for food card
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

	border_rect.resized.connect(func():
		if border_rect.material:
			border_rect.material.set_shader_parameter("size", border_rect.size)
	)
	
	if is_new:
		add_child(border_rect)
		move_child(border_rect, 0)
		
	if border_rect.material:
		var initial_size = border_rect.size if border_rect.size != Vector2.ZERO else (size if size != Vector2.ZERO else custom_minimum_size)
		border_rect.material.set_shader_parameter("size", initial_size)
		
	update_ui()

func update_ui() -> void:
	# Clean styles
	var card_style = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", card_style)
	
	# Set border to golden-orange for food/items
	var border_rect = get_node_or_null("BorderRect")
	if border_rect and border_rect.material:
		var mat = border_rect.material as ShaderMaterial
		mat.set_shader_parameter("size", size if size != Vector2.ZERO else custom_minimum_size)
		mat.set_shader_parameter("outer_border_width", 3)
		mat.set_shader_parameter("inner_border_width", 3)
		mat.set_shader_parameter("outer_border_color", Color(0.9, 0.6, 0.1)) # Golden orange
		mat.set_shader_parameter("interior_color", GameColors.WHITE_COLOR)
		mat.set_shader_parameter("corner_color", GameColors.TRANSPARENT)
		
	# Setup portrait icon/text
	sprite_rect.visible = false
	portrait_label.visible = true
	portrait_label.add_theme_color_override("font_color", GameColors.PORTRAIT_FALLBACK_TEXT)
	if food_name == "Apple":
		portrait_label.text = "🍎"
	elif food_name == "Sword":
		portrait_label.text = "⚔️"
	else:
		portrait_label.text = "🎁"
		
	# Setup stats boost displays
	var stat_size = Vector2(32, 16)
	if stat_boost_attack > 0:
		attack_panel.visible = true
		attack_label.text = "+" + str(stat_boost_attack)
		setup_stat_panel_shader(attack_panel, GameColors.STAT_ATTACK_BG, stat_size)
	else:
		attack_panel.visible = false
		
	if stat_boost_hp > 0:
		poison_panel.visible = true
		# Reuse poison stats panel to display HP boost (using green background for HP)
		poison_label.text = "+" + str(stat_boost_hp)
		setup_stat_panel_shader(poison_panel, Color(0.15, 0.6, 0.3), stat_size)
	else:
		poison_panel.visible = false

func setup_stat_panel_shader(panel: PanelContainer, bg_color: Color, stat_size: Vector2) -> void:
	panel.custom_minimum_size = stat_size
	var empty_style = StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", empty_style)
	
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
		panel.move_child(border_rect, 0)
		
		panel.resized.connect(func():
			if border_rect and border_rect.material:
				border_rect.material.set_shader_parameter("size", panel.size)
		)
		
	if border_rect.material:
		var mat = border_rect.material as ShaderMaterial
		mat.set_shader_parameter("size", panel.size if panel.size != Vector2.ZERO else panel.custom_minimum_size)
		mat.set_shader_parameter("border_width", 2)
		mat.set_shader_parameter("border_indentation", 1)
		mat.set_shader_parameter("border_color", bg_color.lightened(.2))
		mat.set_shader_parameter("interior_color", bg_color)
		mat.set_shader_parameter("corner_color", GameColors.TRANSPARENT)

func apply_food_effect(monster_card: Control) -> void:
	var inst = monster_card.monster_instance
	if inst:
		inst.current_attack += stat_boost_attack
		inst.max_health_bonus += stat_boost_hp
		inst.current_health += stat_boost_hp

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Preview
	var preview_scene = load("res://src/shared/components/food_item.tscn")
	var preview = preview_scene.instantiate()
	preview.food_name = food_name
	preview.stat_boost_attack = stat_boost_attack
	preview.stat_boost_hp = stat_boost_hp
	preview.custom_minimum_size = custom_minimum_size
	preview.modulate.a = 0.7
	
	var preview_wrapper = Control.new()
	preview_wrapper.add_child(preview)
	preview.position = -custom_minimum_size / 2.0
	
	set_drag_preview(preview_wrapper)
	
	var original_slot = get_parent()
	while original_slot and not original_slot.has_method("add_card"):
		original_slot = original_slot.get_parent()
		
	if original_slot:
		original_slot.remove_card.call_deferred(self)
		original_slot.slot_changed.emit.call_deferred(original_slot)
		
	# Notify ShopScene about the drag starting
	var shop_scene = get_tree().current_scene
	if shop_scene and shop_scene.has_method("notify_drag_started"):
		shop_scene.notify_drag_started(self, original_slot)
		
	var viewport = get_viewport()
	preview_wrapper.tree_exiting.connect(func():
		if viewport and not viewport.gui_is_drag_successful():
			if original_slot:
				original_slot.add_card(self)
				original_slot.slot_changed.emit(original_slot)
	)
	
	return {
		"card": self,
		"original_slot": original_slot
	}
