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
@onready var upgrade_panel: Panel = $GameArea/Panels/UpgradePanel
@onready var upgrade_container: VBoxContainer = $GameArea/Panels/UpgradePanel/VBoxContainer/ScrollContainer/UpgradeContainer

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
	game_manager.ship_stats_updated.connect(_on_ship_stats_updated)
	
	# Initial UI update
	_update_location_display()
	_update_market_display()
	_update_travel_display()
	_update_upgrade_display()

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
	_update_upgrade_display()

func _on_ship_stats_updated(_stats: Dictionary):
	_update_upgrade_display()

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

func _update_upgrade_display():
	# Show upgrade panel only at Nexus Station
	var current_system = game_manager.player_data.current_system
	upgrade_panel.visible = (current_system == "nexus_station")
	
	if not upgrade_panel.visible:
		return
	
	# Clear existing upgrade items
	for child in upgrade_container.get_children():
		child.queue_free()
	
	# Create upgrade items for each category
	var upgrade_types = game_manager.ship_system.get_all_upgrade_types()
	for upgrade_type in upgrade_types:
		var current_level = game_manager.player_data.ship.upgrades[upgrade_type]
		var upgrade_info = game_manager.ship_system.get_upgrade_info(upgrade_type, current_level)
		
		var upgrade_item = _create_upgrade_item(upgrade_type, upgrade_info)
		upgrade_container.add_child(upgrade_item)

func _create_upgrade_item(upgrade_type: String, upgrade_info: Dictionary) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	
	# Header with upgrade name and level
	var header_container = HBoxContainer.new()
	var name_label = Label.new()
	name_label.text = upgrade_info["name"]
	name_label.add_theme_font_size_override("font_size", 16)
	
	var level_label = Label.new()
	level_label.text = "Level " + str(upgrade_info["current_level"]) + "/" + str(upgrade_info["max_level"])
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	header_container.add_child(name_label)
	header_container.add_child(level_label)
	
	# Description
	var description_label = Label.new()
	description_label.text = upgrade_info["description"]
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 12)
	
	# Current effects display
	var effects_container = VBoxContainer.new()
	var current_effects = upgrade_info.get("current_effects", {})
	
	if not current_effects.is_empty():
		var current_effects_label = Label.new()
		current_effects_label.text = "Current Effects:"
		current_effects_label.add_theme_font_size_override("font_size", 12)
		effects_container.add_child(current_effects_label)
		
		for effect_key in current_effects.keys():
			var effect_label = Label.new()
			effect_label.text = "  • " + _format_effect_text(effect_key, current_effects[effect_key])
			effect_label.add_theme_font_size_override("font_size", 11)
			effects_container.add_child(effect_label)
	
	# Upgrade button and next level info
	var upgrade_section = HBoxContainer.new()
	
	if upgrade_info["can_upgrade"]:
		var next_info_container = VBoxContainer.new()
		next_info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var next_level_label = Label.new()
		next_level_label.text = "Next Level Effects:"
		next_level_label.add_theme_font_size_override("font_size", 12)
		next_info_container.add_child(next_level_label)
		
		var next_effects = upgrade_info.get("next_effects", {})
		for effect_key in next_effects.keys():
			var effect_label = Label.new()
			effect_label.text = "  • " + _format_effect_text(effect_key, next_effects[effect_key])
			effect_label.add_theme_font_size_override("font_size", 11)
			effect_label.modulate = Color.GREEN
			next_info_container.add_child(effect_label)
		
		var cost_label = Label.new()
		cost_label.text = "Cost: $" + str(upgrade_info["next_cost"])
		cost_label.add_theme_font_size_override("font_size", 12)
		next_info_container.add_child(cost_label)
		
		upgrade_section.add_child(next_info_container)
		
		# Upgrade button
		var button_container = VBoxContainer.new()
		var upgrade_button = Button.new()
		upgrade_button.text = "Upgrade"
		upgrade_button.custom_minimum_size = Vector2(100, 40)
		
		# Check affordability
		var can_afford = game_manager.ship_system.can_afford_upgrade(
			upgrade_type, 
			upgrade_info["current_level"], 
			game_manager.player_data.credits
		)
		
		upgrade_button.disabled = not can_afford
		if not can_afford:
			upgrade_button.tooltip_text = "Insufficient credits"
		
		upgrade_button.pressed.connect(_on_upgrade_pressed.bind(upgrade_type))
		
		button_container.add_child(upgrade_button)
		upgrade_section.add_child(button_container)
	else:
		var max_level_label = Label.new()
		max_level_label.text = "Maximum level reached"
		max_level_label.add_theme_font_size_override("font_size", 12)
		max_level_label.modulate = Color.GOLD
		upgrade_section.add_child(max_level_label)
	
	# Add all components to container
	container.add_child(header_container)
	container.add_child(description_label)
	container.add_child(effects_container)
	container.add_child(upgrade_section)
	
	# Add separator
	var separator = HSeparator.new()
	container.add_child(separator)
	
	return container

func _format_effect_text(effect_key: String, value) -> String:
	match effect_key:
		"cargo_capacity":
			return "Cargo Capacity: " + str(value)
		"fuel_efficiency":
			return "Fuel Efficiency: " + str(int((1.0 - value) * 100)) + "% reduction"
		"speed_multiplier":
			return "Travel Speed: " + str(int((value - 1.0) * 100)) + "% faster"
		"detection_range":
			return "Scanner Range: " + str(value)
		"detection_chance":
			return "Discovery Chance: " + str(int(value * 100)) + "%"
		"automation_level":
			return "Automation Level: " + str(value)
		"efficiency_bonus":
			return "Automation Efficiency: " + str(int(value * 100)) + "%"
		_:
			return effect_key.capitalize() + ": " + str(value)

func _on_upgrade_pressed(upgrade_type: String):
	var result = game_manager.purchase_ship_upgrade(upgrade_type)
	
	if result["success"]:
		# The GameManager will handle the upgrade through signal connections
		# UI will update automatically through the ship_stats_updated signal
		pass
	else:
		# Could show error message to player
		print("Upgrade failed: " + result["error"])
