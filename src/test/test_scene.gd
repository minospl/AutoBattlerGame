extends Control

# List of pre-created monster resources to spawn randomly
var monster_templates: Array[MonsterData] = []

@onready var team_bench_view: TeamBenchView = %TeamBenchView
@onready var console_log: RichTextLabel = %ConsoleLog

func _ready() -> void:
	# Apply visual styling programmatically to keep the presentation premium and clean
	_apply_visual_styling()
	
	# Load our pre-created templates
	var paths = [
		"res://src/resources/monsters/czerwony_smok.tres",
		"res://src/resources/monsters/lesny_straznik.tres",
		"res://src/resources/monsters/dziki_wilk.tres",
		"res://src/resources/monsters/rzeczny_krab.tres"
	]
	
	for path in paths:
		if not ResourceLoader.exists(path):
			log_message("[color=#e53e3e][BŁĄD] Plik nie istnieje: %s[/color]" % path)
			continue
			
		var template = load(path)
		if template == null:
			log_message("[color=#e53e3e][BŁĄD] Błąd ładowania pliku .tres: %s[/color]" % path)
			log_message("[color=#ecc94b]WSKAZÓWKA: Otwórz projekt w Edytorze Godot (GUI), aby automatycznie zaimportować nowe pliki PNG![/color]")
			continue
			
		if not (template is MonsterData):
			log_message("[color=#e53e3e][BŁĄD] Zasób nie jest typu MonsterData: %s[/color]" % path)
			continue
			
		monster_templates.append(template)
			
	log_message("[color=#63b3ed][SYSTEM] Pomyślnie załadowano %d szablonów potworów.[/color]" % monster_templates.size())
	
	# Connect view signals
	team_bench_view.team_state_changed.connect(_on_team_state_changed)
	
	# Spawn initial monsters
	_on_add_monster_pressed()
	_on_add_monster_pressed()
	
	# Hide logs on start
	%LogSection.visible = false

func _apply_visual_styling() -> void:
	# 1. Main Background Panel
	var bg_panel = get_node("BackgroundPanel") as Panel
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.04, 0.04, 0.05, 1.0) # Deep pitch black-blue
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	
	# 2. Add Monster Button (Premium Green Action)
	var add_btn = %AddButton as Button
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.15, 0.50, 0.30, 1.0) # Flat emerald green
	btn_normal.corner_radius_top_left = 6
	btn_normal.corner_radius_top_right = 6
	btn_normal.corner_radius_bottom_right = 6
	btn_normal.corner_radius_bottom_left = 6
	btn_normal.content_margin_left = 16
	btn_normal.content_margin_right = 16
	btn_normal.content_margin_top = 8
	btn_normal.content_margin_bottom = 8
	add_btn.add_theme_stylebox_override("normal", btn_normal)
	
	var btn_hover = btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.18, 0.60, 0.36, 1.0) # Brighter green on hover
	add_btn.add_theme_stylebox_override("hover", btn_hover)
	
	var btn_pressed = btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color(0.12, 0.40, 0.24, 1.0)
	add_btn.add_theme_stylebox_override("pressed", btn_pressed)
	
	# 3. Clear Button (Danger Outline Action)
	var clear_btn = %ClearButton as Button
	var clear_normal = StyleBoxFlat.new()
	clear_normal.bg_color = Color(0.10, 0.11, 0.13, 1.0) # Sleek dark
	clear_normal.border_width_left = 1
	clear_normal.border_width_top = 1
	clear_normal.border_width_right = 1
	clear_normal.border_width_bottom = 1
	clear_normal.border_color = Color(0.80, 0.30, 0.30, 0.7) # Red outline
	clear_normal.corner_radius_top_left = 6
	clear_normal.corner_radius_top_right = 6
	clear_normal.corner_radius_bottom_right = 6
	clear_normal.corner_radius_bottom_left = 6
	clear_normal.content_margin_left = 16
	clear_normal.content_margin_right = 16
	clear_normal.content_margin_top = 8
	clear_normal.content_margin_bottom = 8
	clear_btn.add_theme_stylebox_override("normal", clear_normal)
	
	var clear_hover = clear_normal.duplicate() as StyleBoxFlat
	clear_hover.bg_color = Color(0.80, 0.30, 0.30, 0.15) # Red tint on hover
	clear_btn.add_theme_stylebox_override("hover", clear_hover)
	
	var clear_pressed = clear_normal.duplicate() as StyleBoxFlat
	clear_pressed.bg_color = Color(0.80, 0.30, 0.30, 0.30)
	clear_btn.add_theme_stylebox_override("pressed", clear_pressed)
	
	# 3b. Multiply Button (Premium Purple Action)
	var multiply_btn = %MultiplyButton as Button
	var mult_normal = StyleBoxFlat.new()
	mult_normal.bg_color = Color(0.45, 0.25, 0.75, 1.0) # Flat purple
	mult_normal.corner_radius_top_left = 6
	mult_normal.corner_radius_top_right = 6
	mult_normal.corner_radius_bottom_right = 6
	mult_normal.corner_radius_bottom_left = 6
	mult_normal.content_margin_left = 16
	mult_normal.content_margin_right = 16
	mult_normal.content_margin_top = 8
	mult_normal.content_margin_bottom = 8
	multiply_btn.add_theme_stylebox_override("normal", mult_normal)
	
	var mult_hover = mult_normal.duplicate() as StyleBoxFlat
	mult_hover.bg_color = Color(0.55, 0.30, 0.85, 1.0) # Brighter purple on hover
	multiply_btn.add_theme_stylebox_override("hover", mult_hover)
	
	var mult_pressed = mult_normal.duplicate() as StyleBoxFlat
	mult_pressed.bg_color = Color(0.35, 0.20, 0.60, 1.0)
	multiply_btn.add_theme_stylebox_override("pressed", mult_pressed)
	
	# 3c. Toggle Log Button (Sleek Dark Gray with border)
	var toggle_btn = %ToggleLogButton as Button
	var toggle_normal = StyleBoxFlat.new()
	toggle_normal.bg_color = Color(0.12, 0.13, 0.15, 1.0) # Dark gray
	toggle_normal.border_width_left = 1
	toggle_normal.border_width_top = 1
	toggle_normal.border_width_right = 1
	toggle_normal.border_width_bottom = 1
	toggle_normal.border_color = Color(0.35, 0.50, 0.90, 0.7) # Indigo/blue border
	toggle_normal.corner_radius_top_left = 6
	toggle_normal.corner_radius_top_right = 6
	toggle_normal.corner_radius_bottom_right = 6
	toggle_normal.corner_radius_bottom_left = 6
	toggle_normal.content_margin_left = 16
	toggle_normal.content_margin_right = 16
	toggle_normal.content_margin_top = 8
	toggle_normal.content_margin_bottom = 8
	toggle_btn.add_theme_stylebox_override("normal", toggle_normal)
	
	var toggle_hover = toggle_normal.duplicate() as StyleBoxFlat
	toggle_hover.bg_color = Color(0.35, 0.50, 0.90, 0.15) # Indigo tint on hover
	toggle_btn.add_theme_stylebox_override("hover", toggle_hover)
	
	var toggle_pressed = toggle_normal.duplicate() as StyleBoxFlat
	toggle_pressed.bg_color = Color(0.35, 0.50, 0.90, 0.30)
	toggle_btn.add_theme_stylebox_override("pressed", toggle_pressed)
	
	# 4. Console Log Panel
	var log_panel = %LogPanel as PanelContainer
	var log_style = StyleBoxFlat.new()
	log_style.bg_color = Color(0.02, 0.02, 0.03, 1.0) # Solid pitch black
	log_style.border_width_left = 1
	log_style.border_width_top = 1
	log_style.border_width_right = 1
	log_style.border_width_bottom = 1
	log_style.border_color = Color(0.12, 0.13, 0.15, 1.0) # Very dark border
	log_style.corner_radius_top_left = 8
	log_style.corner_radius_top_right = 8
	log_style.corner_radius_bottom_right = 8
	log_style.corner_radius_bottom_left = 8
	log_style.content_margin_left = 12
	log_style.content_margin_right = 12
	log_style.content_margin_top = 10
	log_style.content_margin_bottom = 10
	log_panel.add_theme_stylebox_override("panel", log_style)

func log_message(msg: String) -> void:
	console_log.append_text(msg + "\n")
	var scroll = console_log.get_v_scroll_bar()
	if scroll:
		scroll.value = scroll.max_value

func _on_add_monster_pressed() -> void:
	if monster_templates.is_empty():
		log_message("[color=#e53e3e][BŁĄD] Brak załadowanych szablonów potworów![/color]")
		return
		
	# Pick random template
	var template = monster_templates[randi() % monster_templates.size()]
	
	# Create runtime instance
	var instance = MonsterInstance.new()
	instance.initialize(template)
	
	# Try to add to bench
	var success = team_bench_view.add_monster_to_bench(instance)
	if success:
		var types_str = ""
		for type in instance.get_types():
			# Convert color to hex for BBCode styling
			var hex_color = type.color.to_html(false)
			types_str += "[color=#%s][%s][/color] " % [hex_color, type.type_name]
			
		var rarity_str = "Common"
		var rarity_color = "718096"
		if instance.data and instance.data.rarity:
			rarity_str = instance.data.rarity.rarity_name
			rarity_color = instance.data.rarity.border_color.to_html(false)
			
		log_message("[color=#48bb78][SPAWN][/color] Dodano do ławki: [b]%s[/b] [color=#%s](%s)[/color] (Atak: %d, HP: %d) Typy: %s" % [
			instance.get_monster_name(), rarity_color, rarity_str, instance.get_attack(), instance.get_max_health(), types_str
		])
	else:
		log_message("[color=#ecc94b][OSTRZEŻENIE] Ławka rezerwowych jest pełna![/color]")

func _on_clear_pressed() -> void:
	team_bench_view.clear_all()
	log_message("[color=#718096][SYSTEM] Wyczyszczono całą drużynę i ławkę.[/color]")

func _on_multiply_pressed() -> void:
	for m in team_bench_view.active_team:
		if m:
			m.current_attack *= 10
			m.current_health *= 10
			m.poison *= 10
	for m in team_bench_view.bench:
		if m:
			m.current_attack *= 10
			m.current_health *= 10
			m.poison *= 10
			
	# Refresh all UI cards and slot health bars
	for slot in team_bench_view.active_slots + team_bench_view.bench_slots:
		var card = slot.get_card()
		if card:
			card.update_ui()
			slot.update_health_bar()
			
	log_message("[color=#eb3860][MOC x10][/color] Pomnożono statystyki wszystkich potworów x10!")

func _on_team_state_changed() -> void:
	log_message("[color=#4299e1][ZMIANA POZYCJI][/color] Stan zaktualizowany:")
	
	# Log active team
	var active_names = []
	for i in range(team_bench_view.active_team.size()):
		var m = team_bench_view.active_team[i]
		if m:
			active_names.append("Slot %d: %s" % [i, m.get_monster_name()])
		else:
			active_names.append("Slot %d: Pusty" % i)
			
	# Log bench
	var bench_names = []
	for i in range(team_bench_view.bench.size()):
		var m = team_bench_view.bench[i]
		if m:
			bench_names.append(m.get_monster_name())
		else:
			bench_names.append("Pusty")
			
	log_message("  [b]Drużyna:[/b] " + ", ".join(active_names))
	log_message("  [b]Ławka:[/b] [" + ", ".join(bench_names) + "]")

func _on_toggle_log_pressed() -> void:
	%LogSection.visible = not %LogSection.visible
	if %LogSection.visible:
		%ToggleLogButton.text = "Ukryj Logi"
	else:
		%ToggleLogButton.text = "Pokaż Logi"
