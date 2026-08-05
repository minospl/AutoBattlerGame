class_name BattleScene
extends Control

signal battle_finished(outcome: String)
var run_state: RunState

# Static Preloads
const CARD_TOOLTIP_SCENE: PackedScene = preload("res://src/shared/ui/components/card_tooltip.tscn")
const HP_BORDER_SHADER: Shader = preload("res://src/shared/shaders/hp_border.gdshader")
const SHOP_BACKGROUND_TEXTURE: Texture2D = preload("res://src/assets/ui/shop_background.jpg")
const RIVER_CRAB_RES: UnitData = preload("res://src/features/units/templates/river_crab.tres")
const BATTLE_CARD_SCENE: PackedScene = preload("res://src/features/battle/components/battle_card.tscn")

const MAX_TEAM_SIZE: int = RunState.MAX_ACTIVE_TEAM_SIZE

enum State { PLAYING, PAUSED }
var simulation_state: State = State.PAUSED

var player_team: BattleTeamModel
var enemy_team: BattleTeamModel

var game_speed: float = 1.0
var preview_tooltip: CardTooltip
var current_enemy_profile: OpponentProfile = null
var is_outcome_showing: bool = false
var _battle_start_triggered: bool = false
var relic_bar: RelicBar = null

var ruleset: BattleRuleset

# Countdown Timer & Fatigue
var match_timer: float = 30.0
var fatigue_tick_timer: float = 0.0
var fatigue_tick_count: int = 0

# Slot References
var player_slots: Array[BattleCardSlot] = []
var enemy_slots: Array[BattleCardSlot] = []

# Cached Node References
@onready var header_bar: BattleHeaderBar = %BattleHeaderBar
@onready var preview_container: Control = %PreviewContainer
@onready var relic_bar_wrapper: Control = %RelicBarWrapper
@onready var player_panel: BattleTeamPanel = %PlayerTeamPanel
@onready var enemy_panel: BattleTeamPanel = %EnemyTeamPanel
@onready var floating_text_manager: FloatingTextManager = %FloatingTextManager

func _ready() -> void:
	# Add the tooltip instance to PreviewContainer
	if preview_container:
		preview_tooltip = CARD_TOOLTIP_SCENE.instantiate() as CardTooltip
		preview_tooltip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		preview_tooltip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		preview_container.add_child(preview_tooltip)
		preview_tooltip.visible = false

	if header_bar:
		header_bar.exit_pressed.connect(_on_exit_pressed)
		header_bar.play_pressed.connect(_on_play_pressed)
		header_bar.pause_pressed.connect(_on_pause_pressed)
		header_bar.speed_pressed.connect(_on_speed_pressed)

	# Populate slots from components
	if player_panel:
		player_slots = player_panel.slots
		for i: int in range(player_slots.size()):
			player_slots[i].slot_index = i
			
	if enemy_panel:
		enemy_slots = enemy_panel.slots
		for i: int in range(enemy_slots.size()):
			enemy_slots[i].slot_index = i

	# Create BattleTeamModel instances
	player_team = BattleTeamModel.new()
	enemy_team = BattleTeamModel.new()
	
	# Connect signals from player_team
	player_team.team_units_loaded.connect(_on_units_loaded.bind(player_slots))
	player_team.team_defeated.connect(_on_team_defeat)
	player_team.gold_generated.connect(_on_gold_generated)
	player_team.unit_stats_changed.connect(_on_player_unit_stats_changed)

	# Connect signals from enemy_team
	enemy_team.team_units_loaded.connect(_on_units_loaded.bind(enemy_slots))
	enemy_team.team_defeated.connect(_on_enemy_defeat)
	enemy_team.unit_stats_changed.connect(_on_enemy_unit_stats_changed)

	# Connect UI Panels (setup model data and signals)
	if player_panel:
		player_panel.setup_model(player_team)
		player_panel.floating_text_spawn_requested.connect(func(txt: String, col: Color, pos: Vector2) -> void:
			if floating_text_manager: floating_text_manager.show_popup(txt, col, pos)
		)
		
	if enemy_panel:
		enemy_panel.setup_model(enemy_team)
		enemy_panel.floating_text_spawn_requested.connect(func(txt: String, col: Color, pos: Vector2) -> void:
			if floating_text_manager: floating_text_manager.show_popup(txt, col, pos)
		)

	player_team.initialize(false)
	enemy_team.initialize(true)

	# Initialize RelicBar below TopBar (inside the scene-defined RelicBarWrapper placeholder)
	if relic_bar_wrapper:
		relic_bar = RelicBar.new()
		relic_bar.setup(preview_tooltip)
		relic_bar.anchor_left = 0.0
		relic_bar.anchor_right = 1.0
		relic_bar.offset_left = 0.0
		relic_bar.offset_right = 0.0
		relic_bar_wrapper.add_child(relic_bar)

	if run_state and ruleset == null:
		pass

func setup(p_state: RunState, p_ruleset: BattleRuleset) -> void:
	run_state = p_state
	ruleset = p_ruleset
	
	if run_state:
		if run_state.battle_speed <= 0.0:
			run_state.battle_speed = 1.0
		game_speed = run_state.battle_speed
		if header_bar:
			header_bar.set_speed_text("Speed: %dx" % int(game_speed))
			
	if ruleset:
		ruleset.setup_battle(self, run_state)
	
	if player_team.health <= 0:
		show_battle_outcome("defeat")
		return
	if enemy_team.health <= 0:
		show_battle_outcome("victory")
		return
		
	match_timer = 30.0
	fatigue_tick_timer = 0.0
	fatigue_tick_count = 0
	_battle_start_triggered = false
	
	# Start simulation
	set_playing(true)

func load_battle_team() -> void:
	if run_state == null:
		return

	# Copy team and make clones for the battle scene simulation
	var player_units: Array[UnitInstance] = []
	for i: int in range(MAX_TEAM_SIZE):
		var inst: UnitInstance = run_state.active_team[i]
		if inst:
			player_units.append(inst.clone())
		else:
			player_units.append(null)

	player_team.load_team_units(player_units, run_state.base_health)
	
	# Clone player relics from run_state to isolate battle simulation state
	if run_state:
		var cloned_relics: Array[RelicInstance] = []
		for relic: RelicInstance in run_state.relics:
			cloned_relics.append(relic.clone())
		player_team.active_relics = cloned_relics
		player_team.has_magnetic_core = run_state.has_magnetic_core
		player_team.has_focusing_lens = run_state.has_focusing_lens
	else:
		player_team.active_relics = []
		player_team.has_magnetic_core = false
		player_team.has_focusing_lens = false
				
	if relic_bar:
		relic_bar.update_relics(player_team.active_relics)

	match_timer = 30.0
	fatigue_tick_timer = 0.0
	fatigue_tick_count = 0
	if header_bar:
		header_bar.set_timer_visible(true)
		header_bar.set_timer_text("⏳ 30.0s")
		
	load_enemy_team()

func load_enemy_team() -> void:
	var enemy_units: Array[UnitInstance] = []
	enemy_units.resize(MAX_TEAM_SIZE)

	if current_enemy_profile and not current_enemy_profile.active_team.is_empty():
		for i: int in range(MAX_TEAM_SIZE):
			if i < current_enemy_profile.active_team.size() and current_enemy_profile.active_team[i] != null:
				enemy_units[i] = current_enemy_profile.active_team[i].clone()
	else:
		# Fallback just in case
		if RIVER_CRAB_RES:
			var crab_instance: UnitInstance = UnitInstance.new()
			crab_instance.initialize(RIVER_CRAB_RES)
			# Override health and attack
			crab_instance.health = 1000
			crab_instance.attack = 10
			enemy_units[0] = crab_instance
		
	enemy_team.load_team_units(enemy_units, RunState.STARTING_BASE_HEALTH)
	ModifierEngine.update_ongoing_modifiers(player_team, enemy_team)
	ModifierEngine.update_ongoing_modifiers(enemy_team, player_team)

func trigger_battle_start() -> void:
	for i: int in range(MAX_TEAM_SIZE):
		if player_team.units[i]:
			ModifierEngine.trigger_unit_modifier(i, player_team, UnitModifier.Trigger.ON_BATTLE_START)
		if enemy_team.units[i]:
			ModifierEngine.trigger_unit_modifier(i, enemy_team, UnitModifier.Trigger.ON_BATTLE_START)
			
	# Trigger player relics on_battle_start
	for relic: RelicInstance in player_team.active_relics:
		if relic.data.modifier:
			relic.data.modifier.on_battle_start(relic, player_team, enemy_team)
					
	# Update all health and stat overlays
	_update_all_card_uis()


func trigger_cast(source_idx: int) -> void:
	player_team.execute_cast(source_idx, enemy_team)

func trigger_enemy_cast(source_idx: int) -> void:
	enemy_team.execute_cast(source_idx, player_team)

func _on_player_unit_stats_changed(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= player_slots.size():
		return
	var slot: BattleCardSlot = player_slots[slot_idx] as BattleCardSlot
	var card: BattleCard = slot.get_card()
	card.update_ui()
	if preview_tooltip and preview_tooltip.visible and preview_tooltip.get_unit_instance() == card.unit_instance:
		preview_tooltip.update_dynamic_content()

func _on_enemy_unit_stats_changed(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= enemy_slots.size():
		return
	var slot: BattleCardSlot = enemy_slots[slot_idx] as BattleCardSlot
	var card: BattleCard = slot.get_card()
	card.update_ui()
	if preview_tooltip and preview_tooltip.visible and preview_tooltip.get_unit_instance() == card.unit_instance:
		preview_tooltip.update_dynamic_content()

func _update_all_card_uis() -> void:
	for i: int in range(MAX_TEAM_SIZE):
		var slot: BattleCardSlot = player_slots[i] as BattleCardSlot
		var card: Control = slot.get_card()
		if card is BattleCard and player_team.units[i]:
			var b_card: BattleCard = card
			b_card.update_ui()
			
	for i: int in range(MAX_TEAM_SIZE):
		var slot: BattleCardSlot = enemy_slots[i] as BattleCardSlot
		var card: Control = slot.get_card()
		if card is BattleCard and enemy_team.units[i]:
			var b_card: BattleCard = card
			b_card.update_ui()

	if preview_tooltip and preview_tooltip.visible:
		preview_tooltip.update_dynamic_content()

func _process(delta: float) -> void:
	if not _battle_start_triggered:
		_battle_start_triggered = true
		trigger_battle_start()

	if simulation_state == State.PLAYING:
		advance_simulation(delta * game_speed)

func advance_simulation(delta: float) -> void:
	# Update match timer
	if match_timer > 0.0:
		match_timer -= delta
		if match_timer <= 0.0:
			match_timer = 0.0
			if header_bar:
				header_bar.set_timer_visible(false)
		if header_bar:
			header_bar.set_timer_text("⏳ %.1fs" % match_timer)
	else:
		# Fatigue damage active
		fatigue_tick_timer += delta
		if fatigue_tick_timer >= 1.0:
			fatigue_tick_timer -= 1.0
			fatigue_tick_count += 1
			var stage: int = floori((fatigue_tick_count - 1) / 3.0) + 1
			var dmg: int = get_fibonacci(stage + 1)
			
			player_team.take_damage(dmg, BattleTeamModel.DamageType.FATIGUE)
			enemy_team.take_damage(dmg, BattleTeamModel.DamageType.FATIGUE)

	# Tick statuses
	player_team.tick_statuses(delta)
	enemy_team.tick_statuses(delta)

	# Update ongoing modifiers
	ModifierEngine.update_ongoing_modifiers(player_team, enemy_team)
	ModifierEngine.update_ongoing_modifiers(enemy_team, player_team)

	# Tick card casts
	player_team.tick_casts(delta, trigger_cast)
	enemy_team.tick_casts(delta, trigger_enemy_cast)

func _on_enemy_defeat() -> void:
	if ruleset:
		ruleset.on_enemy_defeat(self)

func _on_team_defeat() -> void:
	if ruleset:
		ruleset.on_player_defeat(self)

func reset_for_next_round() -> void:
	load_battle_team()
	if player_team.health <= 0:
		show_battle_outcome("defeat")
		return
	if enemy_team.health <= 0:
		_on_enemy_defeat()
		return
		
	match_timer = 30.0
	fatigue_tick_timer = 0.0
	fatigue_tick_count = 0
	_battle_start_triggered = false
	set_playing(true)

func show_battle_outcome(p_outcome: String, custom_title: String = "", custom_desc: String = "") -> void:
	if is_outcome_showing:
		return
	is_outcome_showing = true
	set_playing(false)
	
	var overlay: ColorRect = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var popup: PanelContainer = PanelContainer.new()
	popup.custom_minimum_size = Vector2(400, 220)
	
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 1.0)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	var title_text: String = "BATTLE ENDED"
	var title_color: Color = Color(1.0, 1.0, 1.0)
	var desc_text: String = ""
	
	match p_outcome:
		"victory":
			title_text = custom_title if custom_title else "VICTORY"
			title_color = Color(1.0, 0.85, 0.2)
			var bot_name: String = current_enemy_profile.name if current_enemy_profile else "Enemy Team"
			desc_text = custom_desc if custom_desc else "%s has been defeated!" % bot_name
			style.border_color = Color(1.0, 0.85, 0.2)
		"defeat":
			title_text = custom_title if custom_title else "DEFEAT"
			title_color = Color(1.0, 0.3, 0.3)
			desc_text = custom_desc if custom_desc else "Your active team was wiped out!"
			style.border_color = Color(1.0, 0.3, 0.3)
		"draw":
			title_text = "DRAW"
			title_color = Color(0.8, 0.8, 0.8)
			desc_text = "Both teams collapsed simultaneously!"
			style.border_color = Color(0.6, 0.6, 0.6)
			
	popup.add_theme_stylebox_override("panel", style)
	
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	popup.add_child(margin)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title_lbl: Label = Label.new()
	title_lbl.text = title_text
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", title_color)
	title_lbl.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title_lbl)
	
	var desc_lbl: Label = Label.new()
	desc_lbl.text = desc_text
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(desc_lbl)
	
	var btn: Button = Button.new()
	btn.text = "Continue"
	btn.custom_minimum_size = Vector2(120, 36)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func() -> void:
		sync_stats_to_run_state()
		battle_finished.emit(p_outcome)
	)
	vbox.add_child(btn)
	
	overlay.add_child(popup)
	popup.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

func _on_gold_generated(amount: int) -> void:
	if run_state:
		run_state.gold += amount

func set_playing(play: bool) -> void:
	if play:
		simulation_state = State.PLAYING
	else:
		simulation_state = State.PAUSED
		
	if header_bar:
		header_bar.set_playing(play)

func _on_play_pressed() -> void:
	set_playing(true)

func _on_pause_pressed() -> void:
	set_playing(false)

func sync_stats_to_run_state() -> void:
	if run_state != null:
		run_state.sync_battle_team_stats(player_team.units)
		run_state.pending_on_battle_end = true

func _on_exit_pressed() -> void:
	sync_stats_to_run_state()
	battle_finished.emit("draw")

func _on_card_hovered(card: Control, is_hovered: bool) -> void:
	if not preview_tooltip:
		return
		
	if is_hovered:
		if card is BattleCard:
			var b_card: BattleCard = card
			if b_card.unit_instance:
				CardUIHelper.show_tooltip(preview_tooltip, b_card.unit_instance)
	else:
		CardUIHelper.hide_tooltip(preview_tooltip)

func _clear_slot_target_highlights() -> void:
	for slot: BattleCardSlot in player_slots:
		slot.set_target_highlight(false)

func _on_speed_pressed() -> void:
	if game_speed == 1.0:
		game_speed = 2.0
	elif game_speed == 2.0:
		game_speed = 3.0
	else:
		game_speed = 1.0
		
	if run_state:
		run_state.battle_speed = game_speed
		
	if header_bar:
		header_bar.set_speed_text("Speed: %dx" % int(game_speed))

func get_fibonacci(n: int) -> int:
	if n <= 0:
		return 0
	if n == 1 or n == 2:
		return 1
	var a: int = 1
	var b: int = 1
	for i: int in range(3, n + 1):
		var temp: int = a + b
		a = b
		b = temp
	return b

# UI Team Handler Methods
func _update_team_slots_ui(slots_arr: Array[BattleCardSlot], loaded_units: Array[UnitInstance]) -> void:
	for slot: BattleCardSlot in slots_arr:
		var old_card: Control = slot.get_card()
		if old_card is BattleCard:
			var old_b_card: BattleCard = old_card
			slot.remove_card(old_b_card)
			old_b_card.queue_free()
			
	for i: int in range(MAX_TEAM_SIZE):
		var inst: UnitInstance = loaded_units[i]
		if inst:
			var card: BattleCard = BATTLE_CARD_SCENE.instantiate() as BattleCard
			card.unit_instance = inst
			card.hovered.connect(func(c: Control, h: bool) -> void: _on_card_hovered(c, h))
			slots_arr[i].add_card(card)

func _on_units_loaded(loaded_units: Array[UnitInstance], slots: Array[BattleCardSlot]) -> void:
	_update_team_slots_ui(slots, loaded_units)

func _exit_tree() -> void:
	if player_team:
		player_team.cleanup()
	if enemy_team:
		enemy_team.cleanup()
