class_name ShopPanel
extends PanelContainer

signal roll_requested
signal sell_card_requested(card: Control, original_slot: ShopCardSlot)
signal freeze_all_requested(freeze: bool)

@onready var slots_hbox: HBoxContainer = %SlotsHBox
@onready var refresh_shop_button: Button = %RefreshShopButton
@onready var freeze_shop_button: Button = %FreezeShopButton
@onready var gold_label: RichTextLabel = %GoldLabel
@onready var sell_overlay: MarginContainer = %SellOverlay
@onready var sell_panel: PanelContainer = %SellPanel
@onready var sell_label: Label = %SellLabel
@onready var border_decorator: ShaderBorderDecorator = $PanelBorder/BorderOverlay as ShaderBorderDecorator

@export var gold: int = 10:
	set(val):
		gold = val
		_update_labels()

@onready var shop_label: Label = %ShopLabel
@onready var chance_label: RichTextLabel = %ChanceLabel

@export var shop_level: int = 1:
	set(val):
		shop_level = val
		_update_labels()

@export var shop_weights: Array[float] = []:
	set(val):
		shop_weights = val
		_update_labels()

@export var has_unique_potential: bool = false:
	set(val):
		has_unique_potential = val
		_update_labels()

@export var is_shop_frozen: bool = false:
	set(val):
		is_shop_frozen = val
		if freeze_shop_button.button_pressed != is_shop_frozen:
			freeze_shop_button.set_pressed_no_signal(is_shop_frozen)

var slots: Array[ShopCardSlot] = []

func _ready() -> void:
	refresh_shop_button.pressed.connect(func() -> void: roll_requested.emit())
	freeze_shop_button.toggled.connect(func(pressed: bool) -> void: freeze_all_requested.emit(pressed))
		
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
					if card is UnitCard: # Only sell Card (units)
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
		if card is UnitCard and original_slot and not original_slot.is_shop_slot:
			var unit_card: UnitCard = card as UnitCard
			var sell_price: int = max(1, unit_card.unit_instance.data.price - 1)
			sell_label.text = "RELEASE TO SELL (+" + str(sell_price) + "g)"
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

func _format_chance_text(weights: Array[float]) -> String:
	var parts: Array[String] = []
	var w_scale: float = 0.9 if has_unique_potential else 1.0
	
	if weights.size() > 0 and weights[0] > 0.0:
		parts.append("[color=#708094]C:%d%%[/color]" % roundi(weights[0] * w_scale * 100))
	if weights.size() > 1 and weights[1] > 0.0:
		parts.append("[color=#3082cf]R:%d%%[/color]" % roundi(weights[1] * w_scale * 100))
	if weights.size() > 2 and weights[2] > 0.0:
		parts.append("[color=#8059d6]E:%d%%[/color]" % roundi(weights[2] * w_scale * 100))
	if weights.size() > 3 and weights[3] > 0.0:
		parts.append("[color=#d69e2e]L:%d%%[/color]" % roundi(weights[3] * w_scale * 100))
	if has_unique_potential:
		parts.append("[color=#e61a33]U:10%[/color]")

	return " | ".join(parts)

func _update_labels() -> void:
	if is_inside_tree() and gold_label:
		gold_label.text = str(gold) + "[color=#f2b726]G[/color]"
	if is_inside_tree() and shop_label:
		shop_label.text = "SHOP LVL " + str(shop_level)
	if is_inside_tree() and chance_label and shop_weights.size() > 0:
		chance_label.text = _format_chance_text(shop_weights)
