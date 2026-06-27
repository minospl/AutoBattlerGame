class_name RunState
extends Resource

@export var active_team: Array[UnitInstance] = []
@export var bench: Array[UnitInstance] = []
@export var shop_units: Array[Resource] = [] # Can hold UnitInstance, ShopItemInstance, or null
@export var shop_frozen_statuses: Array[bool] = []
@export var gold: int = 10
@export var lives: int = 10
@export var day: int = 4
@export var trophies: int = 3
@export var max_trophies: int = 10
