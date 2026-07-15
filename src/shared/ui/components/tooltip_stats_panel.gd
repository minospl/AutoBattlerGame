class_name TooltipStatsPanel
extends MarginContainer

@onready var stats_grid: GridContainer = %StatsGrid
@onready var stat_label_template: RichTextLabel = %StatLabelTemplate

func setup(unit_instance: UnitInstance) -> void:
	update_dynamic_stats(unit_instance)

func update_dynamic_stats(unit_instance: UnitInstance) -> void:
	if not unit_instance:
		return
		
	var active_stats: PackedStringArray = PackedStringArray()
	active_stats.append("%s [color=%s]HP[/color]" % [NumberFormatter.format_large_number(unit_instance.get_max_health()), GameColors.DESC_HEALTH])
	active_stats.append(str(unit_instance.get_cast_speed()).trim_suffix(".0") + " [color=%s]CD[/color]" % GameColors.DESC_CAST_SPEED)

	if unit_instance.get_attack() > 0:
		active_stats.append("%s [color=%s]ATK[/color]" % [NumberFormatter.format_large_number(unit_instance.get_attack()), GameColors.DESC_ATTACK])
	if unit_instance.heal > 0:
		active_stats.append("%s [color=%s]HEAL[/color]" % [NumberFormatter.format_large_number(unit_instance.heal), GameColors.DESC_HEAL])
	if unit_instance.shield > 0:
		active_stats.append("%s [color=%s]SHIELD[/color]" % [NumberFormatter.format_large_number(unit_instance.shield), GameColors.DESC_SHIELD])
	if unit_instance.poison > 0:
		active_stats.append("%s [color=%s]POISON[/color]" % [NumberFormatter.format_large_number(unit_instance.poison), GameColors.DESC_POISON])
	if unit_instance.burn > 0:
		active_stats.append("%s [color=%s]BURN[/color]" % [NumberFormatter.format_large_number(unit_instance.burn), GameColors.DESC_BURN])
	if unit_instance.electrocute > 0:
		active_stats.append("%s [color=%s]ELEC[/color]" % [NumberFormatter.format_large_number(unit_instance.electrocute), GameColors.DESC_ELECTROCUTE])

	# Node reuse (Object pooling) logic
	var needed_labels: int = active_stats.size()
	var existing_children: Array[Node] = stats_grid.get_children()
	
	# Add labels if we don't have enough
	while existing_children.size() < needed_labels:
		var new_lbl: RichTextLabel = stat_label_template.duplicate() as RichTextLabel
		stats_grid.add_child(new_lbl)
		existing_children.append(new_lbl)
		
	# Update all labels text and visibility
	for idx: int in range(existing_children.size()):
		var lbl: RichTextLabel = existing_children[idx] as RichTextLabel
		if idx < needed_labels:
			if idx < active_stats.size():
				lbl.text = active_stats[idx]
			else:
				lbl.text = ""
			lbl.visible = true
		else:
			lbl.visible = false
