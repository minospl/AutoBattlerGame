class_name RelicBagPopup
extends PanelContainer

const RELIC_SLOT_SCENE: PackedScene = preload("res://src/features/relics/components/relic_slot.tscn")

@onready var grid: GridContainer = %GridContainer
var tooltip: CardTooltip = null

func setup(p_tooltip: CardTooltip) -> void:
	tooltip = p_tooltip
	hide()

func update_relics(relic_list: Array[RelicInstance]) -> void:
	# Wyczyść stare
	for child: Node in grid.get_children():
		child.queue_free()
		
	var sorted_list: Array[RelicInstance] = relic_list.duplicate()
	sorted_list.sort_custom(func(a: RelicInstance, b: RelicInstance) -> bool:
		return a.data.rarity.rarity_type > b.data.rarity.rarity_type
	)
			
	var min_slots: int = 12 # 3x4
	var total_slots: int = max(min_slots, ceili(sorted_list.size() / 3.0) * 3)
	
	if total_slots > 12:
		custom_minimum_size.x = 220 # +10px for scrollbar clearance
	else:
		custom_minimum_size.x = 200
		
	for i: int in range(total_slots):
		var slot: RelicSlot = RELIC_SLOT_SCENE.instantiate() as RelicSlot
		grid.add_child(slot)
		
		if i < sorted_list.size():
			slot.set_relic(sorted_list[i], tooltip)

func toggle() -> void:
	visible = !visible
