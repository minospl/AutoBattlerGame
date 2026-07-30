class_name StatBadge
extends PanelContainer

@onready var stat_label: Label = %StatLabel
@onready var border_rect: ShaderBorderDecorator = %BorderRect

var _stat_type: StatType.Type = StatType.Type.HP
var _value: int = 0
var _badge_size: Vector2 = Vector2(28, 16)
var _is_setup: bool = false

func _ready() -> void:
	if _is_setup:
		_apply_visuals()

func setup(stat_type: StatType.Type, value: int, badge_size: Vector2 = Vector2(28, 16)) -> void:
	_stat_type = stat_type
	_value = value
	_badge_size = badge_size
	_is_setup = true
	
	if is_node_ready():
		_apply_visuals()

func _apply_visuals() -> void:
	custom_minimum_size = _badge_size
	
	if stat_label:
		stat_label.text = NumberFormatter.format_large_number(_value)
		
	var bg_color: Color = StatType.get_stat_color(_stat_type)
	if border_rect:
		border_rect.border_color = bg_color.lightened(0.2)
		border_rect.interior_color = bg_color
		border_rect.inner_border_width = 2
		border_rect.border_indentation = 1
		border_rect.update_shader_parameters()
