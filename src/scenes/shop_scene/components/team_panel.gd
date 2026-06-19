class_name TeamPanel
extends PanelContainer

signal slot_changed(slot: MonsterSlot)

@onready var frontline_hbox: HBoxContainer = %FrontlineHBox
@onready var backline_hbox: HBoxContainer = %BacklineHBox

var slots: Array[MonsterSlot] = []

func create_slots(slot_scene: PackedScene, slot_count: int) -> void:
	for child in frontline_hbox.get_children():
		child.queue_free()
	for child in backline_hbox.get_children():
		child.queue_free()
	slots.clear()
	
	for i in range(slot_count):
		var slot = slot_scene.instantiate() as MonsterSlot
		slot.is_active_team = true
		slot.slot_index = i
		slot.slot_changed.connect(func(_slot): slot_changed.emit(_slot))
		
		if i < 3:
			backline_hbox.add_child(slot) # Slots 0, 1, 2 are backline
		else:
			frontline_hbox.add_child(slot) # Slots 3, 4, 5 are frontline
			
		slots.append(slot)
