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

@onready var card_portrait: CardPortrait = %CardPortrait

func _ready() -> void:
	custom_minimum_size = CardUIHelper.CARD_SIZE

	update_ui()

	mouse_entered.connect(func() -> void: hovered.emit(self, true))
	mouse_exited.connect(func() -> void: hovered.emit(self, false))

func update_ui() -> void:
	if not data_resource:
		return
		
	if card_portrait:
		card_portrait.setup_visuals(data_resource)


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
