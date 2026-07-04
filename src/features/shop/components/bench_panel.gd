class_name BenchPanel
extends PanelContainer

signal card_dropped(dragged_card: Control, original_slot: ShopCardSlot, target_slot: ShopCardSlot)

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
		slot.card_dropped.connect(func(c: Control, o: ShopCardSlot, t: ShopCardSlot) -> void: card_dropped.emit(c, o, t))
		bench_hbox.add_child(slot)
		slots.append(slot)
