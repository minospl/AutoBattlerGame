class_name GameOverScreen
extends Control

signal restart_requested

func setup(p_victory: bool, p_trophies: int, p_day: int) -> void:
	# Full screen layout
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Background Panel
	var bg_panel: Panel = Panel.new()
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.08, 0.1, 1.0)
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(bg_panel)
	
	# Center VBox container
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(500, 300)
	add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	# Title Label
	var title_lbl: Label = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 48)
	if p_victory:
		title_lbl.text = "RUN VICTORY!"
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2)) # Gold
	else:
		title_lbl.text = "RUN DEFEATED"
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3)) # Red
	vbox.add_child(title_lbl)
	
	# Subtitle Label
	var sub_lbl: Label = Label.new()
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 18)
	if p_victory:
		sub_lbl.text = "Congratulations! You completed the dungeon run!"
	else:
		sub_lbl.text = "Your team succumbed to the dungeon..."
	vbox.add_child(sub_lbl)
	
	# Stats Container
	var stats_panel: PanelContainer = PanelContainer.new()
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
	vbox.add_child(stats_panel)
	
	var stats_margin: MarginContainer = MarginContainer.new()
	stats_margin.add_theme_constant_override("margin_left", 30)
	stats_margin.add_theme_constant_override("margin_top", 15)
	stats_margin.add_theme_constant_override("margin_right", 30)
	stats_margin.add_theme_constant_override("margin_bottom", 15)
	stats_panel.add_child(stats_margin)
	
	var stats_vbox: VBoxContainer = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	stats_margin.add_child(stats_vbox)
	
	# Days Stat
	var days_lbl: Label = Label.new()
	days_lbl.text = "Days Survived: " + str(p_day)
	days_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	days_lbl.add_theme_font_size_override("font_size", 16)
	stats_vbox.add_child(days_lbl)
	
	# Trophies Stat
	var trophies_lbl: Label = Label.new()
	trophies_lbl.text = "Trophies Earned: " + str(p_trophies) + " / 10"
	trophies_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trophies_lbl.add_theme_font_size_override("font_size", 16)
	stats_vbox.add_child(trophies_lbl)
	
	# Restart Button
	var btn: Button = Button.new()
	btn.text = "Play Again"
	btn.custom_minimum_size = Vector2(160, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func() -> void:
		restart_requested.emit()
	)
	vbox.add_child(btn)
