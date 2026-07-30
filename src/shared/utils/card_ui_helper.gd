class_name CardUIHelper
extends Object

const CARD_SIZE: Vector2 = Vector2(100, 100)
const CARD_SLOT_SIZE_DEFAULT: Vector2 = Vector2(100, 100)
const CARD_SLOT_SIZE_SHOP: Vector2 = Vector2(100, 90)

## Visual composition method for backward-compatibility
static func setup_card_visuals(
	unit_instance: UnitInstance,
	stats_bar: UnitStatsBar,
	sprite_rect: TextureRect,
	fallback_label: Label,
	left_ind: Control = null,
	right_ind: Control = null,
	top_ind: Control = null,
	bottom_ind: Control = null
) -> void:
	setup_stats(unit_instance, stats_bar)
	setup_portrait(unit_instance, sprite_rect, fallback_label)
	setup_indicators(unit_instance, left_ind, right_ind, top_ind, bottom_ind)

## Configures combat stats inside a stats bar container
static func setup_stats(unit_instance: UnitInstance, stats_bar: UnitStatsBar) -> void:
	stats_bar.setup_stats(unit_instance)

## Configures portrait sprite or name-fallback when no texture exists
static func setup_portrait(unit_instance: UnitInstance, sprite_rect: TextureRect, fallback_label: Label) -> void:		
	if unit_instance.data.sprite:
		sprite_rect.visible = true
		fallback_label.visible = false
		sprite_rect.texture = unit_instance.data.sprite
	else:
		sprite_rect.visible = false
		fallback_label.visible = true
		fallback_label.text = unit_instance.get_unit_name().to_upper()


## Configures direction indicators using Control (ColorRect/Panel) and indicator_arrow shader
static func setup_indicators(
	unit_instance: UnitInstance,
	left_ind: Control = null,
	right_ind: Control = null,
	top_ind: Control = null,
	bottom_ind: Control = null
) -> void:
	if left_ind: left_ind.visible = false
	if right_ind: right_ind.visible = false
	if top_ind: top_ind.visible = false
	if bottom_ind: bottom_ind.visible = false
	
	if not unit_instance or not unit_instance.data or not unit_instance.data.modifier:
		return
		
	var is_plus: bool = false
	var target_type: UnitModifier.TargetType = unit_instance.data.modifier.get_target(unit_instance.level)
	is_plus = (target_type == UnitModifier.TargetType.LEFT_PLUS or
			   target_type == UnitModifier.TargetType.RIGHT_PLUS or
			   target_type == UnitModifier.TargetType.HORIZONTAL_PLUS or
			   target_type == UnitModifier.TargetType.ALL)
			   
	var target_color: Color = Color(1.0, 0.85, 0.2) if is_plus else Color(0.28, 0.31, 0.35, 1.0)
	
	var indicators: Array[Control] = []
	if left_ind: indicators.append(left_ind)
	if right_ind: indicators.append(right_ind)
	if top_ind: indicators.append(top_ind)
	if bottom_ind: indicators.append(bottom_ind)
	
	for ind: Control in indicators:
		if ind is ColorRect:
			(ind as ColorRect).color = target_color
		else:
			ind.modulate = target_color
			
		var mat: ShaderMaterial = ind.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("size", ind.size)

	match target_type:
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
