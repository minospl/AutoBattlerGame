class_name TeamPanel
extends PanelContainer

signal card_dropped(dragged_card: Control, original_slot: ShopCardSlot, target_slot: ShopCardSlot)

@onready var grid_container: GridContainer = %GridContainer

var slots: Array[ShopCardSlot] = []

func create_slots(slot_scene: PackedScene, slot_count: int) -> void:
	for child: Node in grid_container.get_children():
		child.queue_free()
	slots.clear()
	
	for i: int in range(slot_count):
		var slot: ShopCardSlot = slot_scene.instantiate() as ShopCardSlot
		slot.is_active_team = true
		slot.slot_index = i
		slot.card_dropped.connect(func(c: Control, o: ShopCardSlot, t: ShopCardSlot) -> void: card_dropped.emit(c, o, t))
		
		grid_container.add_child(slot)
		slots.append(slot)
