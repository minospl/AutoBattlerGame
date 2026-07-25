class_name TeamPanel
extends PanelContainer

signal item_dropped(item_card: ShopCardItem, original_slot: ShopSlot, target_slot: UnitSlot)
signal unit_dropped(unit_card: UnitCard, original_slot: UnitSlot, target_slot: UnitSlot)

@onready var grid_container: GridContainer = %GridContainer
@onready var team_hp_label: Label = %TeamHPLabel

var slots: Array[UnitSlot] = []

func update_team_hp(hp_value: int) -> void:
	team_hp_label.text = NumberFormatter.format_large_number(hp_value)

func create_slots(slot_scene: PackedScene, slot_count: int) -> void:
	for child: Node in grid_container.get_children():
		child.queue_free()
	slots.clear()
	
	for i: int in range(slot_count):
		var slot: UnitSlot = slot_scene.instantiate() as UnitSlot
		slot.is_active_team = true
		slot.slot_index = i
		slot.item_dropped.connect(func(c: ShopCardItem, o: ShopSlot, t: UnitSlot) -> void: item_dropped.emit(c, o, t))
		slot.unit_dropped.connect(func(c: UnitCard, o: UnitSlot, t: UnitSlot) -> void: unit_dropped.emit(c, o, t))
		grid_container.add_child(slot)
		slots.append(slot)
