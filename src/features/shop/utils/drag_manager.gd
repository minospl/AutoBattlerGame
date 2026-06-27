class_name DragManager
extends RefCounted

static var dragged_card: Control = null
static var dragged_card_original_slot: Control = null

static func notify_drag_started(card: Control, original_slot: Control) -> void:
	dragged_card = card
	dragged_card_original_slot = original_slot

static func notify_drag_ended() -> void:
	dragged_card = null
	dragged_card_original_slot = null
