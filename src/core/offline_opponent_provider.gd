class_name OfflineOpponentProvider
extends OpponentProvider

var _bots: Array[OpponentProfile] = []
var _unit_templates: Array[UnitData] = []

func _init(p_templates: Array[UnitData]) -> void:
	_unit_templates = p_templates
	
	# Inicjalizacja puli symulowanych rywali (botów)
	for i: int in range(7):
		var profile: OpponentProfile = OpponentProfile.new()
		profile.id = i + 1
		profile.name = "Bot %d" % (i + 1)
		profile.data.lives = 5
		# TODO: W przyszłości przypisać archetypy e.g. ["Beast", "Dragon"]
		_bots.append(profile)

const POOL_SIZE: int = 3

func update_opponents_pool(run_state: RunState) -> void:
	var new_pool: Array[OpponentProfile] = []
	for bot: OpponentProfile in run_state.opponents_pool:
		if bot != null and bot.data.lives > 0:
			new_pool.append(bot)
			
	var available_bots: Array[OpponentProfile] = []
	for bot: OpponentProfile in _bots:
		if bot != null and bot.data.lives > 0 and not new_pool.has(bot):
			available_bots.append(bot)

	available_bots.shuffle()

	for bot: OpponentProfile in available_bots:
		if new_pool.size() >= POOL_SIZE:
			break
		new_pool.append(bot)

	if new_pool.is_empty() and _bots.size() > 0:
		new_pool.append(_bots[0])

	run_state.opponents_pool = new_pool

func select_next_opponent(run_state: RunState, previous_opponent: OpponentProfile = null) -> OpponentProfile:
	if run_state.opponents_pool.is_empty():
		update_opponents_pool(run_state)
		
	var alive_in_pool: Array[OpponentProfile] = []
	for bot: OpponentProfile in run_state.opponents_pool:
		if bot != null and bot.data.lives > 0:
			alive_in_pool.append(bot)

	var candidates: Array[OpponentProfile] = []
	if previous_opponent != null:
		for bot: OpponentProfile in alive_in_pool:
			if bot.id != previous_opponent.id:
				candidates.append(bot)
	
	if candidates.is_empty():
		candidates = alive_in_pool

	var chosen: OpponentProfile = null
	if candidates.size() > 0:
		chosen = candidates.pick_random()
	elif _bots.size() > 0:
		chosen = _bots[0]

	if chosen != null:
		chosen.data.active_team = EnemyTeamGenerator.generate_enemy_team(run_state.day, _unit_templates)

	return chosen

func get_next_opponent(run_state: RunState) -> OpponentProfile:
	if run_state.next_opponent == null:
		update_opponents_pool(run_state)
		run_state.next_opponent = select_next_opponent(run_state)
	return run_state.next_opponent

func get_all_alive_opponents(run_state: RunState) -> Array[OpponentProfile]:
	var opponents: Array[OpponentProfile] = []
	
	for bot: OpponentProfile in _bots:
		if bot.data.lives > 0:
			# Odświeżamy ich drużynę na dany dzień (tymczasowe dopóki nie ma ewolucji)
			bot.data.active_team = EnemyTeamGenerator.generate_enemy_team(run_state.day, _unit_templates)
			opponents.append(bot)
			
	# Upewniamy się, że zawsze jest chociaż minimum 1 przeciwnik do deathmatchu
	if opponents.is_empty() and _bots.size() > 0:
		opponents.append(_bots[0])
		
	return opponents

func get_all_opponents() -> Array[OpponentProfile]:
	var copy: Array[OpponentProfile] = []
	for bot: OpponentProfile in _bots:
		copy.append(bot.clone())
	return copy
