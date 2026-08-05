class_name OpponentProfile
extends RefCounted

var id: int
var name: String
var lives: int = 5
var archetypes: Array[String] = []
var active_team: Array[UnitInstance] = []
var relics: Array[RelicInstance] = []

func clone() -> OpponentProfile:
	var copy: OpponentProfile = OpponentProfile.new()
	copy.id = id
	copy.name = name
	copy.lives = lives
	copy.archetypes = archetypes.duplicate()
	
	var cloned_team: Array[UnitInstance] = []
	for u: UnitInstance in active_team:
		if u:
			cloned_team.append(u.clone())
		else:
			cloned_team.append(null)
	copy.active_team = cloned_team
	
	var cloned_relics: Array[RelicInstance] = []
	for r: RelicInstance in relics:
		if r:
			cloned_relics.append(r.clone())
	copy.relics = cloned_relics
	
	return copy
