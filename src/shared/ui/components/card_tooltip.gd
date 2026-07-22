class_name CardTooltip
extends MarginContainer

const TYPE_BADGE_SCENE: PackedScene = preload("res://src/shared/ui/components/type_badge.tscn")
const BADGE_COLOR_ITEM: Color = Color(0.18, 0.45, 0.72, 1.0) # Sleek blue for items
const BADGE_COLOR_RELIC: Color = Color(0.72, 0.45, 0.18, 1.0) # Gold-amber for relics

@onready var border_rect: ShaderBorderDecorator = %BorderRect
@onready var name_label: Label = %NameLabel
@onready var rarity_label: Label = %RarityLabel
@onready var card_portrait: CardPortrait = %CardPortrait
@onready var badge_list: VBoxContainer = %BadgeList
@onready var stats_panel_container: PanelContainer = %StatsPanelContainer
@onready var stats_panel: TooltipStatsPanel = %StatsPanel
@onready var desc_panel: PanelContainer = %DescPanel
@onready var desc_label: RichTextLabel = %DescLabel

# Cache border panels as @onready to avoid runtime lookup issues
@onready var portrait_border_rect: ShaderBorderDecorator = %PortraitBorderRect
@onready var stats_border_rect: ShaderBorderDecorator = %StatsBorderRect
@onready var desc_border_rect: ShaderBorderDecorator = %DescBorderRect
@onready var help_border_rect: ShaderBorderDecorator = %HelpBorderRect
@onready var help_panel: PanelContainer = %HelpPanel

var _unit_instance: UnitInstance
var _item_instance: ItemInstance
var _relic_instance: RelicInstance
var _keywords_count: int = 0

@onready var keywords_vbox: TooltipKeywordsBox = %KeywordsVBox
@onready var main_tooltip_wrapper: MarginContainer = %MainTooltipWrapper

func _ready() -> void:
	if _unit_instance:
		_setup_unit_ui()
		_build_keywords()
	elif _item_instance:
		_setup_item_ui()
		_build_keywords()
	elif _relic_instance:
		_setup_relic_ui()
		_build_keywords()

	_set_mouse_filter_ignore_recursive(self)
	
	var parent_node: Node = get_parent()
	if parent_node and parent_node is Control:
		(parent_node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _set_mouse_filter_ignore_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_set_mouse_filter_ignore_recursive(child)

func get_unit_instance() -> UnitInstance:
	return _unit_instance

func setup_for_unit(unit_instance: UnitInstance) -> void:
	_unit_instance = unit_instance
	_item_instance = null
	_relic_instance = null
	if is_node_ready():
		_setup_unit_ui()
		_build_keywords()

func setup_for_item(item_card: ItemInstance) -> void:
	_item_instance = item_card
	_unit_instance = null
	_relic_instance = null
	if is_node_ready():
		_setup_item_ui()
		_build_keywords()

func setup_for_relic(relic_instance: RelicInstance) -> void:
	_relic_instance = relic_instance
	_unit_instance = null
	_item_instance = null
	if is_node_ready():
		_setup_relic_ui()
		_build_keywords()

func _setup_unit_ui() -> void:
	_setup_common_ui(_unit_instance.data)
	
	# Specyficzne dla jednostki:
	name_label.text = _unit_instance.get_unit_name().to_upper() + " [Lvl %d]" % _unit_instance.level
	stats_panel_container.visible = true
	stats_panel.setup(_unit_instance)
	
	update_badge()
	update_description()

func _setup_item_ui() -> void:
	_setup_common_ui(_item_instance.data)
	
	# Specyficzne dla przedmiotu:
	stats_panel_container.visible = false
	badge_list.visible = true

	update_badge()
	update_description()

func _setup_relic_ui() -> void:
	_setup_common_ui(_relic_instance.data)
	
	# Specyficzne dla reliktu:
	var stacks: int = _relic_instance.stacks
	if stacks > 1:
		name_label.text = _relic_instance.data.display_name.to_upper() + " [x%d]" % stacks
		
	stats_panel_container.visible = false
	badge_list.visible = true

	update_badge()
	update_description()

func _setup_common_ui(data: GameResourceData) -> void:
	name_label.text = data.display_name.to_upper()
	rarity_label.text = data.rarity.rarity_name.to_upper()
	
	var border_col: Color = data.rarity.border_color
	if border_rect:
		border_rect.interior_color = border_col
		border_rect.update_shader_parameters()
		
	_update_sub_panel_borders(border_col.lightened(0.5))
	_update_sprite(data)

func _update_sub_panel_borders(border_col: Color) -> void:
	var panels: Array[ShaderBorderDecorator] = [
		portrait_border_rect,
		stats_border_rect,
		desc_border_rect,
		help_border_rect
	]

	for rect: ShaderBorderDecorator in panels:
		rect.border_color = border_col
		rect.update_shader_parameters()

func _update_sprite(data: GameResourceData) -> void:
	if card_portrait:
		card_portrait.setup_visuals(data)

func update_badge() -> void:
	# Clear old badge nodes
	for child: Node in badge_list.get_children():
		child.queue_free()

	var badges_to_create: Dictionary[String, Color] = {}

	if _unit_instance:
		for type: UnitType in _unit_instance.get_types():
			badges_to_create[type.type_name.to_upper()] = type.color
	if _item_instance:
		badges_to_create["ITEM"] = BADGE_COLOR_ITEM
	if _relic_instance:
		badges_to_create["RELIC"] = BADGE_COLOR_RELIC

	badge_list.visible = true
	for text: String in badges_to_create:
		var badge: TypeBadge = TYPE_BADGE_SCENE.instantiate()
		badge_list.add_child(badge)
		badge.setup(text, badges_to_create[text])

func update_dynamic_content() -> void:
	if _unit_instance and stats_panel_container.visible:
		stats_panel.update_dynamic_stats(_unit_instance)

func update_description() -> void:
	var full_desc: String = ""
	if _unit_instance:
		var modifier: UnitModifier = _unit_instance.data.modifier
		if modifier:
			full_desc = modifier.get_description(_unit_instance.level)
	if _item_instance:
		full_desc = _item_instance.data.modifier.get_description()
	if _relic_instance:
		full_desc = _relic_instance.data.modifier.get_description(_relic_instance)
			
	if not full_desc.is_empty():
		desc_panel.visible = true
		desc_label.text = "[center]%s[/center]" % full_desc
	else:
		desc_panel.visible = false

func _process(_delta: float) -> void:
	if visible:
		var shift_pressed: bool = Input.is_key_pressed(KEY_SHIFT)
		_update_keywords_visibility(shift_pressed)

func _build_keywords() -> void:
	if not keywords_vbox:
		return
	_keywords_count = keywords_vbox.build_keywords(_unit_instance)
	_update_help_panel_visibility()

func _update_help_panel_visibility() -> void:
	if not help_panel:
		return
	help_panel.visible = _keywords_count > 0

func _update_keywords_visibility(show_keywords: bool) -> void:
	if not keywords_vbox:
		return
	keywords_vbox.visible = show_keywords and _keywords_count > 0
