class_name BattleTeam
extends RefCounted

# Signals for communicating with BattleScene controller
signal team_units_loaded(loaded_units: Array[UnitInstance])
signal health_changed(current_health: int, max_health: int, shield: int)
signal status_changed(status_type: String, amount: int, cooldown_ratio: float)
signal cast_progress_changed(slot_idx: int, ratio: float)
signal floating_text_requested(text: String, color: Color, is_on_slot: bool, slot_idx: int)
signal team_defeated()

const MAX_TEAM_SIZE: int = 6

# Combat State
var units: Array[UnitInstance] = []
var cast_timers: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

var max_health: int = 0
var health: int = 0
var shield: int = 0

# Status Effects
var poison: int = 0
var poison_timer: float = 0.0
var burn: int = 0
var burn_timer: float = 0.0
var electrocute: int = 0

var is_enemy: bool = false

func initialize(p_is_enemy: bool = false) -> void:
	is_enemy = p_is_enemy
	
	units.clear()
	units.resize(MAX_TEAM_SIZE)
	cast_timers = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

func load_team_units(new_units: Array[UnitInstance]) -> void:
	shield = 0
	poison = 0
	poison_timer = 0.0
	burn = 0
	burn_timer = 0.0
	electrocute = 0
	
	health = 0
	max_health = 0
	
	var num_units: int = mini(MAX_TEAM_SIZE, new_units.size())
	for i: int in range(MAX_TEAM_SIZE):
		if i < num_units and new_units[i]:
			var inst: UnitInstance = new_units[i]
			var battle_inst: BattleUnitInstance = BattleUnitInstance.new()
			battle_inst.initialize_battle_unit(inst)
			units[i] = battle_inst
			health += battle_inst.get_max_health()
			max_health += battle_inst.get_max_health()
		else:
			units[i] = null
			
	cast_timers = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	
	team_units_loaded.emit(units)
	health_changed.emit(health, max_health, shield)
	status_changed.emit("poison", poison, 0.0)
	status_changed.emit("burn", burn, 0.0)
	status_changed.emit("electrocute", electrocute, 0.0)

func execute_cast(source_idx: int, opponent: BattleTeam) -> void:
	var unit: UnitInstance = units[source_idx]
	if not unit:
		return
		
	# Attack opponent team!
	var dmg: int = unit.get_attack()
	if dmg > 0:
		if opponent.electrocute > 0:
			dmg += opponent.electrocute
		opponent.take_damage(dmg)
		
	# Apply status effects to opponent
	if unit.poison > 0:
		opponent.apply_status("poison", unit.poison)
	if unit.burn > 0:
		opponent.apply_status("burn", unit.burn)
	if unit.electrocute > 0:
		opponent.apply_status("electrocute", unit.electrocute)
		
	# Apply self/team effects
	if unit.heal > 0:
		heal(unit.heal)
	if unit.shield > 0:
		add_shield(unit.shield)
		
	# Trigger ON_CAST modifier
	ModifierEngine.trigger_unit_modifier(source_idx, self, UnitModifier.Trigger.ON_CAST)

func take_damage(amount: int, damage_type: String = "physical") -> void:
	if amount <= 0:
		return
		
	var actual_dmg: int = amount
	var text_color: Color = Color(1.0, 0.3, 0.3) # default red
	
	if damage_type == "poison":
		text_color = Color(0.7, 0.3, 0.8) # purple
	elif damage_type == "burn":
		text_color = Color(0.9, 0.4, 0.1) # orange
	else:
		# physical
		if is_enemy:
			text_color = Color(1.0, 1.0, 1.0) # white for enemy
		else:
			text_color = Color(1.0, 0.3, 0.3) # red for friendly
			
	# Apply shield absorption
	if shield >= actual_dmg:
		shield -= actual_dmg
	else:
		var remaining_dmg: int = actual_dmg - shield
		shield = 0
		health -= remaining_dmg
		
	health_changed.emit(health, max_health, shield)
	floating_text_requested.emit("-" + str(actual_dmg), text_color, false, 0)
		
	if max_health > 0 and health <= 0:
		team_defeated.emit()

func heal(amount: int, source_slot_idx: int = -1) -> void:
	if amount <= 0:
		return
	var health_before: int = health
	health = min(health + amount, max_health)
	var actual_heal: int = health - health_before
	
	health_changed.emit(health, max_health, shield)
	
	if actual_heal > 0:
		if source_slot_idx != -1:
			spawn_floating_text_on_slot(source_slot_idx, "+" + str(actual_heal), Color(0.2, 0.9, 0.2))
		else:
			floating_text_requested.emit("+" + str(actual_heal), Color(0.2, 0.9, 0.2), false, 0)

func add_shield(amount: int) -> void:
	if amount <= 0:
		return
	shield += amount
	health_changed.emit(health, max_health, shield)
	floating_text_requested.emit("+" + str(amount), Color(0.7, 0.7, 0.7), false, 0)

func apply_status(status_type: String, amount: int) -> void:
	if amount <= 0:
		return
	if status_type == "poison":
		poison += amount
	elif status_type == "burn":
		burn += amount
	elif status_type == "electrocute":
		electrocute += amount
		
	status_changed.emit(status_type, get_status_value(status_type), get_status_cooldown_ratio(status_type))

func get_status_value(status_type: String) -> int:
	match status_type:
		"poison": return poison
		"burn": return burn
		"electrocute": return electrocute
	return 0

func get_status_cooldown_ratio(status_type: String) -> float:
	match status_type:
		"poison": return clampf(poison_timer / 1.0, 0.0, 1.0)
		"burn": return clampf(burn_timer / 0.5, 0.0, 1.0)
	return 0.0

func tick_statuses(delta: float) -> void:
	# Tick poison status every second!
	if poison > 0:
		poison_timer += delta
		if poison_timer >= 1.0:
			poison_timer -= 1.0
			take_damage(poison, "poison")
		status_changed.emit("poison", poison, clampf(poison_timer / 1.0, 0.0, 1.0))
	else:
		if poison_timer > 0.0:
			poison_timer = 0.0
			status_changed.emit("poison", 0, 0.0)

	# Tick burn status every 0.5 seconds!
	if burn > 0:
		burn_timer += delta
		if burn_timer >= 0.5:
			burn_timer -= 0.5
			take_damage(burn, "burn")
			burn = max(0, burn - 1)
		status_changed.emit("burn", burn, clampf(burn_timer / 0.5, 0.0, 1.0))
	else:
		if burn_timer > 0.0:
			burn_timer = 0.0
			status_changed.emit("burn", 0, 0.0)

func tick_casts(delta: float, game_speed: float, cast_callback: Callable) -> void:
	for i: int in range(MAX_TEAM_SIZE):
		if units[i]:
			cast_timers[i] += delta * game_speed
			var speed: float = units[i].get_cast_speed()
			if speed <= 0.0: speed = 1.0
			
			cast_progress_changed.emit(i, cast_timers[i] / speed)
			
			if cast_timers[i] >= speed:
				cast_timers[i] = 0.0
				cast_callback.call(i)




func spawn_floating_text_on_slot(t_idx: int, text: String, color: Color) -> void:
	floating_text_requested.emit(text, color, true, t_idx)

func buff_unit_attack(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.attack += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.attack += amount
	spawn_floating_text_on_slot(slot_idx, "+" + str(amount) + " ATK", Color(1.0, 0.85, 0.2))

func buff_unit_max_health(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.health += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.health += amount
	max_health += amount
	health += amount
	health_changed.emit(health, max_health, shield)
	spawn_floating_text_on_slot(slot_idx, "+" + str(amount) + " HP", Color(1.0, 0.3, 0.3))

func add_unit_shield(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.shield += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.shield += amount
	shield += amount
	health_changed.emit(health, max_health, shield)
	spawn_floating_text_on_slot(slot_idx, "+" + str(amount) + " Shield", Color(0.7, 0.7, 0.7))

func buff_unit_poison(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.poison += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.poison += amount
	spawn_floating_text_on_slot(slot_idx, "+" + str(amount) + " Poison", Color(0.7, 0.3, 0.8))

func buff_unit_burn(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.burn += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.burn += amount
	spawn_floating_text_on_slot(slot_idx, "+" + str(amount) + " Burn", Color(0.9, 0.4, 0.1))

func buff_unit_electrocute(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.electrocute += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.electrocute += amount
	spawn_floating_text_on_slot(slot_idx, "+" + str(amount) + " Electrocute", Color(0.3, 0.7, 1.0))

func buff_unit_heal_power(slot_idx: int, amount: int, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.heal += amount
		if permanent and b_unit.base_unit:
			b_unit.base_unit.heal += amount
	spawn_floating_text_on_slot(slot_idx, "+" + str(amount) + " Heal Power", Color(0.2, 0.9, 0.2))

func buff_unit_cast_speed(slot_idx: int, amount: float, permanent: bool = false) -> void:
	if slot_idx < 0 or slot_idx >= units.size() or not units[slot_idx]:
		return
	var b_unit: BattleUnitInstance = units[slot_idx] as BattleUnitInstance
	if b_unit:
		b_unit.cast_speed = maxf(0.1, b_unit.cast_speed - amount)
		if permanent and b_unit.base_unit:
			b_unit.base_unit.cast_speed = maxf(0.1, b_unit.base_unit.cast_speed - amount)
	spawn_floating_text_on_slot(slot_idx, "-" + str(amount) + "s CD", Color(0.5, 0.8, 1.0))
