class_name BattleHeaderBar
extends PanelContainer

signal exit_pressed
signal play_pressed
signal pause_pressed
signal speed_pressed

@onready var exit_button: Button = %ExitButton
@onready var play_button: Button = %PlayButton
@onready var pause_button: Button = %PauseButton
@onready var speed_button: Button = %SpeedButton
@onready var timer_container: Control = %TimerContainer
@onready var timer_label: Label = %TimerLabel

func _ready() -> void:
	exit_button.pressed.connect(func() -> void: exit_pressed.emit())
	play_button.pressed.connect(func() -> void: play_pressed.emit())
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	speed_button.pressed.connect(func() -> void: speed_pressed.emit())

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
