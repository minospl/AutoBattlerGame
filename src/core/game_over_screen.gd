class_name GameOverScreen
extends Control

signal restart_requested

@onready var title_lbl: Label = %TitleLabel
@onready var sub_lbl: Label = %SubtitleLabel
@onready var days_lbl: Label = %DaysLabel
@onready var trophies_lbl: Label = %TrophiesLabel
@onready var play_again_btn: Button = %PlayAgainButton

func _ready() -> void:
	play_again_btn.pressed.connect(func() -> void:
		restart_requested.emit()
	)
	
	# Configure background panel styling programmatically to match design tokens
	var bg_panel: Panel = %BackgroundPanel
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.08, 0.1, 1.0)
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	
	# Configure stats panel styling programmatically to match design tokens
	var stats_panel: PanelContainer = %StatsPanel
	var stats_style: StyleBoxFlat = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.12, 0.12, 0.16, 1.0)
	stats_style.border_width_left = 1
	stats_style.border_width_top = 1
	stats_style.border_width_right = 1
	stats_style.border_width_bottom = 1
	stats_style.border_color = Color(0.25, 0.25, 0.3, 1.0)
	stats_style.corner_radius_top_left = 6
	stats_style.corner_radius_top_right = 6
	stats_style.corner_radius_bottom_left = 6
	stats_style.corner_radius_bottom_right = 6
	stats_panel.add_theme_stylebox_override("panel", stats_style)

func setup(p_victory: bool, p_trophies: int, p_day: int) -> void:
	if p_victory:
		title_lbl.text = "RUN VICTORY!"
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2)) # Gold
		sub_lbl.text = "Congratulations! You completed the dungeon run!"
	else:
		title_lbl.text = "RUN DEFEATED"
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3)) # Red
		sub_lbl.text = "Your team succumbed to the dungeon..."
		
	days_lbl.text = "Days Survived: " + str(p_day)
	trophies_lbl.text = "Trophies Earned: " + str(p_trophies) + " / 10"
