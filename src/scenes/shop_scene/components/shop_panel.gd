class_name ShopPanel
extends PanelContainer

signal roll_requested
signal sell_card_requested(card: Control, original_slot: MonsterSlot)

@onready var slots_hbox: HBoxContainer = %SlotsHBox
@onready var refresh_shop_button: Button = %RefreshShopButton
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
	refresh_shop_button.pressed.connect(func(): roll_requested.emit())
		
	# Sell Overlay styling
	var sell_style = StyleBoxFlat.new()
	sell_style.bg_color = Color(0.292, 0.245, 0.092, 0.85)
	sell_panel.add_theme_stylebox_override("panel", sell_style)
	
	_update_labels()
	set_process(false)

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
				if sell_label and "price" in card:
					sell_label.text = "RELEASE TO SELL (+" + str(card.price) + "g)"
				set_process(true)
	elif what == NOTIFICATION_DRAG_END:
		set_process(false)
		if sell_overlay:
			sell_overlay.visible = false
		if border_decorator:
			border_decorator.set_border_color(GameColors.PANEL_BORDER_DEFAULT)

func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var is_inside = get_global_rect().has_point(mouse_pos)
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
		gold_label.text = str(gold) + "G"
