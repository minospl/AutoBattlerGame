class_name CardTooltip
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
@onready var desc_label: RichTextLabel = %DescLabel

var _unit_instance: UnitInstance
var _item_card: ShopItemInstance

func _ready() -> void:
	# Ensure the container panel is transparent so only the decorator shader draws the background
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	
	if _unit_instance:
		_setup_unit_ui()
	elif _item_card:
		_setup_item_ui()

func setup_for_unit(unit_instance: UnitInstance) -> void:
	_unit_instance = unit_instance
	_item_card = null
	if is_node_ready():
		_setup_unit_ui()

func setup_for_item(item_card: ShopItemInstance) -> void:
	_item_card = item_card
	_unit_instance = null
	if is_node_ready():
		_setup_item_ui()

func _setup_unit_ui() -> void:
	if not _unit_instance:
		return
		
	# 1. Header
	name_label.text = _unit_instance.get_unit_name().to_upper()
	var rarity_name: String = "COMMON"
	var rarity_color: Color = GameColors.BORDER_OUTER_DEFAULT
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
			var shader: Shader = load("res://src/shared/shaders/chroma_key.gdshader")
			var mat: ShaderMaterial = ShaderMaterial.new()
			mat.shader = shader
			sprite_rect.material = mat
	else:
		sprite_rect.visible = false
		fallback_label.visible = true
		fallback_label.text = _unit_instance.get_unit_name().left(1).to_upper()
		
	# 4. Badge (Type)
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
		
	# 5. Stats
	stats_panel.visible = true
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
	
	# 6. Description
	var full_desc: String = ""
	if _unit_instance.data:
		var modifier: UnitModifier = _unit_instance.data.modifier
		if modifier:
			if not full_desc.is_empty():
				full_desc += "\n\n"
			full_desc += modifier.get_description()
			
	if not full_desc.is_empty():
		desc_panel.visible = true
		desc_label.text = "[center]%s[/center]" % full_desc
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
		%PortraitBorderRect,
		%SpriteBorderRect,
		%StatsBorderRect,
		%DescBorderRect,
		%HelpBorderRect
	]

	for rect: ShaderBorderDecorator in panels:
		rect.border_color = border_col
		rect.interior_color = Color(1, 1, 1, 1)
		rect.update_shader_parameters()
