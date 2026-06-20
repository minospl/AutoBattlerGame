class_name BenchPanel
extends PanelContainer

signal slot_changed(slot: CardSlot)

@onready var bench_hbox: HBoxContainer = %BenchHBox

var slots: Array[CardSlot] = []

func create_slots(slot_scene: PackedScene, slot_count: int) -> void:
	for child in bench_hbox.get_children():
		child.queue_free()
	slots.clear()
	
	for i in range(slot_count):
		var slot = slot_scene.instantiate() as CardSlot
		slot.is_active_team = false
		slot.slot_index = i
		slot.slot_changed.connect(func(_slot): slot_changed.emit(_slot))
		bench_hbox.add_child(slot)
		slots.append(slot)
