class_name BenchPanel
extends PanelContainer

signal slot_changed(slot: MonsterSlot)

@onready var bench_hbox: HBoxContainer = %BenchHBox
@onready var bench_header: PanelContainer = %BenchHeader
@onready var bench_label: Label = %BenchLabel

var slots: Array[MonsterSlot] = []

func _ready() -> void:
	# Bench Header Style (Yellow Banner)
	var bench_header_style = StyleBoxFlat.new()
	var bench_color = GameColors.BENCH_HEADER_BG
	bench_header_style.bg_color = bench_color
	bench_header_style.border_width_bottom = 3
	bench_header_style.border_color = bench_color.lightened(0.5)
	bench_header_style.content_margin_bottom = 2
	bench_header_style.content_margin_left = 2
	bench_header.add_theme_stylebox_override("panel", bench_header_style)
	
	# Label outline styling
	bench_label.add_theme_color_override("font_outline_color", GameColors.LABEL_OUTLINE)
	bench_label.add_theme_constant_override("outline_size", 5)

func create_slots(slot_scene: PackedScene, slot_count: int) -> void:
	for child in bench_hbox.get_children():
		child.queue_free()
	slots.clear()
	
	for i in range(slot_count):
		var slot = slot_scene.instantiate() as MonsterSlot
		slot.is_active_team = false
		slot.slot_index = i
		slot.slot_changed.connect(func(_slot): slot_changed.emit(_slot))
		bench_hbox.add_child(slot)
		slots.append(slot)
