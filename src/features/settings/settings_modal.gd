class_name SettingsModal
extends Control

signal back_requested

@onready var window_mode_option: OptionButton = %WindowModeOption
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var vsync_option: OptionButton = %VSyncOption
@onready var back_btn: Button = %BackButton

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1280, 800),
	Vector2i(1600, 900),
	Vector2i(1680, 1050),
	Vector2i(1920, 1080),
	Vector2i(1920, 1200),
	Vector2i(2560, 1440),
	Vector2i(2560, 1600),
	Vector2i(3840, 2160)
]

func _ready() -> void:
	z_index = 4000
	z_as_relative = false
	_populate_options()
	_sync_ui_with_display_server()
	
	window_mode_option.item_selected.connect(_on_window_mode_selected)
	resolution_option.item_selected.connect(_on_resolution_selected)
	vsync_option.item_selected.connect(_on_vsync_selected)
	back_btn.pressed.connect(func() -> void: back_requested.emit())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_requested.emit()

func _populate_options() -> void:
	window_mode_option.clear()
	window_mode_option.add_item("Windowed", 0)
	window_mode_option.add_item("Fullscreen", 1)
	window_mode_option.add_item("Borderless Fullscreen", 2)
	
	resolution_option.clear()
	var screen_id: int = DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_id)
	
	var available_resolutions: Array[Vector2i] = []
	for i: int in range(RESOLUTIONS.size()):
		var res: Vector2i = RESOLUTIONS[i]
		if res.x <= screen_size.x and res.y <= screen_size.y:
			available_resolutions.append(res)
			
	if available_resolutions.is_empty():
		available_resolutions.append(Vector2i(1280, 720))
		
	for i: int in range(available_resolutions.size()):
		var res: Vector2i = available_resolutions[i]
		resolution_option.add_item("%dx%d" % [res.x, res.y], i)
		resolution_option.set_item_metadata(i, res)
	
	vsync_option.clear()
	vsync_option.add_item("Enabled", 0)
	vsync_option.add_item("Disabled", 1)

func _sync_ui_with_display_server() -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	var is_borderless: bool = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS)
	
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		if is_borderless:
			window_mode_option.selected = 2
		else:
			window_mode_option.selected = 1
		resolution_option.disabled = true
	else:
		window_mode_option.selected = 0
		resolution_option.disabled = false
		
	var current_size: Vector2i = DisplayServer.window_get_size()
	var screen_id: int = DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_id)
	
	if mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
		current_size = screen_size
		
	var closest_idx: int = 0
	var min_diff: int = 99999999
	for i: int in range(resolution_option.item_count):
		var item_res: Vector2i = resolution_option.get_item_metadata(i)
		var diff: int = absi(item_res.x - current_size.x) + absi(item_res.y - current_size.y)
		if diff < min_diff:
			min_diff = diff
			closest_idx = i
	resolution_option.selected = closest_idx
	
	var vsync_mode: DisplayServer.VSyncMode = DisplayServer.window_get_vsync_mode()
	if vsync_mode == DisplayServer.VSYNC_DISABLED:
		vsync_option.selected = 1
	else:
		vsync_option.selected = 0

func _on_window_mode_selected(index: int) -> void:
	if index == 0:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		resolution_option.disabled = false
		if resolution_option.item_count > 0 and resolution_option.selected >= 0:
			var selected_res: Vector2i = resolution_option.get_item_metadata(resolution_option.selected)
			_apply_resolution(selected_res)
	elif index == 1:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		resolution_option.disabled = true
	elif index == 2:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		resolution_option.disabled = true

func _on_resolution_selected(index: int) -> void:
	if index >= 0 and index < resolution_option.item_count:
		var selected_res: Vector2i = resolution_option.get_item_metadata(index)
		_apply_resolution(selected_res)

func _apply_resolution(new_size: Vector2i) -> void:
	var screen_id: int = DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_id)
	var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen_id)
	var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	
	if current_mode == DisplayServer.WINDOW_MODE_WINDOWED or current_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
		if new_size.x >= screen_size.x or new_size.y >= screen_size.y:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			return

		if current_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			
	DisplayServer.window_set_size(new_size)
	var center_pos: Vector2i = usable_rect.position + Vector2i(floori((usable_rect.size.x - new_size.x) * 0.5), floori((usable_rect.size.y - new_size.y) * 0.5))
	center_pos.y = maxi(center_pos.y, usable_rect.position.y + 32)
	DisplayServer.window_set_position(center_pos)

func _on_vsync_selected(index: int) -> void:
	if index == 0:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
