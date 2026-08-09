class_name OpponentPreviewModal
extends Control

const UNIT_CARD: PackedScene = preload("res://src/features/shop/components/unit_card.tscn")
const UNIT_SLOT: PackedScene = preload("res://src/features/shop/components/unit_slot.tscn")

@onready var title_label: Label = %TitleLabel
@onready var stats_label: Label = %StatsLabel
@onready var grid_container: GridContainer = %GridContainer
@onready var close_btn: Button = %CloseButton

var preview_tooltip: CardTooltip = null

func setup(bot: OpponentProfile, tooltip: CardTooltip) -> void:
	preview_tooltip = tooltip
	title_label.text = bot.name if bot and "name" in bot else "Opponent " + str(bot.id)
		
	stats_label.text = "Lives: %d | Gold: %d | Shop Lvl: %d" % [bot.data.lives, bot.data.gold, bot.data.shop_level]
	for child: Node in grid_container.get_children():
		child.queue_free()
		
	for i: int in range(RunData.MAX_ACTIVE_TEAM_SIZE):
		var u: UnitInstance = bot.data.active_team[i]
		if u:
			var card_inst: UnitCard = UNIT_CARD.instantiate() as UnitCard
			card_inst.mouse_filter = Control.MOUSE_FILTER_PASS
			card_inst.unit_instance = u
			card_inst.hovered.connect(func(c: UnitCard, is_hov: bool) -> void:
				if preview_tooltip:
					if is_hov:
						CardUIHelper.show_tooltip(preview_tooltip, c.unit_instance)
					else:
						CardUIHelper.hide_tooltip(preview_tooltip)
			)
			grid_container.add_child(card_inst)
		else:			
			var empty_slot: Control = UNIT_SLOT.instantiate() as Control
			empty_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			var container: Control = empty_slot.get_node_or_null("%CardContainer") as Control
			if container: container.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			grid_container.add_child(empty_slot)

func _ready() -> void:
	close_btn.pressed.connect(func() -> void:
		CardUIHelper.hide_tooltip(preview_tooltip)
		queue_free()
	)
