class_name CardUIHelper
extends Object

const CARD_SIZE : Vector2 = Vector2(100, 100)
const CARD_SLOT_SIZE_DEFAULT : Vector2 = Vector2(100, 100)
const CARD_SLOT_SIZE_SHOP : Vector2 = Vector2(100, 125)

const CHROMA_KEY_SHADER: Shader = preload("res://src/shared/shaders/chroma_key.gdshader")

## Shared helper to configure card unit visuals (Attack, Poison, sprite, indicators)
static func setup_card_visuals(
	unit_instance: UnitInstance,
	stats_hbox: HBoxContainer,
	sprite_rect: TextureRect,
	fallback_label: Label,
	left_ind: Control = null,
	right_ind: Control = null,
	top_ind: Control = null,
	bottom_ind: Control = null
) -> void:
	if not unit_instance:
		return
		
	# 1. Gather all active stats (Attack, Heal, Poison, Shield, Burn, Electrocute)
	var candidates: Array[Dictionary] = []
	if unit_instance.get_attack() > 0:
		candidates.append({
			"name": "attack",
			"value": unit_instance.get_attack(),
			"color": Color(GameColors.DESC_ATTACK),
			"priority": 0
		})
	if unit_instance.heal > 0:
		candidates.append({
			"name": "heal",
			"value": unit_instance.heal,
			"color": Color(GameColors.DESC_HEAL),
			"priority": 1
		})
	if unit_instance.shield > 0:
		candidates.append({
			"name": "shield",
			"value": unit_instance.shield,
			"color": Color(GameColors.DESC_SHIELD),
			"priority": 2
		})
	if unit_instance.poison > 0:
		candidates.append({
			"name": "poison",
			"value": unit_instance.poison,
			"color": Color(GameColors.DESC_POISON),
			"priority": 3
		})
	if unit_instance.burn > 0:
		candidates.append({
			"name": "burn",
			"value": unit_instance.burn,
			"color": Color(GameColors.DESC_BURN),
			"priority": 4
		})
	if unit_instance.electrocute > 0:
		candidates.append({
			"name": "electrocute",
			"value": unit_instance.electrocute,
			"color": Color(GameColors.DESC_ELECTROCUTE),
			"priority": 5
		})

	# Sort candidates: highest value first, tie break using priority index
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.value != b.value:
			return a.value > b.value
		return a.priority < b.priority
	)

	# Keep only the top 3 stats for the card UI display
	var active_stats: Array[Dictionary] = []
	active_stats.assign(candidates.slice(0, 3))

	var stat_size: Vector2 = Vector2(30, 16)
		
	var template_panel: PanelContainer = stats_hbox.get_child(0) as PanelContainer if stats_hbox and stats_hbox.get_child_count() > 0 else null

	if stats_hbox and template_panel:
		stats_hbox.visible = true
		template_panel.visible = false
		
		# 1. Ensure we have enough child panels (up to active_stats.size() + 1)
		while stats_hbox.get_child_count() <= active_stats.size():
			var new_panel: PanelContainer = template_panel.duplicate() as PanelContainer
			stats_hbox.add_child(new_panel)
			
		# 2. Update and show the required panels, hide the rest
		for i: int in range(1, stats_hbox.get_child_count()):
			var panel: PanelContainer = stats_hbox.get_child(i) as PanelContainer
			var stat_idx: int = i - 1
			if stat_idx < active_stats.size():
				var stat: Dictionary = active_stats[stat_idx]
				panel.visible = true
				var label: Label = panel.find_child("*Label", true, false) as Label
				if label:
					var stat_val: int = stat.value
					label.text = NumberFormatter.format_large_number(stat_val)
				var stat_color: Color = stat.color
				setup_stat_panel_shader(panel, stat_color, stat_size)
			else:
				panel.visible = false
			
	# 2. Setup sprite / fallback portrait
	if sprite_rect and fallback_label:
		if unit_instance.data and unit_instance.data.sprite:
			sprite_rect.visible = true
			fallback_label.visible = false
			sprite_rect.texture = unit_instance.data.sprite
			
			if not sprite_rect.material:
				var mat: ShaderMaterial = ShaderMaterial.new()
				mat.shader = CHROMA_KEY_SHADER
				sprite_rect.material = mat
		else:
			sprite_rect.visible = false
			fallback_label.visible = true
			if unit_instance.data and not unit_instance.get_unit_name().is_empty():
				fallback_label.text = unit_instance.get_unit_name().left(1).to_upper()
				fallback_label.add_theme_color_override("font_color", GameColors.PORTRAIT_FALLBACK_TEXT)
			else:
				fallback_label.text = "?"
				fallback_label.add_theme_color_override("font_color", GameColors.PORTRAIT_FALLBACK_TEXT)
				
	# 3. Setup target direction indicators
	if left_ind:
		left_ind.visible = false
	if right_ind:
		right_ind.visible = false
	if top_ind:
		top_ind.visible = false
	if bottom_ind:
		bottom_ind.visible = false
		
	var is_plus: bool = false
	if unit_instance.data and unit_instance.data.modifier:
		var target_type: UnitModifier.TargetType = unit_instance.data.modifier.get_target(unit_instance.level)
		is_plus = (target_type == UnitModifier.TargetType.LEFT_PLUS or 
				   target_type == UnitModifier.TargetType.RIGHT_PLUS or 
				   target_type == UnitModifier.TargetType.HORIZONTAL_PLUS or
				   target_type == UnitModifier.TargetType.ALL)

	var target_color: Color = Color(1.0, 0.85, 0.2) if is_plus else Color(1.0, 1.0, 1.0)
	if left_ind: left_ind.modulate = target_color
	if right_ind: right_ind.modulate = target_color
	if top_ind: top_ind.modulate = target_color
	if bottom_ind: bottom_ind.modulate = target_color
	
	if unit_instance.data and unit_instance.data.modifier:
		var modifier: UnitModifier = unit_instance.data.modifier
		match modifier.get_target(unit_instance.level):
			UnitModifier.TargetType.HORIZONTAL, UnitModifier.TargetType.HORIZONTAL_PLUS:
				if left_ind: left_ind.visible = true
				if right_ind: right_ind.visible = true
			UnitModifier.TargetType.VERTICAL:
				if top_ind: top_ind.visible = true
				if bottom_ind: bottom_ind.visible = true
			UnitModifier.TargetType.ADJACENT:
				if left_ind: left_ind.visible = true
				if right_ind: right_ind.visible = true
				if top_ind: top_ind.visible = true
				if bottom_ind: bottom_ind.visible = true
			UnitModifier.TargetType.UP:
				if top_ind: top_ind.visible = true
			UnitModifier.TargetType.DOWN:
				if bottom_ind: bottom_ind.visible = true
			UnitModifier.TargetType.LEFT, UnitModifier.TargetType.LEFT_PLUS:
				if left_ind: left_ind.visible = true
			UnitModifier.TargetType.RIGHT, UnitModifier.TargetType.RIGHT_PLUS:
				if right_ind: right_ind.visible = true
			UnitModifier.TargetType.ALL:
				if left_ind: left_ind.visible = true
				if right_ind: right_ind.visible = true
				if top_ind: top_ind.visible = true
				if bottom_ind: bottom_ind.visible = true

## Setup background shaders for stats labels
static func setup_stat_panel_shader(panel: PanelContainer, bg_color: Color, stat_size: Vector2) -> void:
	panel.custom_minimum_size = stat_size
	var border_rect: ShaderBorderDecorator = panel.get_node_or_null("BorderRect") as ShaderBorderDecorator
	if border_rect:
		border_rect.border_color = bg_color.lightened(.2)
		border_rect.interior_color = bg_color
		border_rect.inner_border_width = 2
		border_rect.border_indentation = 1
		border_rect.update_shader_parameters()

static func setup_item_visuals(
	item_instance: ItemInstance,
	portrait_label: Label,
	sprite_rect: TextureRect,
	border_rect: ShaderBorderDecorator
) -> void:
	if not item_instance:
		return
		
	# 1. Outer Border style based on rarity
	if border_rect:
		var border_color: Color = Color(0.9, 0.6, 0.1) # Fallback to golden orange
		if item_instance.data and item_instance.data.rarity:
			border_color = item_instance.data.rarity.border_color
		border_rect.border_color = border_color
		border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
		border_rect.interior_color = GameColors.WHITE_COLOR
		border_rect.update_shader_parameters()
		
	# 2. Portrait setup
	if item_instance.data and item_instance.data.sprite:
		if sprite_rect:
			sprite_rect.visible = true
			sprite_rect.texture = item_instance.data.sprite
		if portrait_label:
			portrait_label.visible = false
	else:
		if sprite_rect:
			sprite_rect.visible = false
		if portrait_label:
			portrait_label.visible = true
			portrait_label.add_theme_color_override("font_color", GameColors.PORTRAIT_FALLBACK_TEXT)
			if item_instance.data and item_instance.data.is_clickable:
				portrait_label.text = "📦" # Chest emoji for relic chests
			else:
				portrait_label.text = "🎁" # Gift emoji for regular food items

## Tooltip Display Manager helpers
static func show_tooltip(tooltip: CardTooltip, unit_instance: UnitInstance) -> void:
	if tooltip and unit_instance:
		tooltip.setup_for_unit(unit_instance)
		tooltip.visible = true

static func show_item_tooltip(tooltip: CardTooltip, item_card: ItemInstance) -> void:
	if tooltip and item_card:
		tooltip.setup_for_item(item_card)
		tooltip.visible = true

static func show_relic_tooltip(tooltip: CardTooltip, relic: RelicInstance) -> void:
	if tooltip and relic:
		tooltip.setup_for_relic(relic)
		tooltip.visible = true

static func hide_tooltip(tooltip: CardTooltip) -> void:
	if tooltip:
		tooltip.visible = false
