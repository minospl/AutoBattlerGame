class_name UnitCard
extends PanelContainer

signal hovered(card: UnitCard, is_hovered: bool)
signal right_clicked(card: UnitCard)

@export var unit_instance: UnitInstance:
	set(val):
		unit_instance = val
		if is_inside_tree():
			update_ui()

@onready var card_portrait: CardPortrait = %CardPortrait
@onready var stats_hbox: HBoxContainer = %StatsHBox
@onready var direction_indicators: DirectionIndicators = %DirectionIndicators

var is_highlighted: bool = false
var is_targeted: bool = false
var slot: ShopCardSlot = null

func _ready() -> void:
	custom_minimum_size = CardUIHelper.CARD_SIZE
	update_ui()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	tree_exiting.connect(_on_mouse_exited)

func update_ui() -> void:
	if not unit_instance:
		return
		
	# 1. Konfiguracja portretu i ramki za pomocą danych statycznych
	card_portrait.setup_visuals(unit_instance.data)
	card_portrait.border_rect.interior_color = GameColors.WHITE_COLOR
	card_portrait.border_rect.update_shader_parameters()
			
	# 2. Konfiguracja statystyk bojowych
	CardUIHelper.setup_stats(unit_instance, stats_hbox)
	
	# 3. Konfiguracja wskaźników celowania
	if direction_indicators:
		direction_indicators.setup_indicators(unit_instance)
		
	update_border_colors()

func set_highlight(active: bool) -> void:
	is_highlighted = active
	update_border_colors()

func set_target_highlight(active: bool) -> void:
	is_targeted = active
	update_border_colors()

func update_border_colors() -> void:
	if not card_portrait or not card_portrait.border_rect:
		return
		
	var border_rect: ShaderBorderDecorator = card_portrait.border_rect
	
	if is_highlighted:
		border_rect.border_color = GameColors.SLOT_HOVER_OUTER_BORDER
		border_rect.inner_border_color = GameColors.SLOT_HOVER_INNER_BORDER
	elif is_targeted:
		border_rect.border_color = Color(0.9, 0.15, 0.15, 1.0)
		border_rect.inner_border_color = Color(0.5, 0.05, 0.05, 1.0)
	else:
		var rarity_color: Color = GameColors.BORDER_OUTER_DEFAULT
		if unit_instance and unit_instance.data and unit_instance.data.rarity:
			rarity_color = unit_instance.data.rarity.border_color
		border_rect.border_color = rarity_color
		border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
	border_rect.update_shader_parameters()

func _on_mouse_entered() -> void:
	if DragManager.dragged_card:
		return
	hovered.emit(self, true)

func _on_mouse_exited() -> void:
	hovered.emit(self, false)

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview_scene: PackedScene = load("res://src/features/shop/components/unit_card.tscn") as PackedScene
	var preview: UnitCard = preview_scene.instantiate() as UnitCard
	preview.unit_instance = unit_instance
	preview.custom_minimum_size = custom_minimum_size
	
	preview.modulate.a = 0.7
	preview.z_index = 100
	preview.z_as_relative = false
	
	var preview_wrapper: Control = Control.new()
	preview_wrapper.z_index = 100
	preview_wrapper.z_as_relative = false
	preview_wrapper.add_child(preview)
	preview.position = -custom_minimum_size / 2.0
	
	set_drag_preview(preview_wrapper)
	
	var original_slot: ShopCardSlot = slot
	self.visible = false
	if original_slot:
		original_slot.update_placeholder()
		
	DragManager.notify_drag_started(self, original_slot)
	
	preview_wrapper.tree_exiting.connect(func() -> void:
		if is_instance_valid(self):
			self.visible = true
			if original_slot:
				original_slot.update_placeholder()
		DragManager.notify_drag_ended()
	)
	
	return {
		"card": self,
		"original_slot": original_slot
	}

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			right_clicked.emit(self)
			accept_event()
