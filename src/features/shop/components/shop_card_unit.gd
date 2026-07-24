class_name ShopCardUnit
extends VBoxContainer

signal hovered(card: ShopCardUnit, is_hovered: bool)
signal clicked(card: ShopCardUnit)

@export var price: int

@export var unit_instance: UnitInstance:
	set(val):
		unit_instance = val
		if unit_instance and unit_instance.data:
			price = unit_instance.data.price
		if is_inside_tree():
			update_ui()

var is_highlighted: bool = false
var is_targeted: bool = false
var slot: ShopSlot = null

func _ready() -> void:
	custom_minimum_size = CardUIHelper.CARD_SLOT_SIZE_SHOP
	update_ui()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func update_ui() -> void:
	if not unit_instance:
		return
		
	# 1. Configure stats using modular helpers
	CardUIHelper.setup_stats(unit_instance, %StatsHBox as HBoxContainer)
	
	# 2. Configure portrait and rarity border
	var portrait: CardPortrait = %CardPortrait as CardPortrait
	portrait.setup_visuals(unit_instance.data)
	portrait.border_rect.interior_color = GameColors.WHITE_COLOR
	portrait.border_rect.update_shader_parameters()
	
	var texture_rect: TextureRect = portrait.find_child("TextureRect", true, false)
	if texture_rect:
		texture_rect.offset_top = -20.0
		
	# 3. Configure name and price footer
	var name_label: Label = %NameLabel as Label
	name_label.text = unit_instance.data.display_name
		
	var price_label: Label = %PriceLabel as Label
	price_label.text = str(price) + "G"
		
	update_border_colors()

func set_highlight(active: bool) -> void:
	is_highlighted = active
	update_border_colors()

func set_target_highlight(active: bool) -> void:
	is_targeted = active
	update_border_colors()

func update_border_colors() -> void:
	var portrait: CardPortrait = %CardPortrait as CardPortrait
	if not portrait:
		return
		
	var border_rect: ShaderBorderDecorator = portrait.get_node_or_null("BorderRect") as ShaderBorderDecorator
	if not border_rect:
		return
		
	if is_highlighted:
		border_rect.border_color = GameColors.SLOT_HOVER_OUTER_BORDER
		border_rect.inner_border_color = GameColors.SLOT_HOVER_INNER_BORDER
	elif is_targeted:
		border_rect.border_color = Color(0.9, 0.15, 0.15, 1.0)
		border_rect.inner_border_color = Color(0.5, 0.05, 0.05, 1.0)
	else:
		var rarity_color: Color = GameColors.BORDER_OUTER_DEFAULT
		if unit_instance:
			rarity_color = unit_instance.data.rarity.border_color
		border_rect.border_color = rarity_color
		border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
	border_rect.update_shader_parameters()

func _on_mouse_entered() -> void:
	hovered.emit(self, true)

func _on_mouse_exited() -> void:
	hovered.emit(self, false)

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Shop offers are not draggable
	return null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(self)
			accept_event()
