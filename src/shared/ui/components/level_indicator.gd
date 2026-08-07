class_name LevelIndicator
extends Control

const BASE_BADGE: PackedScene = preload("res://src/shared/ui/components/base_badge.tscn")

## Indicates unit level/stars using pixel-art shader badges above the card portrait.
@export var level: int = 1:
	set(val):
		level = val
		_update_badges()
		
@export var max_level: int = 3
@export var badge_size: Vector2 = Vector2(8, 8)
@export var badge_spacing: int = 3
@export var x_offset: float = 12.0
@export var y_offset: float = 12.0
@export var border_color: Color = Color(0.2, 0.1, 0.0, 1.0)
@export var interior_color: Color = Color(0.9, 0.7, 0.2, 1.0)

var _badges_container: HBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 10
	z_as_relative = true
	_setup_container()
	_update_badges()

## Configures level indicator for a card.
func setup(p_level: int, p_max_level: int = 3) -> void:
	max_level = p_max_level
	level = clampi(p_level, 0, max_level)

func _setup_container() -> void:
	if not _badges_container:
		_badges_container = HBoxContainer.new()
		_badges_container.name = "BadgesContainer"
		_badges_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_badges_container.position = Vector2(x_offset, y_offset)
		add_child(_badges_container)
	_badges_container.add_theme_constant_override("separation", badge_spacing)

func _update_badges() -> void:
	_setup_container()

	for child: Node in _badges_container.get_children():
		_badges_container.remove_child(child)
		child.free()

	if level <= 0:
		return

	for i: int in range(level):
		var badge: BaseBadge = BASE_BADGE.instantiate() as BaseBadge
		badge.badge_size = badge_size
		badge.setup(interior_color, border_color)
		_badges_container.add_child(badge)
