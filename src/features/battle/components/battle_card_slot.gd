class_name BattleCardSlot
extends Control

## Index of this slot in the team array (0 to 5)
@export var slot_index: int = 0

@onready var card_container: PanelContainer = %CardContainer
@onready var cooldown_fill: ColorRect = %CooldownFill
@onready var empty_border_rect: ShaderBorderDecorator = %EmptyBorderRect

var is_targeted: bool = false
var _cooldown_material: ShaderMaterial = null

func _ready() -> void:
	# Configure sizes dynamically based on CardUIHelper
	custom_minimum_size = Vector2(CardUIHelper.CARD_SIZE.x + 8 + 4, CardUIHelper.CARD_SIZE.y)
	
	if has_node("%CardContainer"):
		var container: PanelContainer = get_node("%CardContainer") as PanelContainer
		if container:
			container.custom_minimum_size = CardUIHelper.CARD_SIZE
		
	if has_node("%CooldownContainer"):
		var cooldown: Control = get_node("%CooldownContainer") as Control
		if cooldown:
			cooldown.custom_minimum_size = Vector2(8, CardUIHelper.CARD_SIZE.y)
			
	if cooldown_fill:
		cooldown_fill.anchor_top = 0.0
		cooldown_fill.anchor_bottom = 1.0
		var shader_res: Shader = load("res://src/shared/shaders/cooldown_fill.gdshader") as Shader
		if shader_res:
			_cooldown_material = ShaderMaterial.new()
			_cooldown_material.shader = shader_res
			_cooldown_material.set_shader_parameter("fill_color", Color(0.18, 0.53, 0.88, 0.85))
			_cooldown_material.set_shader_parameter("progress", 0.0)
			cooldown_fill.material = _cooldown_material

	# Initialize slot placeholder state
	update_placeholder()

func set_cast_progress(ratio: float) -> void:
	var clamped_ratio: float = clamp(ratio, 0.0, 1.0)
	if _cooldown_material:
		_cooldown_material.set_shader_parameter("progress", clamped_ratio)

func set_target_highlight(active: bool) -> void:
	is_targeted = active
	if empty_border_rect:
		if is_targeted:
			empty_border_rect.visible = true
			empty_border_rect.border_color = Color(0.9, 0.15, 0.15, 1.0)
			empty_border_rect.inner_border_color = Color(0.5, 0.05, 0.05, 1.0)
			empty_border_rect.interior_color = Color(0.0, 0.0, 0.0, 0.0)
			empty_border_rect.update_shader_parameters()
		else:
			empty_border_rect.visible = is_empty()
			empty_border_rect.border_color = GameColors.BORDER_OUTER_DEFAULT
			empty_border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
			empty_border_rect.interior_color = GameColors.WHITE_COLOR
			empty_border_rect.update_shader_parameters()

func update_placeholder() -> void:
	var empty: bool = is_empty()
	if empty_border_rect:
		empty_border_rect.visible = empty
		
	if empty:
		set_cast_progress(0.0)

func add_card(card: BattleCard) -> void:
	if card_container:
		card_container.add_child(card)
		update_placeholder()

func remove_card(card: BattleCard) -> void:
	if card_container:
		card_container.remove_child(card)
		update_placeholder()

func get_card() -> BattleCard:
	if not card_container:
		return null
	for child: Node in card_container.get_children():
		if child is BattleCard:
			return child as BattleCard
	return null

func is_empty() -> bool:
	return get_card() == null

func get_unit_instance() -> UnitInstance:
	var card: BattleCard = get_card()
	if card:
		return card.unit_instance
	return null
