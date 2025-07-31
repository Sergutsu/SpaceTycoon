extends Control
class_name SimpleHUD

# Simple HUD - Standalone version that doesn't require complex node structure
# Can be used immediately without scene setup

# UI Elements created dynamically
var credits_label: Label
var fuel_label: Label
var cargo_label: Label
var location_label: Label

# Game Manager reference
var game_manager: GameManager

func _ready():
	print("SimpleHUD: Initializing...")
	
	# Create UI elements dynamically
	_create_ui_elements()
	
	# Get game manager reference
	game_manager = get_node("../../GameManager")
	if game_manager:
		_connect_signals()
		_update_all_displays()
		print("SimpleHUD: Connected to GameManager")
	else:
		print("SimpleHUD: GameManager not found")

func _create_ui_elements():
	"""Create UI elements dynamically"""
	# Header panel
	var header_panel = Panel.new()
	header_panel.anchors_preset = Control.PRESET_TOP_WIDE
	header_panel.offset_bottom = 80
	add_child(header_panel)
	
	# Header container
	var header_container = HBoxContainer.new()
	header_container.anchors_preset = Control.PRESET_FULL_RECT
	header_container.offset_left = 20
	header_container.offset_top = 10
	header_container.offset_right = -20
	header_container.offset_bottom = -10
	header_panel.add_child(header_container)
	
	# Game title
	var title_label = Label.new()
	title_label.text = "Space Transport Tycoon"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 18)
	header_container.add_child(title_label)
	
	# Stats container
	var stats_container = HBoxContainer.new()
	stats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_container.alignment = BoxContainer.ALIGNMENT_END
	header_container.add_child(stats_container)
	
	# Credits label
	credits_label = Label.new()
	credits_label.text = "Credits: $0"
	stats_container.add_child(credits_label)
	
	# Fuel label
	fuel_label = Label.new()
	fuel_label.text = "Fuel: 0/100"
	stats_container.add_child(fuel_label)
	
	# Cargo label
	cargo_label = Label.new()
	cargo_label.text = "Cargo: 0/50"
	stats_container.add_child(cargo_label)
	
	# Location label
	location_label = Label.new()
	location_label.text = "Location: Unknown"
	stats_container.add_child(location_label)

func _connect_signals():
	"""Connect to GameManager signals"""
	if game_manager:
		game_manager.credits_changed.connect(_on_credits_changed)
		game_manager.fuel_changed.connect(_on_fuel_changed)
		game_manager.cargo_changed.connect(_on_cargo_changed)
		game_manager.location_changed.connect(_on_location_changed)

func _update_all_displays():
	"""Update all displays with current game state"""
	if not game_manager:
		return
	
	_on_credits_changed(game_manager.player_data.credits)
	_on_fuel_changed(game_manager.player_data.ship.current_fuel)
	_on_cargo_changed(game_manager.player_data.inventory)
	_on_location_changed(game_manager.player_data.current_system)

func _on_credits_changed(new_credits: int):
	"""Handle credits change"""
	if credits_label:
		credits_label.text = "Credits: $" + _format_number(new_credits)

func _on_fuel_changed(new_fuel: int):
	"""Handle fuel change"""
	if fuel_label:
		var max_fuel = game_manager.player_data.ship.fuel_capacity if game_manager else 100
		fuel_label.text = "Fuel: " + str(new_fuel) + "/" + str(max_fuel)
		
		# Color code based on fuel level
		var fuel_percentage = float(new_fuel) / float(max_fuel)
		if fuel_percentage < 0.2:
			fuel_label.modulate = Color.RED
		elif fuel_percentage < 0.5:
			fuel_label.modulate = Color.YELLOW
		else:
			fuel_label.modulate = Color.WHITE

func _on_cargo_changed(cargo_dict: Dictionary):
	"""Handle cargo change"""
	if cargo_label:
		var total_cargo = 0
		for amount in cargo_dict.values():
			total_cargo += amount
		
		var max_cargo = game_manager.player_data.ship.cargo_capacity if game_manager else 50
		cargo_label.text = "Cargo: " + str(total_cargo) + "/" + str(max_cargo)
		
		# Color code based on cargo level
		var cargo_percentage = float(total_cargo) / float(max_cargo)
		if cargo_percentage > 0.9:
			cargo_label.modulate = Color.ORANGE
		elif cargo_percentage > 0.7:
			cargo_label.modulate = Color.YELLOW
		else:
			cargo_label.modulate = Color.WHITE

func _on_location_changed(system_id: String):
	"""Handle location change"""
	if location_label and game_manager:
		var system_data = game_manager.economy_system.get_system_data(system_id)
		location_label.text = "Location: " + system_data.get("name", system_id)

func _format_number(number: int) -> String:
	"""Format large numbers with commas"""
	var str_number = str(number)
	var formatted = ""
	var count = 0
	
	for i in range(str_number.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = str_number[i] + formatted
		count += 1
	
	return formatted