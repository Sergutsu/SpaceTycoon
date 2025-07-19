extends Control
class_name MainUI

# UI References
@onready var credits_label: Label = $Header/HBoxContainer/Stats/CreditsLabel
@onready var fuel_label: Label = $Header/HBoxContainer/Stats/FuelLabel
@onready var cargo_label: Label = $Header/HBoxContainer/Stats/CargoLabel
@onready var location_title: Label = $GameArea/Panels/LocationPanel/VBoxContainer/LocationTitle
@onready var location_description: Label = $GameArea/Panels/LocationPanel/VBoxContainer/LocationDescription
@onready var market_container: VBoxContainer = $GameArea/Panels/MarketPanel/VBoxContainer/MarketContainer
@onready var travel_container: VBoxContainer = $GameArea/Panels/TravelPanel/VBoxContainer/TravelContainer

# Game Manager reference
var game_manager: GameManager

func _ready():
	# Get game manager reference
	game_manager = get_node("../GameManager")
	
	# Connect to game manager signals
	game_manager.credits_changed.connect(_on_credits_changed)
	game_manager.fuel_changed.connect(_on_fuel_changed)
	game_manager.cargo_changed.connect(_on_cargo_changed)
	game_manager.location_changed.connect(_on_location_changed)
	
	# Initial UI update
	_update_location_display()
	_update_market_display()
	_update_travel_display()

func _on_credits_changed(new_credits: int):
	credits_label.text = "Credits: $" + str(new_credits)

func _on_fuel_changed(new_fuel: int):
	fuel_label.text = "Fuel: " + str(new_fuel)

func _on_cargo_changed(_cargo_dict: Dictionary):
	var total_cargo = game_manager.get_total_cargo()
	cargo_label.text = "Cargo: " + str(total_cargo) + "/" + str(game_manager.player_data.ship.cargo_capacity)
	_update_market_display()

func _on_location_changed(_planet_id: String):
	_update_location_display()
	_update_market_display()
	_update_travel_display()

func _update_location_display():
	var system = game_manager.get_current_system()
	location_title.text = "Current Location: " + system["name"]
	
	# Create description based on system type and features
	var description = system["type"].capitalize() + " system"
	if system.has("special_features") and system["special_features"].size() > 0:
		description += " with " + ", ".join(system["special_features"]).replace("_", " ")
	description += ". Risk level: " + system["risk_level"].capitalize() + "."
	
	location_description.text = description

func _update_market_display():
	# Clear existing market items
	for child in market_container.get_children():
		child.queue_free()
	
	var system = game_manager.get_current_system()
	var current_system_id = game_manager.player_data.current_system
	
	# Create market items for each good
	for good_type in system["goods"].keys():
		var price = game_manager.economy_system.calculate_dynamic_price(current_system_id, good_type)
		var player_has = game_manager.player_data.inventory.get(good_type, 0)
		
		var market_item = _create_market_item(good_type, price, player_has)
		market_container.add_child(market_item)

func _create_market_item(good_type: String, price: int, player_has: int) -> Control:
	var container = HBoxContainer.new()
	
	# Good info
	var info_container = VBoxContainer.new()
	var name_label = Label.new()
	name_label.text = good_type.capitalize()
	var price_label = Label.new()
	price_label.text = "Price: $" + str(price)
	var inventory_label = Label.new()
	inventory_label.text = "You have: " + str(player_has)
	
	info_container.add_child(name_label)
	info_container.add_child(price_label)
	info_container.add_child(inventory_label)
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Buttons
	var button_container = HBoxContainer.new()
	var buy_button = Button.new()
	buy_button.text = "Buy"
	buy_button.disabled = game_manager.player_data.credits < price or game_manager.get_total_cargo() >= game_manager.player_data.ship.cargo_capacity
	buy_button.pressed.connect(_on_buy_pressed.bind(good_type))
	
	var sell_button = Button.new()
	sell_button.text = "Sell"
	sell_button.disabled = player_has <= 0
	sell_button.pressed.connect(_on_sell_pressed.bind(good_type))
	
	button_container.add_child(buy_button)
	button_container.add_child(sell_button)
	
	container.add_child(info_container)
	container.add_child(button_container)
	
	return container

func _update_travel_display():
	# Clear existing travel options
	for child in travel_container.get_children():
		child.queue_free()
	
	# Add travel destinations
	var destinations = game_manager.get_available_destinations()
	for destination in destinations:
		var travel_item = _create_travel_item(destination)
		travel_container.add_child(travel_item)
	
	# Add refuel option if needed
	if game_manager.fuel < game_manager.max_fuel:
		var refuel_item = _create_refuel_item()
		travel_container.add_child(refuel_item)

func _create_travel_item(destination: Dictionary) -> Control:
	var container = HBoxContainer.new()
	
	# Destination info
	var info_container = VBoxContainer.new()
	var name_label = Label.new()
	name_label.text = destination["name"]
	var cost_label = Label.new()
	cost_label.text = "Fuel cost: " + str(destination["fuel_cost"])
	
	info_container.add_child(name_label)
	info_container.add_child(cost_label)
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Travel button
	var travel_button = Button.new()
	travel_button.text = "Travel"
	travel_button.disabled = game_manager.fuel < destination["fuel_cost"]
	travel_button.pressed.connect(_on_travel_pressed.bind(destination["id"]))
	
	container.add_child(info_container)
	container.add_child(travel_button)
	
	return container

func _create_refuel_item() -> Control:
	var container = HBoxContainer.new()
	
	# Calculate refuel cost
	var fuel_needed = game_manager.player_data.ship.fuel_capacity - game_manager.player_data.ship.current_fuel
	var refuel_cost = fuel_needed * 2
	
	# Refuel info
	var info_container = VBoxContainer.new()
	var name_label = Label.new()
	name_label.text = "Refuel"
	var cost_label = Label.new()
	cost_label.text = "Cost: $" + str(refuel_cost)
	
	info_container.add_child(name_label)
	info_container.add_child(cost_label)
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Refuel button
	var refuel_button = Button.new()
	refuel_button.text = "Refuel"
	refuel_button.disabled = game_manager.player_data.credits < refuel_cost or fuel_needed <= 0
	refuel_button.pressed.connect(_on_refuel_pressed)
	
	container.add_child(info_container)
	container.add_child(refuel_button)
	
	return container

func _on_buy_pressed(good_type: String):
	game_manager.buy_good(good_type, 1)

func _on_sell_pressed(good_type: String):
	game_manager.sell_good(good_type, 1)

func _on_travel_pressed(system_id: String):
	game_manager.travel_to_system(system_id)

func _on_refuel_pressed():
	game_manager.refuel_ship()
