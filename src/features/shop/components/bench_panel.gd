class_name BenchPanel
extends PanelContainer

signal item_dropped(item_card: ShopCardItem, original_slot: ShopSlot, target_slot: UnitSlot)
signal unit_dropped(unit_card: UnitCard, original_slot: UnitSlot, target_slot: UnitSlot)

@onready var bench_hbox: HBoxContainer = %BenchHBox

var slots: Array[UnitSlot] = []

func create_slots(slot_scene: PackedScene, slot_count: int) -> void:
	for child: Node in bench_hbox.get_children():
		child.queue_free()
	slots.clear()
	
	for i: int in range(slot_count):
		var slot: UnitSlot = slot_scene.instantiate() as UnitSlot
		slot.is_active_team = false
		slot.slot_index = i
		slot.item_dropped.connect(func(c: ShopCardItem, o: ShopSlot, t: UnitSlot) -> void: item_dropped.emit(c, o, t))
		slot.unit_dropped.connect(func(c: UnitCard, o: UnitSlot, t: UnitSlot) -> void: unit_dropped.emit(c, o, t))
		bench_hbox.add_child(slot)
		slots.append(slot)
