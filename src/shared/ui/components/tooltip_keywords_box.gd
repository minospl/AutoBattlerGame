class_name TooltipKeywordsBox
extends VBoxContainer

const KEYWORD_PANEL_SCENE: PackedScene = preload("res://src/shared/ui/components/keyword_panel.tscn")

func build_keywords(unit_instance: UnitInstance) -> int:
	# Clear old nodes
	for child: Node in get_children():
		child.queue_free()
		
	if not unit_instance:
		return 0
		
	var keywords: Array[Dictionary] = KeywordDatabase.get_keywords_for_unit(unit_instance, unit_instance.level)
	for kw: Dictionary in keywords:
		var panel: KeywordPanel = KEYWORD_PANEL_SCENE.instantiate()
		panel.setup(str(kw["title"]), str(kw["desc"]))
		add_child(panel)
		
	return keywords.size()