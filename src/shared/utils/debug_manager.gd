class_name DebugManager
extends Node

var run_state: RunState
var shop_scene: Node

func setup(p_run_state: RunState, p_shop_scene: Node) -> void:
	run_state = p_run_state
	shop_scene = p_shop_scene

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
		
	var key_event: InputEventKey = event as InputEventKey
	match key_event.keycode:
		KEY_1:
			_add_random_monster()
		KEY_2:
			add_random_relic()
		KEY_3:
			add_all_relics()

func _add_random_monster() -> void:
	if not run_state or run_state.unit_templates.is_empty():
		return
		
	var template: UnitData = run_state.unit_templates[randi() % run_state.unit_templates.size()]
	var instance: UnitInstance = UnitInstance.new()
	instance.initialize(template)
	
	var added: bool = false
	for i: int in range(run_state.bench.size()):
		if run_state.bench[i] == null:
			run_state.bench[i] = instance
			added = true
			break
			
	if added and shop_scene:
		if shop_scene.has_method("populate_ui"):
			shop_scene.call("populate_ui")
		if shop_scene.has_signal("team_state_changed"):
			var sig: Signal = shop_scene.get("team_state_changed")
			sig.emit()

func add_random_relic(p_rarity: Rarity = null) -> void:
	if run_state:
		run_state.add_random_relic(p_rarity)

func add_all_relics() -> void:
	if not run_state:
		return
		
	for template: RelicData in run_state.relic_templates:
		if not template:
			continue
			
		var is_unique: bool = false
		if template.rarity:
			is_unique = (template.rarity.rarity_type == Rarity.Type.UNIQUE)
			
		var already_owned: bool = false
		for existing: RelicInstance in run_state.relics:
			if existing.data and existing.data.display_name == template.display_name:
				already_owned = true
				break
				
		if is_unique and already_owned:
			continue
			
		var relic_inst: RelicInstance = RelicInstance.new()
		relic_inst.initialize(template)
		run_state.add_relic(relic_inst)

func handle_card_right_click(card: UnitCard) -> void:
	if not card or not card.unit_instance:
		return
		
	card.unit_instance.level_up()
	card.update_ui()
	
	if shop_scene:
		var preview_tooltip: Control = shop_scene.get("preview_tooltip")
		var current_hovered_card: Control = shop_scene.get("current_hovered_card")
		if preview_tooltip and preview_tooltip.visible and current_hovered_card == card:
			CardUIHelper.show_tooltip(preview_tooltip as CardTooltip, card.unit_instance)
			
		if shop_scene.has_method("check_for_unit_merges"):
			shop_scene.call("check_for_unit_merges")
			
		if shop_scene.has_signal("team_state_changed"):
			var sig: Signal = shop_scene.get("team_state_changed")
			sig.emit()

func on_card_gui_input(event: InputEvent, card: UnitCard) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			handle_card_right_click(card)
			if shop_scene and shop_scene.is_inside_tree():
				shop_scene.get_viewport().set_input_as_handled()
