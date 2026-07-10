class_name RelicChestModifier
extends ItemModifier

@export var target_rarity: Rarity

func apply_shop_effect(run_state: RunState) -> void:
	if not run_state or not target_rarity:
		return
		
	# Filter relic templates by target_rarity
	var matching_relics: Array[RelicData] = []
	for relic: RelicData in run_state.relic_templates:
		if relic and relic.rarity and relic.rarity.rarity_name == target_rarity.rarity_name:
			matching_relics.append(relic)
			
	if matching_relics.is_empty():
		printerr("No relics found matching rarity: ", target_rarity.rarity_name)
		return
		
	# Select a random one
	var rolled_relic: RelicData = matching_relics[randi() % matching_relics.size()]
	
	# Instantiate and add to player's relics
	var relic_inst: RelicInstance = RelicInstance.new()
	relic_inst.initialize(rolled_relic)
	run_state.add_relic(relic_inst)

func get_description() -> String:
	var rarity_str: String = target_rarity.rarity_name if target_rarity else "Unknown"
	var text_color: Color = Color.GRAY
	if target_rarity:
		text_color = target_rarity.border_color
	
	var color_hex: String = text_color.to_html(false)
	return "Click to purchase a random [color=#%s]%s[/color] Relic." % [color_hex, rarity_str]
