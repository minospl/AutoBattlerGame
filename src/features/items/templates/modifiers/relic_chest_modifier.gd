class_name RelicChestModifier
extends ItemModifier

@export var target_rarity: Rarity

func apply_shop_effect(run_state: RunState) -> void:
	if not run_state or not target_rarity:
		return
		
	# 1. Zbieramy tylko te relikty, które pasują i nie są posiadanymi unikalnymi
	var available_relics: Array[RelicData] = run_state.get_available_relic_templates(target_rarity)
			
	# 2. Bezpieczeństwo na wypadek braku jakichkolwiek zdefiniowanych reliktów tej rzadkości w bazie danych
	if available_relics.is_empty():
		printerr("No relics found matching rarity: ", target_rarity.rarity_name)
		return
		
	# 3. Losujemy i dodajemy
	var rolled_relic: RelicData = available_relics[randi() % available_relics.size()]
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
