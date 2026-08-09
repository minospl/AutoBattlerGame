class_name OpponentProfile
extends RefCounted

var id: int
var name: String
var archetypes: Array[String] = []

var data: RunData = RunData.new()

func clone() -> OpponentProfile:
	var copy: OpponentProfile = OpponentProfile.new()
	copy.id = id
	copy.name = name
	copy.archetypes = archetypes.duplicate()
	copy.data = data.duplicate_data()
	
	return copy
