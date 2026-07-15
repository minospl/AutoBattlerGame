class_name TypeBadge
extends PanelContainer

var _pending_text: String = ""

@onready var label: Label = $Label

func _ready() -> void:
	if label and not _pending_text.is_empty():
		label.text = _pending_text

func setup(text: String, bg_color: Color) -> void:
	_pending_text = text
	if label:
		label.text = text
		
	var flat_style: StyleBoxFlat = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	flat_style.bg_color = bg_color
	add_theme_stylebox_override("panel", flat_style)
