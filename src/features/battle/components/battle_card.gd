class_name BattleCard
extends PanelContainer

signal hovered(card: BattleCard, is_hovered: bool)

@export var unit_instance: UnitInstance:
	set(val):
		unit_instance = val
		if is_inside_tree():
			update_ui()

@onready var stats_hbox: HBoxContainer = %StatsHBox
@onready var sprite_rect: TextureRect = %SpriteRect
@onready var portrait_char_label: Label = %PortraitCharLabel

func _ready() -> void:
	update_ui()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	tree_exiting.connect(_on_mouse_exited)

func update_ui() -> void:
	if not unit_instance:
		return
		
	# Delegate visual rendering to shared helper
	CardUIHelper.setup_card_visuals(
		unit_instance,
		stats_hbox,
		sprite_rect,
		portrait_char_label
	)
	
	# Since this is battle_card, it has NO border drawing. The container panel itself can be transparent.
	# We override stylebox to Empty
	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", empty_style)

func _on_mouse_entered() -> void:
	hovered.emit(self, true)

func _on_mouse_exited() -> void:
	hovered.emit(self, false)
