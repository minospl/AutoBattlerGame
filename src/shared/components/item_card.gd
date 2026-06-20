class_name ItemCard
extends PanelContainer

@export var item_name: String = "Apple"
@export var stat_boost_attack: int = 0
@export var stat_boost_hp: int = 0
@export var price: int = 2

@onready var portrait_label: Label = %PortraitCharLabel
@onready var sprite_rect: TextureRect = %SpriteRect
@onready var attack_label: Label = %AttackLabel
@onready var hp_label: Label = %HpLabel
@onready var attack_panel: PanelContainer = %AttackPanel
@onready var hp_panel: PanelContainer = %HpPanel

func _ready() -> void:
	tooltip_text = " "
	update_ui()

func update_ui() -> void:
	# Set border to golden-orange for items
	var border_rect = get_node_or_null("BorderRect") as ShaderBorderDecorator
	if border_rect:
		border_rect.border_color = Color(0.9, 0.6, 0.1) # Golden orange
		border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
		border_rect.interior_color = GameColors.WHITE_COLOR
		border_rect.update_shader_parameters()
		
	# Setup portrait icon/text
	sprite_rect.visible = false
	portrait_label.visible = true
	portrait_label.add_theme_color_override("font_color", GameColors.PORTRAIT_FALLBACK_TEXT)
	if item_name == "Apple":
		portrait_label.text = "🍎"
	elif item_name == "Sword":
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
		hp_panel.visible = true
		# Display HP boost (using green background for HP)
		hp_label.text = "+" + str(stat_boost_hp)
		setup_stat_panel_shader(hp_panel, Color(0.15, 0.6, 0.3), stat_size)
	else:
		hp_panel.visible = false

func setup_stat_panel_shader(panel: PanelContainer, bg_color: Color, stat_size: Vector2) -> void:
	panel.custom_minimum_size = stat_size
	
	var border_rect = panel.get_node_or_null("BorderRect") as ShaderBorderDecorator
	if border_rect:
		border_rect.border_color = bg_color.lightened(.2)
		border_rect.interior_color = bg_color
		border_rect.update_shader_parameters()

func apply_food_effect(card: Control) -> void:
	var inst = card.unit_instance
	if inst:
		inst.current_attack += stat_boost_attack
		inst.max_health_bonus += stat_boost_hp
		inst.current_health += stat_boost_hp

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Keep the card in place but dim it visually to indicate it is active
	modulate.a = 0.5
	
	# Create an empty transparent preview so no card visual is dragged under the mouse
	var preview_wrapper = Control.new()
	set_drag_preview(preview_wrapper)
	
	var original_slot = get_parent()
	while original_slot and not original_slot.has_method("add_card"):
		original_slot = original_slot.get_parent()
		
	# Notify about the drag starting using DragManager
	DragManager.notify_drag_started(self, original_slot)
		
	# Restore normal modulate when drag ends
	preview_wrapper.tree_exiting.connect(func():
		modulate.a = 1.0
		DragManager.notify_drag_ended()
	)
	
	return {
		"card": self,
		"original_slot": original_slot
	}

func _make_custom_tooltip(_for_text: String) -> Object:
	var tooltip_scene = load("res://src/shared/components/card_tooltip.tscn")
	var tooltip = tooltip_scene.instantiate()
	tooltip.setup_for_item(self)
	return tooltip
