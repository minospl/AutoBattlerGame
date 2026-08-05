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
		profile.lives = 5
		# TODO: W przyszłości przypisać archetypy e.g. ["Beast", "Dragon"]
		_bots.append(profile)

func get_next_opponent(run_state: RunState) -> OpponentProfile:
	# Tymczasowa symulacja: Wybieramy losowego żyjącego bota (lub pierwszego z brzegu)
	var alive: Array[OpponentProfile] = get_all_alive_opponents(run_state)
	var opponent: OpponentProfile = null
	if alive.size() > 0:
		opponent = alive.pick_random()
	else:
		opponent = _bots[0] # Fallback
		
	# Aktualizacja jego drużyny nowym generatorem (zalążek ewolucji)
	opponent.active_team = EnemyTeamGenerator.generate_enemy_team(run_state.day, _unit_templates)
	return opponent

func get_all_alive_opponents(run_state: RunState) -> Array[OpponentProfile]:
	var opponents: Array[OpponentProfile] = []
	
	for bot: OpponentProfile in _bots:
		if bot.lives > 0:
			# Odświeżamy ich drużynę na dany dzień (tymczasowe dopóki nie ma ewolucji)
			bot.active_team = EnemyTeamGenerator.generate_enemy_team(run_state.day, _unit_templates)
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
