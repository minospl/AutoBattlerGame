class_name OpponentProvider
extends RefCounted

## Base class for opponent providers (e.g. Offline, Network, etc.)
## Updates the active pool of opponents in run_state (e.g. 3 opponents).
func update_opponents_pool(_run_state: RunState) -> void:
	pass

## Called to select the single next opponent for standard days from opponents_pool.
func select_next_opponent(_run_state: RunState, _previous_opponent: OpponentProfile = null) -> OpponentProfile:
	return null

## Called to generate or fetch the single opponent for standard days.
func get_next_opponent(_run_state: RunState) -> OpponentProfile:
	return null

## Called for deathmatch to return all remaining alive opponents.
func get_all_alive_opponents(_run_state: RunState) -> Array[OpponentProfile]:
	return []

## Called by the UI (e.g. Shop) to display the list of all opponents (alive and dead).
## Used to build an interactive panel where players can preview opponent's team and lives.
func get_all_opponents() -> Array[OpponentProfile]:
	return []
