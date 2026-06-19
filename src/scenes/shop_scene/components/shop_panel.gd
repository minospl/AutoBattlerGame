class_name ShopPanel
extends PanelContainer

signal roll_requested
signal sell_card_requested(card: Control, original_slot: MonsterSlot)

@onready var slots_hbox: HBoxContainer = %SlotsHBox
@onready var roll_button: Button = %RollButton
@onready var shop_header: PanelContainer = %ShopHeader
@onready var shop_label: Label = %ShopLabel
@onready var gold_label: Label = %GoldLabel
@onready var sell_overlay: MarginContainer = %SellOverlay
@onready var sell_panel: PanelContainer = %SellPanel
@onready var sell_label: Label = $SellOverlay/SellPanel/Center/SellLabel
@onready var border_decorator: PanelBorderDecorator = $PanelBorderDecorator

@export var gold: int = 10:
	set(val):
		gold = val
		_update_labels()

var slots: Array[MonsterSlot] = []

func _ready() -> void:
	# Shop Header Style (Blue Banner)
	var shop_header_style = StyleBoxFlat.new()
	var shop_color = Color(0.2, 0.55, 0.85, 1.0) # Sleek blue themed for Shop
	shop_header_style.bg_color = shop_color
	shop_header_style.border_width_bottom = 3
	shop_header_style.border_color = shop_color.lightened(0.5)
	shop_header_style.content_margin_bottom = 2
	shop_header_style.content_margin_left = 2
	shop_header.add_theme_stylebox_override("panel", shop_header_style)
	
	# Label outline styling
	shop_label.add_theme_color_override("font_outline_color", GameColors.LABEL_OUTLINE)
	shop_label.add_theme_constant_override("outline_size", 5)
	
	# Roll Button Styling (Premium Orange/Gold)
	var roll_normal = StyleBoxFlat.new()
	roll_normal.bg_color = Color(0.95, 0.6, 0.15, 1.0) # Golden orange
	roll_normal.corner_radius_top_left = 4
	roll_normal.corner_radius_top_right = 4
	roll_normal.corner_radius_bottom_right = 4
	roll_normal.corner_radius_bottom_left = 4
	roll_normal.content_margin_left = 8
	roll_normal.content_margin_right = 8
	roll_normal.content_margin_top = 4
	roll_normal.content_margin_bottom = 4
	roll_button.add_theme_stylebox_override("normal", roll_normal)
	
	var roll_hover = roll_normal.duplicate() as StyleBoxFlat
	roll_hover.bg_color = Color(1.0, 0.7, 0.2, 1.0) # Brighter orange
	roll_button.add_theme_stylebox_override("hover", roll_hover)
	
	var roll_pressed = roll_normal.duplicate() as StyleBoxFlat
	roll_pressed.bg_color = Color(0.8, 0.5, 0.1, 1.0)
	roll_button.add_theme_stylebox_override("pressed", roll_pressed)
	

	
	roll_button.pressed.connect(func(): roll_requested.emit())
		
	# Sell Overlay styling
	var sell_style = StyleBoxFlat.new()
	sell_style.bg_color = Color(0.292, 0.245, 0.092, 0.85)
	sell_panel.add_theme_stylebox_override("panel", sell_style)
	
	_update_labels()

func create_slots(slot_scene: PackedScene, slot_count: int) -> void:
	for child in slots_hbox.get_children():
		child.queue_free()
	slots.clear()
	
	for i in range(slot_count):
		var slot = slot_scene.instantiate() as MonsterSlot
		slot.is_shop_slot = true
		slot.slot_index = i
		slots_hbox.add_child(slot)
		slots.append(slot)

# Drag and drop logic for selling
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if sell_overlay and sell_overlay.visible:
		if typeof(data) == TYPE_DICTIONARY and data.has("card"):
			var original_slot = data["original_slot"] as MonsterSlot
			# Can only sell if it comes from team or bench (not a shop slot)
			if original_slot and not original_slot.is_shop_slot:
				var card = data["card"]
				# Only sell MonsterCard
				if card is MonsterCard:
					return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var card = data["card"]
	var original_slot = data["original_slot"] as MonsterSlot
	sell_card_requested.emit(card, original_slot)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		# Check if the dragged item is sellable by querying ShopScene's tracked drag state
		var shop_scene = get_tree().current_scene
		if shop_scene and shop_scene.get("dragged_card") != null:
			var card = shop_scene.dragged_card
			var original_slot = shop_scene.dragged_card_original_slot
			if card is MonsterCard and original_slot and not original_slot.is_shop_slot:
				if sell_overlay:
					sell_overlay.visible = true
				if sell_label and "price" in card:
					sell_label.text = "RELEASE TO SELL (+" + str(card.price) + "g)"
				if border_decorator:
					border_decorator.set_border_color(GameColors.GOLDEN_BORDER)
	elif what == NOTIFICATION_DRAG_END:
		if sell_overlay:
			sell_overlay.visible = false
		if border_decorator:
			border_decorator.set_border_color(GameColors.PANEL_BORDER_DEFAULT)

func _update_labels() -> void:
	if is_inside_tree() and gold_label:
		gold_label.text = str(gold)
