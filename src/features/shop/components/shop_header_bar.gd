class_name ShopHeaderBar
extends PanelContainer

const SHOP_HEADER_BG_SHADER: Shader = preload("res://src/shared/shaders/shop_header_bar_bg.gdshader")
const OPPONENT_PORTRAIT: PackedScene = preload("res://src/features/shop/components/opponent_portrait.tscn")

signal menu_requested
signal bag_requested

@export var lives: int:
	set(value):
		lives = value
		_update_labels()

@export var day: int:
	set(value):
		day = value
		_update_labels()

@export var max_rounds: int = 20:
	set(value):
		max_rounds = value
		_update_labels()

@export var is_deathmatch: bool = false:
	set(value):
		is_deathmatch = value
		_update_labels()

@onready var menu_btn: Button = %MenuButton
@onready var bag_btn: RelicBagButton = %BagButton
@onready var lives_label: Label = %LivesLabel
@onready var day_label: Label = %DayLabel
@onready var opponents_container: HBoxContainer = %OpponentsContainer

func _ready() -> void:	
	# Connect local button signals
	menu_btn.pressed.connect(func() -> void: menu_requested.emit())
	bag_btn.bag_opened.connect(func() -> void: bag_requested.emit())
	
	# Apply visual styling programmatically to keep the presentation premium and clean
	_apply_visual_styling()
	_update_labels()

func _update_labels() -> void:
	if is_inside_tree():
		if lives_label:
			lives_label.text = str(lives)

		if day_label:
			if is_deathmatch:
				day_label.text = "DEATHMATCH"
			else:
				day_label.text = "DAY " + str(day)

func update_bag_count(count: int) -> void:
	bag_btn.current_count = count

func setup_opponent_list(run_state: RunState) -> void:
	if not opponents_container: return
	
	for child: Node in opponents_container.get_children():
		child.queue_free()
		
	if not run_state or not run_state.opponent_provider:
		return

	var all_opponents: Array[OpponentProfile] = run_state.opponent_provider.get_all_opponents()
	var pool_ids: Array[int] = []
	for bot: OpponentProfile in run_state.opponents_pool:
		if bot != null:
			pool_ids.append(bot.id)

	var next_id: int = run_state.next_opponent.id if run_state.next_opponent else -1

	var colors: Array[Color] = [
		Color(0.8, 0.2, 0.2), Color(0.2, 0.8, 0.2), Color(0.2, 0.2, 0.8),
		Color(0.8, 0.8, 0.2), Color(0.6, 0.2, 0.8), Color(0.2, 0.8, 0.8),
		Color(0.8, 0.5, 0.2)
	]

	for i: int in range(all_opponents.size()):
		var bot: OpponentProfile = all_opponents[i]
		var portrait: OpponentPortrait = OPPONENT_PORTRAIT.instantiate() as OpponentPortrait
		opponents_container.add_child(portrait)

		var is_in_pool: bool = pool_ids.has(bot.id) and bot.data.lives > 0
		var is_next: bool = (bot.id == next_id)
		var c: Color = colors[i % colors.size()]

		portrait.setup(bot.id, is_in_pool, is_next, c)

func _apply_visual_styling() -> void:
	var header_content: PanelContainer = get_node_or_null("VBox/HeaderContent") as PanelContainer
	if not header_content:
		return
		
	# 1. Apply background shader to HeaderContent instead of root
	var panel_mat: ShaderMaterial = ShaderMaterial.new()
	panel_mat.shader = SHOP_HEADER_BG_SHADER
	
	# Connect to resized of HeaderContent to update shader size uniform
	header_content.resized.connect(func() -> void:
		if panel_mat: panel_mat.set_shader_parameter("size", header_content.size)
	)
	
	# Force initial size update
	var initial_size: Vector2 = header_content.size if header_content.size != Vector2.ZERO else Vector2(1280, 40)
	panel_mat.set_shader_parameter("size", initial_size)
		
	header_content.material = panel_mat
	
	# 2. Transparent panel stylebox to let shader draw cleanly on HeaderContent
	var transparent_style: StyleBoxFlat = StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	header_content.add_theme_stylebox_override("panel", transparent_style)
