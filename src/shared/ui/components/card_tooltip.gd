class_name CardTooltip
extends MarginContainer

@onready var border_rect: ShaderBorderDecorator = $BorderRect
@onready var name_label: Label = %NameLabel
@onready var rarity_label: Label = %RarityLabel
@onready var sprite_rect: TextureRect = %SpriteRect
@onready var fallback_label: Label = %FallbackLabel
@onready var badge_panel: PanelContainer = %BadgePanel
@onready var badge_label: Label = %BadgeLabel
@onready var stats_panel: PanelContainer = %StatsPanel
@onready var stats_label: Label = %StatsLabel
@onready var desc_panel: PanelContainer = %DescPanel
@onready var desc_label: RichTextLabel = %DescLabel

# Cache border panels as @onready to avoid runtime lookup issues
@onready var portrait_border_rect: ShaderBorderDecorator = %PortraitBorderRect
@onready var sprite_border_rect: ShaderBorderDecorator = %SpriteBorderRect
@onready var stats_border_rect: ShaderBorderDecorator = %StatsBorderRect
@onready var desc_border_rect: ShaderBorderDecorator = %DescBorderRect
@onready var help_border_rect: ShaderBorderDecorator = %HelpBorderRect

var _unit_instance: UnitInstance
var _item_card: ShopItemInstance
var _rarity_name: String = "COMMON"
var _rarity_color: Color = GameColors.BORDER_OUTER_DEFAULT

var _keywords_vbox: VBoxContainer
var _main_hbox: HBoxContainer
var _main_tooltip_wrapper: PanelContainer

func _ready() -> void:
	# Restructure scene to allow keywords on the left and main card tooltip on the right
	_main_hbox = HBoxContainer.new()
	_main_hbox.alignment = BoxContainer.ALIGNMENT_END
	_main_hbox.add_theme_constant_override("separation", 10)
	_main_hbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	_keywords_vbox = VBoxContainer.new()
	_keywords_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	_keywords_vbox.add_theme_constant_override("separation", 8)
	_keywords_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_keywords_vbox.visible = false
	_main_hbox.add_child(_keywords_vbox)
	
	_main_tooltip_wrapper = PanelContainer.new()
	_main_tooltip_wrapper.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_main_tooltip_wrapper.custom_minimum_size = custom_minimum_size
	_main_tooltip_wrapper.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_main_hbox.add_child(_main_tooltip_wrapper)
	
	# Add _main_hbox to tree first
	add_child(_main_hbox)
	
	var children_to_move: Array[Node] = []
	for child in get_children():
		if child != _main_hbox:
			children_to_move.append(child)
			
	for child in children_to_move:
		remove_child(child)
		_main_tooltip_wrapper.add_child(child)
	
	if _unit_instance:
		_setup_unit_ui()
		_build_keywords()
	elif _item_card:
		_setup_item_ui()

	_set_mouse_filter_ignore_recursive(self)
	
	# Make sure the parent container (PreviewContainer) also ignores mouse inputs
	# as its invisible boundaries expand to fit the keywords column.
	var parent_node: Node = get_parent()
	if parent_node and parent_node is Control:
		(parent_node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _set_mouse_filter_ignore_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_ignore_recursive(child)

func setup_for_unit(unit_instance: UnitInstance) -> void:
	_unit_instance = unit_instance
	_item_card = null
	if is_node_ready():
		_setup_unit_ui()
		_build_keywords()

func setup_for_item(item_card: ShopItemInstance) -> void:
	_item_card = item_card
	_unit_instance = null
	if is_node_ready():
		_setup_item_ui()
		if _keywords_vbox:
			for child in _keywords_vbox.get_children():
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
		
	# 1. Header
	name_label.text = _item_card.item_name.to_upper()
	rarity_label.text = "ITEM"
	
	# 2. Main Outer Border
	if border_rect:
		border_rect.border_color = GameColors.PANEL_BORDER_DEFAULT
		border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
		border_rect.interior_color = Color(0.9, 0.6, 0.1) # Golden orange background for items
		border_rect.update_shader_parameters()
		
	_update_sub_panel_borders(Color(0.9, 0.6, 0.1).lightened(0.5))
		
	# 3. Sprite (Item fallback character icon)
	sprite_rect.visible = false
	fallback_label.visible = true
	if _item_card.item_name == "Apple":
		fallback_label.text = "🍎"
	elif _item_card.item_name == "Sword":
		fallback_label.text = "⚔️"
	else:
		fallback_label.text = "🎁"
		
	# 4. Badge
	badge_panel.visible = true
	badge_label.text = "ITEM"
	var flat_style: StyleBoxFlat = StyleBoxFlat.new()
	flat_style.bg_color = Color(0.35, 0.65, 0.55) # Teal/greyish green matching reference item label bg
	flat_style.content_margin_left = 8
	flat_style.content_margin_right = 8
	flat_style.content_margin_top = 3
	flat_style.content_margin_bottom = 3
	badge_panel.add_theme_stylebox_override("panel", flat_style)
	
	# 5. Stats (Items do not display a stat block)
	stats_panel.visible = false
	
	# 6. Description
	var desc: String = ""
	if _item_card.stat_boost_attack > 0:
		desc += "Give a unit +%d Attack." % _item_card.stat_boost_attack
	if _item_card.stat_boost_hp > 0:
		if not desc.is_empty():
			desc += " "
		desc += "Give a unit +%d Health." % _item_card.stat_boost_hp
		
	desc_panel.visible = true
	desc_label.text = "[center]%s[/center]" % desc

func _update_sub_panel_borders(border_col: Color) -> void:
	var panels: Array[ShaderBorderDecorator] = [
		portrait_border_rect,
		sprite_border_rect,
		stats_border_rect,
		desc_border_rect,
		help_border_rect
	]

	for rect: ShaderBorderDecorator in panels:
		if rect:
			rect.border_color = border_col
			rect.interior_color = Color(1, 1, 1, 1)
			rect.update_shader_parameters()

func update_header() -> void:
	if _unit_instance:
		name_label.text = _unit_instance.get_unit_name().to_upper() + " [Lvl %d]" % _unit_instance.level
	rarity_label.text = _rarity_name

func update_border() -> void:
	# UPDATE BORDER
	if border_rect:
		border_rect.border_color = GameColors.PANEL_BORDER_DEFAULT
		border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
		border_rect.interior_color = _rarity_color
		border_rect.update_shader_parameters()
		
	_update_sub_panel_borders(_rarity_color.lightened(0.5))

func update_sprite() -> void:
	if not _unit_instance:
		return
	if _unit_instance.data and _unit_instance.data.sprite:
		sprite_rect.visible = true
		fallback_label.visible = false
		sprite_rect.texture = _unit_instance.data.sprite
		if not sprite_rect.material:
			var shader: Shader = load("res://src/shared/shaders/chroma_key.gdshader")
			var mat: ShaderMaterial = ShaderMaterial.new()
			mat.shader = shader
			sprite_rect.material = mat
	else:
		sprite_rect.visible = false
		fallback_label.visible = true
		fallback_label.text = _unit_instance.get_unit_name().left(1).to_upper()

func update_badge() -> void:
	if not _unit_instance:
		return
	var types: Array[UnitType] = _unit_instance.get_types()
	if not types.is_empty():
		badge_panel.visible = true
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

func update_stats() -> void:
	if not _unit_instance:
		return
		
	var stats_text: String = "%d HP" % _unit_instance.get_max_health()
	if _unit_instance.get_attack() > 0:
		stats_text += "   |   %d ATK" % _unit_instance.get_attack()
	if _unit_instance.heal > 0:
		stats_text += "   |   %d Heal" % _unit_instance.heal
	if _unit_instance.shield > 0:
		stats_text += "   |   %d Shield" % _unit_instance.shield
	if _unit_instance.burn > 0:
		stats_text += "   |   %d Burn" % _unit_instance.burn
	if _unit_instance.electrocute > 0:
		stats_text += "   |   %d Electro" % _unit_instance.electrocute
	stats_text += "   |   %.1fs" % _unit_instance.get_cast_speed()
	if _unit_instance.poison > 0:
		stats_text += "   |   %d Poison" % _unit_instance.poison
		
	stats_label.text = stats_text

func update_description() -> void:
	if not _unit_instance:
		return
	var full_desc: String = ""
	if _unit_instance.data:
		var modifier: UnitModifier = _unit_instance.data.modifier
		if modifier:
			if not full_desc.is_empty():
				full_desc += "\n\n"
			full_desc += modifier.get_description(_unit_instance.level)
			
	if not full_desc.is_empty():
		desc_panel.visible = true
		desc_label.text = "[center]%s[/center]" % full_desc
	else:
		desc_panel.visible = false

func _process(_delta: float) -> void:
	if visible:
		var shift_pressed: bool = not Input.is_key_pressed(KEY_SHIFT)
		_update_keywords_visibility(shift_pressed)

func _build_keywords() -> void:
	if not _keywords_vbox:
		return
		
	# Clear old nodes
	for child in _keywords_vbox.get_children():
		child.queue_free()
		
	var keywords: Array[Dictionary] = _get_relevant_keywords()
	for kw in keywords:
		var panel: PanelContainer = _create_keyword_panel(kw["title"], kw["desc"])
		_keywords_vbox.add_child(panel)

func _create_keyword_panel(title: String, desc: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 0)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	
	var border: ShaderBorderDecorator = ShaderBorderDecorator.new()
	border.border_type = ShaderBorderDecorator.BorderType.SINGLE
	border.border_color = Color(0.5, 0.55, 0.6) # Lighter steel grey border
	border.interior_color = Color(1.0, 1.0, 1.0) # Solid white background
	border.outer_border_width = 2
	border.inner_border_width = 0
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

func _get_relevant_keywords() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	if not _unit_instance:
		return list
		
	# 1. Combat stats / status effects
	if _unit_instance.shield > 0:
		list.append({"title": "Shield", "desc": "Absorbs incoming damage before it affects the team health pool."})
	if _unit_instance.heal > 0:
		list.append({"title": "Heal", "desc": "Restores team health up to its maximum capacity."})
	if _unit_instance.poison > 0:
		list.append({"title": "Poison", "desc": "Deals damage equal to the number of stacks every 1.0 second."})
	if _unit_instance.burn > 0:
		list.append({"title": "Burn", "desc": "Deals damage equal to the number of stacks every 0.5 seconds, then decreases by 1 stack."})
	if _unit_instance.electrocute > 0:
		list.append({"title": "Electrocute", "desc": "Increases the next damage received by the team by the number of stacks."})
		
	# 2. Modifier properties
	if _unit_instance.data and _unit_instance.data.modifier:
		var mod: UnitModifier = _unit_instance.data.modifier
		var lvl: int = _unit_instance.level
		
		# Trigger
		match mod.trigger:
			UnitModifier.Trigger.ON_CAST:
				list.append({"title": "On Cast", "desc": "Triggers immediately after this unit performs its main action (cast timer reaches maximum)."})
			UnitModifier.Trigger.ON_BATTLE_START:
				list.append({"title": "On Battle Start", "desc": "Triggers once at the very beginning of the combat phase."})
			UnitModifier.Trigger.ON_TAKE_DAMAGE:
				list.append({"title": "On Take Damage", "desc": "Triggers whenever the team health pool takes damage."})
				
		# Target
		var target_type: UnitModifier.TargetType = mod.get_target(lvl)
		match target_type:
			UnitModifier.TargetType.HORIZONTAL:
				list.append({"title": "Horizontal", "desc": "Targets allies directly adjacent horizontally (left and right neighbors)."})
			UnitModifier.TargetType.HORIZONTAL_PLUS:
				list.append({"title": "Horizontal+", "desc": "Targets all other allies in the same row."})
			UnitModifier.TargetType.VERTICAL:
				list.append({"title": "Vertical", "desc": "Targets allies directly above or below this unit."})
			UnitModifier.TargetType.ADJACENT:
				list.append({"title": "Adjacent", "desc": "Targets all adjacent allies (left, right, up, down neighbors)."})
			UnitModifier.TargetType.UP:
				list.append({"title": "Up", "desc": "Targets the ally directly above this unit."})
			UnitModifier.TargetType.DOWN:
				list.append({"title": "Down", "desc": "Targets the ally directly below this unit."})
			UnitModifier.TargetType.LEFT:
				list.append({"title": "Left", "desc": "Targets the ally directly to the left."})
			UnitModifier.TargetType.RIGHT:
				list.append({"title": "Right", "desc": "Targets the ally directly to the right."})
			UnitModifier.TargetType.LEFT_PLUS:
				list.append({"title": "Left+", "desc": "Targets all allies to the left of this unit in the same row."})
			UnitModifier.TargetType.RIGHT_PLUS:
				list.append({"title": "Right+", "desc": "Targets all allies to the right of this unit in the same row."})
			UnitModifier.TargetType.ALL:
				list.append({"title": "All", "desc": "Targets all other allies in the team."})

		# Duration
		var is_perm: bool = false
		if mod.has_method("is_permanent"):
			is_perm = mod.is_permanent(lvl)
		if is_perm:
			list.append({"title": "Permanent", "desc": "Effects permanently modify the unit's base stats and persist across rounds."})
		else:
			list.append({"title": "For Battle", "desc": "Effects last only for the duration of the current combat phase and reset afterward."})
			
		# 3. Specific modifier script name checks for implied keywords
		var mod_script_path: String = ""
		var mod_script: Script = mod.get_script() as Script
		if mod_script:
			mod_script_path = mod_script.resource_path.get_file().to_lower()
			
		if ("forest_guardian" in mod_script_path or "river_crab" in mod_script_path) and not _has_keyword(list, "Shield"):
			list.append({"title": "Shield", "desc": "Absorbs incoming damage before it affects the team health pool."})
		if "wild_wolf" in mod_script_path and not _has_keyword(list, "Heal"):
			list.append({"title": "Heal", "desc": "Restores team health up to its maximum capacity."})
		if "red_dragon" in mod_script_path and not _has_keyword(list, "Burn"):
			list.append({"title": "Burn", "desc": "Deals damage equal to the number of stacks every 0.5 seconds, then decreases by 1 stack."})
		if ("chronomancer" in mod_script_path or "spellweaver" in mod_script_path) and not _has_keyword(list, "Cast Speed"):
			list.append({"title": "Cast Speed", "desc": "The speed at which this unit charges its action bar to perform actions."})
		if "golden_beetle" in mod_script_path and not _has_keyword(list, "Gold"):
			list.append({"title": "Gold", "desc": "Currency used in the shop phase to buy, reroll, or upgrade units."})

	return list

func _has_keyword(list: Array[Dictionary], title: String) -> bool:
	for item in list:
		if item["title"] == title:
			return true
	return false

func _update_keywords_visibility(show_keywords: bool) -> void:
	if not _keywords_vbox:
		return
	var has_keywords: bool = _keywords_vbox.get_child_count() > 0
	_keywords_vbox.visible = show_keywords and has_keywords
