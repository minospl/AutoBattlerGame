class_name EnemyTeamGenerator
extends RefCounted

static func generate_enemy_team(day: int) -> Array[UnitInstance]:
	var enemies: Array[UnitInstance] = []
	enemies.resize(6)
	
	var team_size: int = clampi(1 + floori((day - 1) / 2.0), 1, 6)
	
	var max_price_unlocked: int = 2
	if day >= 3 and day <= 5:
		max_price_unlocked = 3
	if day >= 6:
		max_price_unlocked = 4
	if day >= 10:
		max_price_unlocked = 5
		
	var pool: Array[UnitData] = []
	for t: UnitData in GameTemplates.units:
		if t.price <= max_price_unlocked:
			pool.append(t)
			
	if pool.is_empty():
		return enemies
		
	for i: int in range(team_size):
		var template: UnitData = pool[randi() % pool.size()]
		var inst: UnitInstance = UnitInstance.new()
		inst.initialize(template)
		
		var target_level: int = clampi(1 + floori((day - 1) / 3.0), 1, 3)
		while inst.level < target_level:
			inst.level_up()
			
		enemies[i] = inst
		
	return enemies
