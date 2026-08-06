class_name BattleHeaderBar
extends PanelContainer

signal exit_pressed
signal play_pressed
signal pause_pressed
signal speed_pressed
signal player_bag_requested
signal enemy_bag_requested

@onready var exit_button: Button = %ExitButton
@onready var play_button: Button = %PlayButton
@onready var pause_button: Button = %PauseButton
@onready var speed_button: Button = %SpeedButton
@onready var timer_container: Control = %TimerContainer
@onready var timer_label: Label = %TimerLabel
@onready var player_bag_btn: RelicBagButton = %PlayerBagButton
@onready var enemy_bag_btn: RelicBagButton = %EnemyBagButton

func _ready() -> void:
	exit_button.pressed.connect(func() -> void: exit_pressed.emit())
	play_button.pressed.connect(func() -> void: play_pressed.emit())
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	speed_button.pressed.connect(func() -> void: speed_pressed.emit())
	
	player_bag_btn.bag_opened.connect(func() -> void: player_bag_requested.emit())
	enemy_bag_btn.bag_opened.connect(func() -> void: enemy_bag_requested.emit())
	
	_add_info_label()

var info_label: Label = null

func _add_info_label() -> void:
	info_label = Label.new()
	info_label.text = "DAY 1"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.add_theme_font_size_override("font_size", 18)
	
	# Find the parent hbox container
	var parent_box: Node = exit_button.get_parent()
	if parent_box and parent_box is HBoxContainer:
		parent_box.add_child(info_label)
		# Move it to center (after exit button, before center container if any)
		parent_box.move_child(info_label, 1)

func set_round_info(day: int, max_rounds: int, lives: int, is_deathmatch: bool) -> void:
	if not info_label: return
	var text: String = ""
	if is_deathmatch:
		text = "[DEATHMATCH]"
	else:
		text = "DAY %d/%d" % [day, max_rounds]
		
	text += " | LIVES: %d" % lives
	info_label.text = text

func set_timer_text(p_text: String) -> void:
	if timer_label:
		timer_label.text = p_text

func set_timer_visible(p_visible: bool) -> void:
	if timer_container:
		timer_container.visible = p_visible

func set_speed_text(p_text: String) -> void:
	if speed_button:
		speed_button.text = p_text

func set_playing(p_playing: bool) -> void:
	if play_button:
		play_button.visible = not p_playing
	if pause_button:
		pause_button.visible = p_playing

func update_player_bag_count(count: int) -> void:
	player_bag_btn.current_count = count

func update_enemy_bag_count(count: int) -> void:
	enemy_bag_btn.current_count = count
