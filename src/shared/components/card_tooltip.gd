extends PanelContainer

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
@onready var desc_label: Label = %DescLabel

var _unit_instance: UnitInstance
var _item_card: ItemCard

func _ready() -> void:
	print("--- CardTooltip _ready() called. Unit: ", _unit_instance.get_unit_name() if _unit_instance else "none", ", Item: ", _item_card.item_name if _item_card else "none")
	# Ensure the container panel is transparent so only the decorator shader draws the background
	var transparent_style = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", transparent_style)
	
	if _unit_instance:
		_setup_unit_ui()
	elif _item_card:
		_setup_item_ui()

func setup_for_unit(unit_instance: UnitInstance) -> void:
	_unit_instance = unit_instance
	if is_node_ready():
		_setup_unit_ui()

func setup_for_item(item_card: ItemCard) -> void:
	_item_card = item_card
	if is_node_ready():
		_setup_item_ui()

func _setup_unit_ui() -> void:
	if not _unit_instance:
		return
		
	# 1. Header
	name_label.text = _unit_instance.get_unit_name().to_upper()
	var rarity_name = "COMMON"
	var rarity_color = GameColors.BORDER_OUTER_DEFAULT
	if _unit_instance.data and _unit_instance.data.rarity:
		rarity_name = _unit_instance.data.rarity.rarity_name.to_upper()
		rarity_color = _unit_instance.data.rarity.border_color
	rarity_label.text = rarity_name
	
	# 2. Main Outer Border (Double border Snapped)
	if border_rect:
		border_rect.border_color = GameColors.PANEL_BORDER_DEFAULT
		border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
		border_rect.interior_color = rarity_color
		border_rect.update_shader_parameters()
		
	_update_sub_panel_borders(rarity_color.lightened(0.5))
		
	# 3. Sprite/Artwork
	if _unit_instance.data and _unit_instance.data.sprite:
		sprite_rect.visible = true
		fallback_label.visible = false
		sprite_rect.texture = _unit_instance.data.sprite
		if not sprite_rect.material:
			var shader = load("res://src/shared/shaders/chroma_key.gdshader")
			var mat = ShaderMaterial.new()
			mat.shader = shader
			sprite_rect.material = mat
	else:
		sprite_rect.visible = false
		fallback_label.visible = true
		fallback_label.text = _unit_instance.get_unit_name().left(1).to_upper()
		
	# 4. Badge (Type)
	var types = _unit_instance.get_types()
	if not types.is_empty():
		badge_panel.visible = true
		var first_type = types[0]
		badge_label.text = first_type.type_name.to_upper()
		
		var flat_style = StyleBoxFlat.new()
		flat_style.bg_color = first_type.color
		flat_style.content_margin_left = 8
		flat_style.content_margin_right = 8
		flat_style.content_margin_top = 3
		flat_style.content_margin_bottom = 3
		badge_panel.add_theme_stylebox_override("panel", flat_style)
	else:
		badge_panel.visible = false
		
	# 5. Stats
	stats_panel.visible = true
	var stats_text = "%d HP   |   %d ATK" % [_unit_instance.get_max_health(), _unit_instance.get_attack()]
	if _unit_instance.poison > 0:
		stats_text += "   |   %d Poison" % _unit_instance.poison
	stats_label.text = stats_text
	
	# 6. Description
	if _unit_instance.data and not _unit_instance.data.description.is_empty():
		desc_panel.visible = true
		desc_label.text = _unit_instance.data.description
	else:
		desc_panel.visible = false

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
	var flat_style = StyleBoxFlat.new()
	flat_style.bg_color = Color(0.35, 0.65, 0.55) # Teal/greyish green matching reference item label bg
	flat_style.content_margin_left = 8
	flat_style.content_margin_right = 8
	flat_style.content_margin_top = 3
	flat_style.content_margin_bottom = 3
	badge_panel.add_theme_stylebox_override("panel", flat_style)
	
	# 5. Stats (Items do not display a stat block)
	stats_panel.visible = false
	
	# 6. Description
	var desc = ""
	if _item_card.stat_boost_attack > 0:
		desc += "Give a unit +%d Attack." % _item_card.stat_boost_attack
	if _item_card.stat_boost_hp > 0:
		if not desc.is_empty():
			desc += " "
		desc += "Give a unit +%d Health." % _item_card.stat_boost_hp
		
	desc_panel.visible = true
	desc_label.text = desc

func _update_sub_panel_borders(border_col: Color) -> void:
	var panels = [
		%PortraitBorderRect,
		%SpriteBorderRect,
		%StatsBorderRect,
		%DescBorderRect,
		%HelpBorderRect
	]
	for rect in panels:
		if rect and rect is ShaderBorderDecorator:
			rect.border_color = border_col
			rect.interior_color = Color(1, 1, 1, 1)
			rect.update_shader_parameters()
