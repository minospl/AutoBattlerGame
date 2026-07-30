class_name BattleCard
extends MarginContainer

signal hovered(card: BattleCard, is_hovered: bool)

@export var unit_instance: UnitInstance:
	set(val):
		unit_instance = val
		if is_inside_tree():
			update_ui()

@onready var stats_hbox: UnitStatsBar = %StatsHBox
@onready var sprite_rect: TextureRect = %SpriteRect
@onready var portrait_char_label: Label = %PortraitCharLabel

func _ready() -> void:
	custom_minimum_size = CardUIHelper.CARD_SIZE
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

func _on_mouse_entered() -> void:
	hovered.emit(self, true)

func _on_mouse_exited() -> void:
	hovered.emit(self, false)
