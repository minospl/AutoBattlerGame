class_name UnitStatsBar
extends HBoxContainer

const STAT_BADGE_SCENE: PackedScene = preload("res://src/shared/ui/components/stat_badge.tscn")

@export var max_stats_count: int = 3
@export var badge_size: Vector2 = Vector2(28, 16)

var _badges: Array[StatBadge] = []

func _ready() -> void:
	add_theme_constant_override("separation", 0)
	alignment = BoxContainer.ALIGNMENT_CENTER
	_collect_badges()

func _collect_badges() -> void:
	_badges.clear()
	for child: Node in get_children():
		if child is StatBadge:
			_badges.append(child as StatBadge)

func setup_stats(unit_instance: UnitInstance) -> void:
	if not unit_instance:
		visible = false
		for badge: StatBadge in _badges:
			badge.visible = false
		return
		
	var candidates: Array[Dictionary] = []
	var atk_val: int = unit_instance.get_attack()
	if atk_val > 0:
		candidates.append({"type": StatType.Type.ATK, "value": atk_val, "priority": 0})
	if unit_instance.heal > 0:
		candidates.append({"type": StatType.Type.HEAL, "value": unit_instance.heal, "priority": 1})
	if unit_instance.shield > 0:
		candidates.append({"type": StatType.Type.SHIELD, "value": unit_instance.shield, "priority": 2})
	if unit_instance.poison > 0:
		candidates.append({"type": StatType.Type.POISON, "value": unit_instance.poison, "priority": 3})
	if unit_instance.burn > 0:
		candidates.append({"type": StatType.Type.BURN, "value": unit_instance.burn, "priority": 4})
	if unit_instance.electrocute > 0:
		candidates.append({"type": StatType.Type.ELECTROCUTE, "value": unit_instance.electrocute, "priority": 5})
		
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var val_a: int = a["value"]
		var val_b: int = b["value"]
		if val_a != val_b:
			return val_a > val_b
		var prio_a: int = a["priority"]
		var prio_b: int = b["priority"]
		return prio_a < prio_b
	)
	
	var active_stats: Array[Dictionary] = []
	var limit: int = min(candidates.size(), max_stats_count)
	for i: int in range(limit):
		active_stats.append(candidates[i])
		
	if active_stats.is_empty():
		visible = false
		for badge: StatBadge in _badges:
			badge.visible = false
		return
		
	visible = true
	
	while _badges.size() < active_stats.size():
		var new_badge: StatBadge = STAT_BADGE_SCENE.instantiate() as StatBadge
		if new_badge:
			add_child(new_badge)
			_badges.append(new_badge)
			
	for i: int in range(_badges.size()):
		var badge: StatBadge = _badges[i]
		if i < active_stats.size():
			badge.visible = true
			var info: Dictionary = active_stats[i]
			var st: StatType.Type = info["type"]
			var val: int = info["value"]
			badge.setup(st, val, badge_size)
		else:
			badge.visible = false
