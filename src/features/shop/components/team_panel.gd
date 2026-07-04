class_name TeamPanel
extends PanelContainer

signal card_dropped(dragged_card: Control, original_slot: ShopCardSlot, target_slot: ShopCardSlot)

@onready var row0_hbox: HBoxContainer = %Row0HBox
@onready var row1_hbox: HBoxContainer = %Row1HBox

var slots: Array[ShopCardSlot] = []

func create_slots(slot_scene: PackedScene, slot_count: int) -> void:
	for child: Node in row0_hbox.get_children():
		child.queue_free()
	for child: Node in row1_hbox.get_children():
		child.queue_free()
	slots.clear()
	
	for i: int in range(slot_count):
		var slot: ShopCardSlot = slot_scene.instantiate() as ShopCardSlot
		slot.is_active_team = true
		slot.slot_index = i
		slot.card_dropped.connect(func(c: Control, o: ShopCardSlot, t: ShopCardSlot) -> void: card_dropped.emit(c, o, t))
		
		if i < 3:
			row0_hbox.add_child(slot) # Slots 0, 1, 2 go to Row 0 (top)
		else:
			row1_hbox.add_child(slot) # Slots 3, 4, 5 go to Row 1 (bottom)
			
		slots.append(slot)
