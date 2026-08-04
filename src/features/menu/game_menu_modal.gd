class_name GameMenuModal
extends Control

signal resume_requested
signal compendium_requested
signal settings_requested
signal restart_requested

@onready var resume_btn: Button = %ResumeButton
@onready var compendium_btn: Button = %CompendiumButton
@onready var settings_btn: Button = %SettingsButton
@onready var restart_btn: Button = %RestartButton

func _ready() -> void:
	z_index = 4000
	z_as_relative = false
	resume_btn.pressed.connect(func() -> void: resume_requested.emit())
	compendium_btn.pressed.connect(func() -> void: compendium_requested.emit())
	settings_btn.pressed.connect(func() -> void: settings_requested.emit())
	restart_btn.pressed.connect(func() -> void: restart_requested.emit())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		resume_requested.emit()
