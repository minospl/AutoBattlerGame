class_name KeywordPanel
extends MarginContainer

@onready var shader_border: ShaderBorderDecorator = %ShaderBorder
@onready var title_label: Label = %TitleLabel
@onready var desc_label: RichTextLabel = %DescLabel

var _title: String = ""
var _desc: String = ""

func _ready() -> void:
	if shader_border:
		shader_border.update_shader_parameters()
	_update_ui()

func setup(p_title: String, p_desc: String) -> void:
	_title = p_title
	_desc = p_desc
	_update_ui()

func _update_ui() -> void:
	if not is_node_ready():
		return
	if title_label and desc_label:
		title_label.text = _title.to_upper()
		desc_label.text = "[color=#2c3e50][font_size=12]%s[/font_size][/color]" % _desc
