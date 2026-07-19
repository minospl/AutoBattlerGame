class_name BenchPanel
extends PanelContainer

signal item_dropped(item_card: ShopCardItem, original_slot: ShopCardSlot, target_slot: ShopCardSlot)
signal unit_dropped(unit_card: UnitCard, original_slot: ShopCardSlot, target_slot: ShopCardSlot)

@onready var bench_hbox: HBoxContainer = %BenchHBox

var slots: Array[ShopCardSlot] = []

func create_slots(slot_scene: PackedScene, slot_count: int) -> void:
	for child: Node in bench_hbox.get_children():
		child.queue_free()
	slots.clear()
	
	for i: int in range(slot_count):
		var slot: ShopCardSlot = slot_scene.instantiate() as ShopCardSlot
		slot.is_active_team = false
		slot.slot_index = i
		slot.item_dropped.connect(func(c: ShopCardItem, o: ShopCardSlot, t: ShopCardSlot) -> void: item_dropped.emit(c, o, t))
		slot.unit_dropped.connect(func(c: UnitCard, o: ShopCardSlot, t: ShopCardSlot) -> void: unit_dropped.emit(c, o, t))
		bench_hbox.add_child(slot)
		slots.append(slot)
