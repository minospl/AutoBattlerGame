class_name CardTooltip
extends MarginContainer

const CHROMA_KEY_SHADER: Shader = preload("res://src/shared/shaders/chroma_key.gdshader")

@onready var border_rect: ShaderBorderDecorator = %BorderRect
@onready var name_label: Label = %NameLabel
@onready var rarity_label: Label = %RarityLabel
@onready var sprite_rect: TextureRect = %SpriteRect
@onready var fallback_label: Label = %FallbackLabel
@onready var badge_panel: PanelContainer = %BadgePanel
@onready var badge_label: Label = %BadgeLabel
@onready var badge_container_panel: PanelContainer = %BadgeContainerPanel
@onready var stats_panel: MarginContainer = %StatsPanel
@onready var stats_grid: GridContainer = %StatsGrid
@onready var stat_label_template: RichTextLabel = %StatLabelTemplate
@onready var desc_panel: PanelContainer = %DescPanel
@onready var desc_label: RichTextLabel = %DescLabel

# Cache border panels as @onready to avoid runtime lookup issues
@onready var portrait_border_rect: ShaderBorderDecorator = %PortraitBorderRect
@onready var sprite_border_rect: ShaderBorderDecorator = %SpriteBorderRect
@onready var badge_container_border_rect: ShaderBorderDecorator = %BadgeContainerBorderRect
@onready var desc_border_rect: ShaderBorderDecorator = %DescBorderRect
@onready var help_border_rect: ShaderBorderDecorator = %HelpBorderRect

var _unit_instance: UnitInstance
var _item_card: ItemInstance
var _relic_instance: RelicInstance
var _rarity_name: String = "COMMON"
var _rarity_color: Color = GameColors.BORDER_OUTER_DEFAULT

@onready var keywords_vbox: VBoxContainer = %KeywordsVBox
@onready var main_tooltip_wrapper: PanelContainer = %MainTooltipWrapper

func _ready() -> void:
	if _unit_instance:
		_setup_unit_ui()
		_build_keywords()
	elif _item_card:
		_setup_item_ui()
	elif _relic_instance:
		_setup_relic_ui()

	_set_mouse_filter_ignore_recursive(self)
	
	# Make sure the parent container (PreviewContainer) also ignores mouse inputs
	# as its invisible boundaries expand to fit the keywords column.
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
	_item_card = null
	_relic_instance = null
	if is_node_ready():
		_setup_unit_ui()
		_build_keywords()

func setup_for_item(item_card: ItemInstance) -> void:
	_item_card = item_card
	_unit_instance = null
	_relic_instance = null
	if is_node_ready():
		_setup_item_ui()
		if keywords_vbox:
			for child: Node in keywords_vbox.get_children():
				child.queue_free()

func setup_for_relic(relic_instance: RelicInstance) -> void:
	_relic_instance = relic_instance
	_unit_instance = null
	_item_card = null
	if is_node_ready():
		_setup_relic_ui()
		if keywords_vbox:
			for child: Node in keywords_vbox.get_children():
				child.queue_free()

func _setup_unit_ui() -> void:
	if not _unit_instance:
		return
		
	# Reset rarity state to defaults to prevent carry-over bugs
	_rarity_name = "COMMON"
	_rarity_color = GameColors.BORDER_OUTER_DEFAULT
		
	if _unit_instance.data and _unit_instance.data.rarity:
		_rarity_name = _unit_instance.data.rarity.rarity_name.to_upper()
		_rarity_color = _unit_instance.data.rarity.border_color
	
	# Stats
	stats_panel.visible = true
		
	update_header()
	update_border()
	update_sprite()
	update_badge()
	update_stats()
	update_description()

func _setup_item_ui() -> void:
	if not _item_card:
		return
		
	# Reset rarity state to defaults to prevent carry-over bugs
	_rarity_name = "COMMON"
	_rarity_color = GameColors.BORDER_OUTER_DEFAULT
		
	if _item_card.data and _item_card.data.rarity:
		_rarity_name = _item_card.data.rarity.rarity_name.to_upper()
		_rarity_color = _item_card.data.rarity.border_color
	
	# Items do not use the stats block or the type badge
	stats_panel.visible = false
	badge_panel.visible = false
	if badge_container_panel:
		badge_container_panel.visible = false

	update_header()
	update_border()
	update_sprite()
	update_description()

func _setup_relic_ui() -> void:
	if not _relic_instance:
		return
		
	# Reset rarity state to defaults
	_rarity_name = "COMMON"
	_rarity_color = GameColors.BORDER_OUTER_DEFAULT
	
	var relic_data: RelicData = _relic_instance.data
	if relic_data and relic_data.rarity:
		var rarity_res: Rarity = relic_data.rarity
		if rarity_res:
			_rarity_name = rarity_res.rarity_name.to_upper()
			_rarity_color = rarity_res.border_color
	
	# Relics do not use stats block or type badge
	stats_panel.visible = false
	badge_panel.visible = false
	if badge_container_panel:
		badge_container_panel.visible = false

	update_header()
	update_border()
	update_sprite()
	update_description()

func _update_sub_panel_borders(border_col: Color) -> void:
	var panels: Array[ShaderBorderDecorator] = [
		portrait_border_rect,
		sprite_border_rect,
		badge_container_border_rect,
		desc_border_rect,
		help_border_rect
	]

	for rect: ShaderBorderDecorator in panels:
		if rect:
			rect.border_color = border_col
			rect.update_shader_parameters()

func update_header() -> void:
	if _unit_instance:
		name_label.text = _unit_instance.get_unit_name().to_upper() + " [Lvl %d]" % _unit_instance.level
	elif _item_card:
		name_label.text = _item_card.data.item_name.to_upper() if _item_card.data else ""
	elif _relic_instance:
		var relic_data: RelicData = _relic_instance.data
		name_label.text = relic_data.relic_name.to_upper() if relic_data else ""
		var stacks: int = _relic_instance.stacks
		if stacks > 1:
			name_label.text += " [x%d]" % stacks
	rarity_label.text = _rarity_name

func update_border() -> void:
	if border_rect:
		border_rect.border_color = GameColors.PANEL_BORDER_DEFAULT
		border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
		border_rect.interior_color = _rarity_color
		border_rect.update_shader_parameters()
		
	_update_sub_panel_borders(_rarity_color.lightened(0.5))

func update_sprite() -> void:
	if _unit_instance:
		if _unit_instance.data and _unit_instance.data.sprite:
			sprite_rect.visible = true
			fallback_label.visible = false
			sprite_rect.texture = _unit_instance.data.sprite
			if not sprite_rect.material:
				var mat: ShaderMaterial = ShaderMaterial.new()
				mat.shader = CHROMA_KEY_SHADER
				sprite_rect.material = mat
		else:
			sprite_rect.visible = false
			fallback_label.visible = true
			fallback_label.text = _unit_instance.get_unit_name().left(1).to_upper()
	elif _item_card:
		sprite_rect.visible = false
		fallback_label.visible = true
		if _item_card.data and _item_card.data.is_clickable:
			fallback_label.text = "📦"
		else:
			fallback_label.text = "🎁"
	elif _relic_instance:
		var relic_data: RelicData = _relic_instance.data
		var sprite_tex: Texture2D = relic_data.sprite if relic_data else null
		if sprite_tex:
			sprite_rect.visible = true
			fallback_label.visible = false
			sprite_rect.texture = sprite_tex
			if not sprite_rect.material:
				var mat: ShaderMaterial = ShaderMaterial.new()
				mat.shader = CHROMA_KEY_SHADER
				sprite_rect.material = mat
		else:
			sprite_rect.visible = false
			fallback_label.visible = true
			fallback_label.text = "📦"


func update_badge() -> void:
	if not _unit_instance:
		return

	var types: Array[UnitType] = _unit_instance.get_types()
	if not types.is_empty():
		badge_panel.visible = true
		if badge_container_panel:
			badge_container_panel.visible = true
		var first_type: UnitType = types[0]
		badge_label.text = first_type.type_name.to_upper()
		
		var flat_style: StyleBoxFlat = StyleBoxFlat.new()
		flat_style.bg_color = first_type.color
		flat_style.content_margin_left = 8
		flat_style.content_margin_right = 8
		flat_style.content_margin_top = 3
		flat_style.content_margin_bottom = 3
		badge_panel.add_theme_stylebox_override("panel", flat_style)
	else:
		badge_panel.visible = false
		if badge_container_panel:
			badge_container_panel.visible = false

func update_stats() -> void:
	if not _unit_instance:
		return
		
	var active_stats: PackedStringArray = PackedStringArray()
	active_stats.append("%s [color=%s]HP[/color]" % [NumberFormatter.format_large_number(_unit_instance.get_max_health()), GameColors.DESC_HEALTH])

	active_stats.append(str(_unit_instance.get_cast_speed()).trim_suffix(".0") + " [color=%s]CD[/color]" % GameColors.DESC_CAST_SPEED)

	if _unit_instance.get_attack() > 0:
		active_stats.append("%s [color=%s]ATK[/color]" % [NumberFormatter.format_large_number(_unit_instance.get_attack()), GameColors.DESC_ATTACK])
	if _unit_instance.heal > 0:
		active_stats.append("%s [color=%s]HEAL[/color]" % [NumberFormatter.format_large_number(_unit_instance.heal), GameColors.DESC_HEAL])
	if _unit_instance.shield > 0:
		active_stats.append("%s [color=%s]SHIELD[/color]" % [NumberFormatter.format_large_number(_unit_instance.shield), GameColors.DESC_SHIELD])
	if _unit_instance.poison > 0:
		active_stats.append("%s [color=%s]POISON[/color]" % [NumberFormatter.format_large_number(_unit_instance.poison), GameColors.DESC_POISON])
	if _unit_instance.burn > 0:
		active_stats.append("%s [color=%s]BURN[/color]" % [NumberFormatter.format_large_number(_unit_instance.burn), GameColors.DESC_BURN])
	if _unit_instance.electrocute > 0:
		active_stats.append("%s [color=%s]ELEC[/color]" % [NumberFormatter.format_large_number(_unit_instance.electrocute), GameColors.DESC_ELECTROCUTE])

	# Node reuse (Object pooling) logic
	var needed_labels: int = active_stats.size()
	var existing_children: Array[Node] = stats_grid.get_children()
	
	# Add labels if we don't have enough
	while existing_children.size() < needed_labels:
		var new_lbl: RichTextLabel = stat_label_template.duplicate() as RichTextLabel
		stats_grid.add_child(new_lbl)
		existing_children.append(new_lbl)
		
	# Update all labels text and visibility
	for idx: int in range(existing_children.size()):
		var lbl: RichTextLabel = existing_children[idx] as RichTextLabel
		if idx < needed_labels:
			if idx < active_stats.size():
				lbl.text = active_stats[idx]
			else:
				lbl.text = ""
			lbl.visible = true
		else:
			lbl.visible = false

func update_description() -> void:
	var full_desc: String = ""
	if _unit_instance:
		if _unit_instance.data:
			var modifier: UnitModifier = _unit_instance.data.modifier
			if modifier:
				full_desc += modifier.get_description(_unit_instance.level)
	elif _item_card:
		if _item_card.data and _item_card.data.modifier:
			full_desc += _item_card.data.modifier.get_description()
	elif _relic_instance:
		var relic_data: RelicData = _relic_instance.data
		if relic_data and relic_data.modifier:
			var modifier: RelicModifier = relic_data.modifier
			if modifier:
				full_desc += modifier.get_description(_relic_instance)
			
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
		
	# Clear old nodes
	for child: Node in keywords_vbox.get_children():
		child.queue_free()
		
	var keywords: Array[Dictionary] = KeywordDatabase.get_keywords_for_unit(_unit_instance, _unit_instance.level)
	for kw: Dictionary in keywords:
		var panel: PanelContainer = _create_keyword_panel(str(kw["title"]), str(kw["desc"]))
		keywords_vbox.add_child(panel)

func _create_keyword_panel(title: String, desc: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 0)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	
	var border: ShaderBorderDecorator = ShaderBorderDecorator.new()
	border.border_type = ShaderBorderDecorator.BorderType.DOUBLE
	border.interior_color = Color(1.0, 1.0, 1.0) # Solid white background
	border.outer_border_width = 2
	border.inner_border_width = 2
	border.border_indentation = 1
	panel.add_child(border)
	
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	
	var title_lbl: Label = Label.new()
	title_lbl.text = title.to_upper()
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2)) # Gold title
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.12, 0.13)) # Dark outline
	title_lbl.add_theme_constant_override("outline_size", 4)
	vbox.add_child(title_lbl)
	
	var desc_lbl: RichTextLabel = RichTextLabel.new()
	desc_lbl.bbcode_enabled = true
	desc_lbl.text = "[color=#2c3e50][font_size=12]%s[/font_size][/color]" % desc
	desc_lbl.fit_content = true
	desc_lbl.selection_enabled = false
	desc_lbl.scroll_active = false
	vbox.add_child(desc_lbl)
	
	margin.add_child(vbox)
	panel.add_child(margin)
	
	panel.ready.connect(func() -> void:
		border.update_shader_parameters()
	)
	
	_set_mouse_filter_ignore_recursive(panel)
	return panel


func _update_keywords_visibility(show_keywords: bool) -> void:
	if not keywords_vbox:
		return
	var has_keywords: bool = keywords_vbox.get_child_count() > 0
	keywords_vbox.visible = show_keywords and has_keywords
