class_name TooltipKeywordsBox
extends VBoxContainer

func build_keywords(unit_instance: UnitInstance) -> int:
	# Clear old nodes
	for child: Node in get_children():
		child.queue_free()
		
	if not unit_instance:
		return 0
		
	var keywords: Array[Dictionary] = KeywordDatabase.get_keywords_for_unit(unit_instance, unit_instance.level)
	for kw: Dictionary in keywords:
		var panel: MarginContainer = _create_keyword_panel(str(kw["title"]), str(kw["desc"]))
		add_child(panel)
		
	return keywords.size()

func _create_keyword_panel(title: String, desc: String) -> MarginContainer:
	var panel: MarginContainer = MarginContainer.new()
	panel.custom_minimum_size = Vector2(220, 0)
	
	var border: ShaderBorderDecorator = ShaderBorderDecorator.new()
	border.border_type = ShaderBorderDecorator.BorderType.DOUBLE
	border.interior_color = Color(1.0, 1.0, 1.0) # Solid white background
	border.outer_border_width = 2
	border.inner_border_width = 2
	border.border_indentation = 1
	panel.add_child(border)
	
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	
	var title_lbl: Label = Label.new()
	title_lbl.text = title.to_upper()
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2)) # Gold title
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.12, 0.13)) # Dark outline
	title_lbl.add_theme_constant_override("outline_size", 4)
	vbox.add_child(title_lbl)
	
	var desc_lbl: RichTextLabel = RichTextLabel.new()
	desc_lbl.bbcode_enabled = true
	desc_lbl.text = "[color=#2c3e50][font_size=12]%s[/font_size][/color]" % desc
	desc_lbl.fit_content = true
	desc_lbl.selection_enabled = false
	desc_lbl.scroll_active = false
	vbox.add_child(desc_lbl)
	
	margin.add_child(vbox)
	panel.add_child(margin)
	
	panel.ready.connect(func() -> void:
		border.update_shader_parameters()
	)
	
	_set_mouse_filter_ignore_recursive(panel)
	return panel

func _set_mouse_filter_ignore_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_set_mouse_filter_ignore_recursive(child)
