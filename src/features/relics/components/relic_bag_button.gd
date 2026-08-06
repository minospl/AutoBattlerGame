class_name RelicBagButton
extends TextureButton

signal bag_opened

@onready var count_label: Label = $BadgeContainer/CountLabel
@onready var badge_container: Control = $BadgeContainer

var current_count: int = 0:
	set(val):
		current_count = val
		_update_badge()

func _ready() -> void:
	pressed.connect(func() -> void: bag_opened.emit())
	_update_badge()

func _update_badge() -> void:
	if current_count > 0:
		badge_container.visible = true
		count_label.text = str(current_count)
	else:
		badge_container.visible = false
