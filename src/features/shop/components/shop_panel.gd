class_name ShopPanel
extends PanelContainer

signal roll_requested
signal sell_card_requested(card: Control, original_slot: ShopCardSlot)

@onready var slots_hbox: HBoxContainer = %SlotsHBox
@onready var refresh_shop_button: Button = %RefreshShopButton
@onready var gold_label: RichTextLabel = %GoldLabel
@onready var sell_overlay: MarginContainer = %SellOverlay
@onready var sell_panel: PanelContainer = %SellPanel
@onready var sell_label: Label = %SellLabel
@onready var border_decorator: ShaderBorderDecorator = $PanelBorder/BorderOverlay as ShaderBorderDecorator

@export var gold: int = 10:
	set(val):
		gold = val
		_update_labels()

var slots: Array[ShopCardSlot] = []

func _ready() -> void:
	refresh_shop_button.pressed.connect(func() -> void: roll_requested.emit())
		
	# Sell Overlay styling
	var sell_style: StyleBoxFlat = StyleBoxFlat.new()
	sell_style.bg_color = Color(0.292, 0.245, 0.092, 0.85)
	sell_panel.add_theme_stylebox_override("panel", sell_style)
	
	_update_labels()
	set_process(false)

func create_slots(slot_scene: PackedScene, slot_count: int) -> void:
	for child: Node in slots_hbox.get_children():
		child.queue_free()
	slots.clear()
	
	for i: int in range(slot_count):
		var slot: ShopCardSlot = slot_scene.instantiate() as ShopCardSlot
		slot.is_shop_slot = true
		slot.slot_index = i
		slots_hbox.add_child(slot)
		slots.append(slot)

# Drag and drop logic for selling
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if sell_overlay and sell_overlay.visible:
		if typeof(data) == TYPE_DICTIONARY:
			var dict: Dictionary = data
			if dict.has("original_slot") and dict.has("card"):
				var original_slot: ShopCardSlot = dict["original_slot"]
				if original_slot and not original_slot.is_shop_slot: # Can only sell if it comes from team or bench (not a shop slot)
					var card: Control = dict["card"]
					if card is ShopCard: # Only sell Card (units)
						return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY:
		var dict: Dictionary = data
		if dict.has("card") and dict.has("original_slot"):
			var card: Control = dict["card"]
			var original_slot: ShopCardSlot = dict["original_slot"]
			sell_card_requested.emit(card, original_slot)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN: # Check if the dragged item is sellable by querying DragManager's static variables
		var card: Control = DragManager.dragged_card
		var original_slot: ShopCardSlot = null
		if DragManager.dragged_card_original_slot is ShopCardSlot:
			original_slot = DragManager.dragged_card_original_slot
		if card is ShopCard and original_slot and not original_slot.is_shop_slot:
			var shop_card: ShopCard = card
			if sell_label:
				sell_label.text = "RELEASE TO SELL (+" + str(shop_card.price) + "g)"
			set_process(true)
	elif what == NOTIFICATION_DRAG_END:
		set_process(false)
		if sell_overlay:
			sell_overlay.visible = false
		if border_decorator:
			border_decorator.set_border_color(GameColors.PANEL_BORDER_DEFAULT)

func _process(_delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var is_inside: bool = get_global_rect().has_point(mouse_pos)
	if is_inside:
		if sell_overlay and not sell_overlay.visible:
			sell_overlay.visible = true
			if border_decorator:
				border_decorator.set_border_color(GameColors.GOLDEN_BORDER)
	else:
		if sell_overlay and sell_overlay.visible:
			sell_overlay.visible = false
			if border_decorator:
				border_decorator.set_border_color(GameColors.PANEL_BORDER_DEFAULT)

func _update_labels() -> void:
	if is_inside_tree() and gold_label:
		gold_label.text = str(gold) + "[color=#f2b726]G[/color]"
