class_name RelicSlot
extends Control

@onready var icon_label: Label = $Container/IconLabel
@onready var stacks_label: Label = $Container/StacksBadge/StacksLabel
@onready var stacks_badge: Control = $Container/StacksBadge
@onready var border_rect: ShaderBorderDecorator = $Container/BorderRect

var tooltip: CardTooltip = null
var relic: RelicInstance = null

func _ready() -> void:
	clear()
	
	mouse_entered.connect(func() -> void:
		if tooltip and relic:
			CardUIHelper.show_relic_tooltip(tooltip, relic)
	)
	mouse_exited.connect(func() -> void:
		if tooltip:
			CardUIHelper.hide_tooltip(tooltip)
	)

func set_relic(p_relic: RelicInstance, p_tooltip: CardTooltip) -> void:
	relic = p_relic
	tooltip = p_tooltip
	
	if relic:
		# Aktualizuj kolor obramowania
		border_rect.set_border_color(relic.data.rarity.border_color)
		
		# Pokaż ikonkę (obecnie wyświetlamy nazwę)
		icon_label.text = relic.data.display_name
		icon_label.visible = true
		
		if relic.stacks > 1:
			stacks_badge.visible = true
			stacks_label.text = str(relic.stacks)
		else:
			stacks_badge.visible = false
	else:
		clear()

func clear() -> void:
	relic = null
	icon_label.visible = false
	stacks_badge.visible = false
	border_rect.set_border_color(GameColors.BORDER_OUTER_DEFAULT)
