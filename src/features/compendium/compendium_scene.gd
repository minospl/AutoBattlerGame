class_name CompendiumScene
extends Control

signal back_requested

enum Category {
	MONSTERS,
	ITEMS,
	RELICS
}

@onready var grid_container: GridContainer = %GridContainer
@onready var preview_container: Control = %PreviewContainer
@onready var back_button: Button = %BackButton
@onready var main_hbox: HBoxContainer = %MainHBox
@onready var preview_panel: Control = %PreviewPanel

@onready var monsters_tab: Button = %MonstersTab
@onready var items_tab: Button = %ItemsTab
@onready var relics_tab: Button = %RelicsTab

var run_state: RunState
var preview_tooltip: CardTooltip
var grid_item_scene: PackedScene = preload("res://src/features/compendium/compendium_grid_item.tscn")
var tooltip_scene: PackedScene = preload("res://src/shared/ui/components/card_tooltip.tscn")

func setup(p_state: RunState) -> void:
	run_state = p_state
	if is_node_ready():
		_load_category(Category.MONSTERS)

func _ready() -> void:
	# Setup the side preview panel
	preview_tooltip = tooltip_scene.instantiate() as CardTooltip
	# Adjust sizes so the tooltip matches the 320px column width and stretches vertically
	preview_tooltip.custom_minimum_size = Vector2(320, 0)
	
	var main_wrapper: Control = preview_tooltip.find_child("MainTooltipWrapper") as Control
	if main_wrapper:
		main_wrapper.custom_minimum_size = Vector2(320, 0)
		main_wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
	preview_tooltip.grow_horizontal = GROW_DIRECTION_BEGIN
	preview_container.add_child(preview_tooltip)
	preview_tooltip.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	
	# Reset offsets so it perfectly fills the 320px column from top to bottom
	preview_tooltip.offset_right = 0
	preview_tooltip.offset_left = -320
	preview_tooltip.offset_top = 0
	preview_tooltip.offset_bottom = 0
	
	preview_tooltip.visible = false

	# Connect buttons
	back_button.pressed.connect(func() -> void: back_requested.emit())
	monsters_tab.pressed.connect(func() -> void: _load_category(Category.MONSTERS))
	items_tab.pressed.connect(func() -> void: _load_category(Category.ITEMS))
	relics_tab.pressed.connect(func() -> void: _load_category(Category.RELICS))

	grid_container.resized.connect(_on_grid_container_resized)

	# Load default category if run_state has been injected early
	_load_category(Category.MONSTERS)

func _load_category(category: Category) -> void:
	# Clear grid
	for child: Node in grid_container.get_children():
		child.queue_free()
		
	# Select active tab button styling
	_update_tab_buttons_styling(category)

	if not run_state:
		return

	var templates: Array[Resource] = []
	if category == Category.MONSTERS:
		for t: UnitData in run_state.unit_templates:
			templates.append(t)
	elif category == Category.ITEMS:
		for t: ItemData in run_state.item_templates:
			templates.append(t)
	elif category == Category.RELICS:
		for t: RelicData in run_state.relic_templates:
			templates.append(t)

	# Sort templates by rarity first, then by name alphabetically
	templates.sort_custom(func(a: Resource, b: Resource) -> bool:
		var w_a: int = _get_rarity_weight(a)
		var w_b: int = _get_rarity_weight(b)
		if w_a != w_b:
			return w_a < w_b
		return _get_resource_name(a).casecmp_to(_get_resource_name(b)) < 0
	)

	var first_item: CompendiumGridItem = null
	
	for temp: Resource in templates:
		var grid_item: CompendiumGridItem = grid_item_scene.instantiate() as CompendiumGridItem
		if grid_item:
			grid_container.add_child(grid_item)
			grid_item.data_resource = temp
			grid_item.hovered.connect(_on_grid_item_hovered)
			grid_item.level_changed.connect(_on_grid_item_level_changed)
			if first_item == null:
				first_item = grid_item
				
	# Show preview of the first item by default if available
	if first_item:
		_update_preview(first_item.data_resource, first_item.unit_level)
	else:
		if preview_tooltip:
			preview_tooltip.visible = false

	_recalculate_grid_sizes()

func _on_grid_item_hovered(grid_item: CompendiumGridItem, is_hover: bool) -> void:
	if is_hover:
		_update_preview(grid_item.data_resource, grid_item.unit_level)

func _on_grid_item_level_changed(grid_item: CompendiumGridItem) -> void:
	_update_preview(grid_item.data_resource, grid_item.unit_level)

func _update_preview(resource: Resource, p_level: int = 1) -> void:
	if not preview_tooltip:
		return
		
	if resource is UnitData:
		var unit_data: UnitData = resource as UnitData
		var inst: UnitInstance = UnitInstance.new()
		inst.initialize(unit_data)
		for i: int in range(p_level - 1):
			inst.level_up()
		preview_tooltip.setup_for_unit(inst)
		preview_tooltip.visible = true
	elif resource is ItemData:
		var item_data: ItemData = resource as ItemData
		var inst: ItemInstance = ItemInstance.new()
		inst.initialize(item_data)
		preview_tooltip.setup_for_item(inst)
		preview_tooltip.visible = true
	elif resource is RelicData:
		var relic_data: RelicData = resource as RelicData
		var inst: RelicInstance = RelicInstance.new()
		inst.initialize(relic_data)
		preview_tooltip.setup_for_relic(inst)
		preview_tooltip.visible = true

func _update_tab_buttons_styling(category: Category) -> void:
	var set_decorator_styling: Callable = func(btn: Button, is_active: bool) -> void:
		var dec: GameButtonDecorator = btn.get_node_or_null("GameButtonDecorator") as GameButtonDecorator
		var normal: Color = GameColors.TAB_ACTIVE_NORMAL if is_active else GameColors.TAB_INACTIVE_NORMAL
		var hover: Color = GameColors.TAB_ACTIVE_HOVER if is_active else GameColors.TAB_INACTIVE_HOVER
		var pressed: Color = GameColors.TAB_ACTIVE_PRESSED if is_active else GameColors.TAB_INACTIVE_PRESSED
		
		dec.normal_color = normal
		dec.hover_color = hover
		dec.pressed_color = pressed
		
		var current_color: Color = normal
		if btn.button_pressed or btn.is_hovered():
			current_color = hover
		dec.mat.set_shader_parameter("interior_color", current_color)
				
	set_decorator_styling.call(monsters_tab, category == Category.MONSTERS)
	set_decorator_styling.call(items_tab, category == Category.ITEMS)
	set_decorator_styling.call(relics_tab, category == Category.RELICS)

func _get_rarity_weight(resource: Resource) -> int:
	var rarity_res: Rarity = null
	if resource is UnitData:
		rarity_res = (resource as UnitData).rarity
	elif resource is ItemData:
		rarity_res = (resource as ItemData).rarity
	elif resource is RelicData:
		rarity_res = (resource as RelicData).rarity
		
	if not rarity_res:
		return -1
		
	var rname: String = rarity_res.rarity_name.to_lower()
	match rname:
		"common":
			return 0
		"rare":
			return 1
		"epic":
			return 2
		"legendary":
			return 3
		"unique":
			return 4
		_:
			return 5

func _get_resource_name(resource: Resource) -> String:
	if resource is UnitData:
		return (resource as UnitData).unit_name
	if resource is ItemData:
		return (resource as ItemData).item_name
	if resource is RelicData:
		return (resource as RelicData).relic_name
	return ""

func _on_grid_container_resized() -> void:
	_recalculate_grid_sizes()

func _recalculate_grid_sizes() -> void:
	if not is_inside_tree():
		return
		
	var viewport_width: float = get_viewport_rect().size.x
	
	# Constant layout offsets from compendium_scene.tscn:
	# - MarginContainer margins: 32px left + 32px right = 64px
	# - MainHBox separation: 24px
	# - GridMargin margins: 16px left + 16px right = 32px
	# - PreviewPanel width: 320px
	# - Scrollbar buffer: 10px
	var layout_offset: float = 64.0 + 24.0 + 32.0 + 320.0 + 10.0
	
	var grid_width: float = viewport_width - layout_offset
	if grid_width <= 0:
		return
		
	# 5 columns means 4 gaps.
	var h_sep: int = grid_container.get_theme_constant("h_separation")
	var total_gaps: float = 4.0 * h_sep
	var available_width: float = grid_width - total_gaps
	if available_width <= 0:
		return
		
	var card_size: float = floor(available_width / 5.0)
	if card_size < 100:
		card_size = 100
		
	for child: Node in grid_container.get_children():
		if child is Control:
			(child as Control).custom_minimum_size = Vector2(100, card_size)
