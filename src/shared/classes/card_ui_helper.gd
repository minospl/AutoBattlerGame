class_name CardUIHelper
extends Object

## Shared helper to configure card unit visuals (Attack, Poison, sprite, indicators)
static func setup_card_visuals(
	unit_instance: UnitInstance,
	attack_label: Label,
	attack_panel: PanelContainer,
	poison_label: Label,
	poison_panel: PanelContainer,
	sprite_rect: TextureRect,
	fallback_label: Label,
	left_ind: Control = null,
	right_ind: Control = null,
	top_ind: Control = null,
	bottom_ind: Control = null
) -> void:
	if not unit_instance:
		return
		
	var stat_size = Vector2(32, 16)
	
	# 1. Gather all active stats (Attack, Heal, Poison, Shield, Thorns, Vampirism, Burn, Electrocute)
	var active_stats = []
	if unit_instance.get_attack() > 0:
		active_stats.append({"value": str(unit_instance.get_attack()), "color": GameColors.STAT_ATTACK_BG})
	if unit_instance.heal > 0:
		active_stats.append({"value": str(unit_instance.heal), "color": Color(0.15, 0.6, 0.3)}) # Green for heal
	if unit_instance.poison > 0:
		active_stats.append({"value": str(unit_instance.poison), "color": GameColors.STAT_POISON_BG})
	if unit_instance.shield > 0:
		active_stats.append({"value": str(unit_instance.shield), "color": Color(0.2, 0.5, 0.8)}) # Light Blue for shield
	if unit_instance.thorns > 0:
		active_stats.append({"value": str(unit_instance.thorns), "color": Color(0.55, 0.45, 0.2)}) # Brown for thorns
	if unit_instance.burn > 0:
		active_stats.append({"value": str(unit_instance.burn), "color": Color(0.9, 0.4, 0.1)}) # Orange for burn
	if unit_instance.electrocute > 0:
		active_stats.append({"value": str(unit_instance.electrocute), "color": Color(0.85, 0.75, 0.1)}) # Yellow for electrocute

	# Hide default panels initially
	if attack_panel:
		attack_panel.visible = false
	if poison_panel:
		poison_panel.visible = false

	# Clean up any previously duplicated dynamic panels
	var stats_hbox = attack_panel.get_parent() if attack_panel else null
	if stats_hbox:
		for child in stats_hbox.get_children():
			if child.name.begins_with("DynamicStatPanel"):
				child.free()

	# Dynamically populate panels for all active stats
	for i in range(active_stats.size()):
		var stat = active_stats[i]
		var panel: PanelContainer = null
		var label: Label = null
		
		if i == 0:
			panel = attack_panel
			label = attack_label
		elif i == 1:
			panel = poison_panel
			label = poison_label
		else:
			# If more than 2 stats are active, duplicate the poison panel dynamically
			if stats_hbox and poison_panel:
				panel = poison_panel.duplicate() as PanelContainer
				panel.name = "DynamicStatPanel"
				stats_hbox.add_child(panel)
				label = panel.find_child("*Label", true, false) as Label
				
		if panel:
			panel.visible = true
			if label:
				label.text = stat.value
			setup_stat_panel_shader(panel, stat.color, stat_size)
			
	# 2. Setup sprite / fallback portrait
	if sprite_rect and fallback_label:
		if unit_instance.data and unit_instance.data.sprite:
			sprite_rect.visible = true
			fallback_label.visible = false
			sprite_rect.texture = unit_instance.data.sprite
			
			if not sprite_rect.material:
				var shader = load("res://src/shared/shaders/chroma_key.gdshader")
				var mat = ShaderMaterial.new()
				mat.shader = shader
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
		
	if unit_instance.data and unit_instance.data.modifiers:
		for modifier in unit_instance.data.modifiers:
			match modifier.target:
				UnitModifier.TargetType.HORIZONTAL:
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
				UnitModifier.TargetType.LEFT:
					if left_ind: left_ind.visible = true
				UnitModifier.TargetType.RIGHT:
					if right_ind: right_ind.visible = true
				UnitModifier.TargetType.ALL:
					if left_ind: left_ind.visible = true
					if right_ind: right_ind.visible = true
					if top_ind: top_ind.visible = true
					if bottom_ind: bottom_ind.visible = true

## Setup background shaders for stats labels
static func setup_stat_panel_shader(panel: PanelContainer, bg_color: Color, stat_size: Vector2) -> void:
	panel.custom_minimum_size = stat_size
	var border_rect = panel.get_node_or_null("BorderRect") as ShaderBorderDecorator
	if border_rect:
		border_rect.border_color = bg_color.lightened(.2)
		border_rect.interior_color = bg_color
		border_rect.update_shader_parameters()

## Shared helper to configure item card visuals
static func setup_item_visuals(
	item_name: String,
	stat_boost_attack: int,
	stat_boost_hp: int,
	portrait_label: Label,
	sprite_rect: TextureRect,
	attack_panel: PanelContainer,
	attack_label: Label,
	hp_panel: PanelContainer,
	hp_label: Label,
	border_rect: ShaderBorderDecorator
) -> void:
	# 1. Outer Border style
	if border_rect:
		border_rect.border_color = Color(0.9, 0.6, 0.1) # Golden orange
		border_rect.inner_border_color = GameColors.BORDER_INNER_DEFAULT
		border_rect.interior_color = GameColors.WHITE_COLOR
		border_rect.update_shader_parameters()
		
	# 2. Portrait setup
	if sprite_rect:
		sprite_rect.visible = false
	if portrait_label:
		portrait_label.visible = true
		portrait_label.add_theme_color_override("font_color", GameColors.PORTRAIT_FALLBACK_TEXT)
		if item_name == "Apple":
			portrait_label.text = "🍎"
		elif item_name == "Sword":
			portrait_label.text = "⚔️"
		else:
			portrait_label.text = "🎁"
			
	# 3. Stats display
	var stat_size = Vector2(32, 16)
	if attack_panel and attack_label:
		if stat_boost_attack > 0:
			attack_panel.visible = true
			attack_label.text = "+" + str(stat_boost_attack)
			setup_stat_panel_shader(attack_panel, GameColors.STAT_ATTACK_BG, stat_size)
		else:
			attack_panel.visible = false
			
	if hp_panel and hp_label:
		if stat_boost_hp > 0:
			hp_panel.visible = true
			hp_label.text = "+" + str(stat_boost_hp)
			setup_stat_panel_shader(hp_panel, Color(0.15, 0.6, 0.3), stat_size) # Green for HP
		else:
			hp_panel.visible = false

## Tooltip Display Manager helpers
static func show_tooltip(tooltip: Control, unit_instance: UnitInstance) -> void:
	if tooltip and unit_instance:
		if tooltip.has_method("setup_for_unit"):
			tooltip.setup_for_unit(unit_instance)
			tooltip.visible = true

static func show_item_tooltip(tooltip: Control, item_card: Resource) -> void:
	if tooltip and item_card:
		if tooltip.has_method("setup_for_item"):
			tooltip.setup_for_item(item_card)
			tooltip.visible = true

static func hide_tooltip(tooltip: Control) -> void:
	if tooltip:
		tooltip.visible = false
