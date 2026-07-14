class_name CompendiumGridItem
extends PanelContainer

signal hovered(item: CompendiumGridItem, is_hover: bool)
signal level_changed(item: CompendiumGridItem)

@export var data_resource: GameResourceData:
	set(val):
		data_resource = val
		if is_inside_tree():
			update_ui()

var unit_level: int = 1

@onready var portrait_label: Label = %PortraitCharLabel
@onready var sprite_rect: TextureRect = %SpriteRect
@onready var border_rect: ShaderBorderDecorator = %BorderRect

func _ready() -> void:
	custom_minimum_size = CardUIHelper.CARD_SIZE

	update_ui()

	mouse_entered.connect(func() -> void: hovered.emit(self, true))
	mouse_exited.connect(func() -> void: hovered.emit(self, false))

func update_ui() -> void:
	if not data_resource:
		return
		
	# Reset defaults
	if portrait_label:
		portrait_label.visible = false
	if sprite_rect:
		sprite_rect.visible = false
	
	# 1. Determine border color based on rarity and configure border
	var border_color: Color = GameColors.BORDER_OUTER_DEFAULT
	border_color = data_resource.rarity.border_color
		
	border_rect.border_color = border_color
	border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
	border_rect.interior_color = GameColors.WHITE_COLOR
	border_rect.update_shader_parameters()
		
	# 2. Configure sprite or text fallback
	if data_resource.sprite:
		if sprite_rect:
			sprite_rect.visible = true
			sprite_rect.texture = data_resource.sprite
	else:
		if portrait_label:
			portrait_label.visible = true
			portrait_label.text = data_resource.display_name.to_upper()

func _gui_input(event: InputEvent) -> void:
	if not data_resource is UnitData:
		return
		
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if not mouse_event.pressed:
			return

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_change_unit_level(1)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_change_unit_level(-1)
			accept_event()

func _change_unit_level(delta: int) -> void:
	var old_level: int = unit_level
	unit_level = clampi(unit_level + delta, 1, 3)
	if unit_level != old_level:
		update_ui()
		level_changed.emit(self)
