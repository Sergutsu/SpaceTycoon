extends Control
class_name SimpleMainUI

# UI References - only header elements
@onready var credits_label: Label = $Header/HBoxContainer/Stats/CreditsLabel
@onready var fuel_label: Label = $Header/HBoxContainer/Stats/FuelLabel
@onready var cargo_label: Label = $Header/HBoxContainer/Stats/CargoLabel

# Game Manager reference
var game_manager: GameManager

func _ready():
	print("SimpleMainUI: Starting initialization...")
	
	# Get game manager reference
	game_manager = get_node("../GameManager")
	
	if game_manager:
		# Connect to game manager signals
		game_manager.credits_changed.connect(_on_credits_changed)
		game_manager.fuel_changed.connect(_on_fuel_changed)
		game_manager.cargo_changed.connect(_on_cargo_changed)
		
		print("SimpleMainUI: Connected to GameManager signals")
		
		# Initial UI update
		_update_display()
	else:
		print("SimpleMainUI: GameManager not found!")
	
	# Add debug info
	_create_debug_overlay()

func _update_display():
	"""Update all UI elements"""
	if not game_manager:
		return
	
	credits_label.text = "Credits: $" + str(game_manager.player_data.credits)
	fuel_label.text = "Fuel: " + str(game_manager.player_data.ship.current_fuel)
	
	var total_cargo = 0
	for amount in game_manager.player_data.inventory.values():
		total_cargo += amount
	
	cargo_label.text = "Cargo: " + str(total_cargo) + "/" + str(game_manager.player_data.ship.cargo_capacity)

func _on_credits_changed(new_credits: int):
	credits_label.text = "Credits: $" + str(new_credits)

func _on_fuel_changed(new_fuel: int):
	fuel_label.text = "Fuel: " + str(new_fuel)

func _on_cargo_changed(_cargo_dict: Dictionary):
	var total_cargo = 0
	for amount in _cargo_dict.values():
		total_cargo += amount
	
	cargo_label.text = "Cargo: " + str(total_cargo) + "/" + str(game_manager.player_data.ship.cargo_capacity)

func _create_debug_overlay():
	# Create debug label in bottom left
	var debug_label = Label.new()
	debug_label.name = "DebugLabel"
	debug_label.text = "Debug Info:\nRight-click in 3D view to raycast\nLeft-drag to orbit, wheel to zoom"
	debug_label.position = Vector2(10, 400)
	debug_label.size = Vector2(300, 100)
	debug_label.add_theme_color_override("font_color", Color.YELLOW)
	debug_label.add_theme_font_size_override("font_size", 12)
	
	add_child(debug_label)
	
	print("SimpleMainUI: Debug overlay created")
