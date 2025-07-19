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
@onready var artifact_panel: Panel = $GameArea/Panels/ArtifactPanel
@onready var artifact_container: VBoxContainer = $GameArea/Panels/ArtifactPanel/VBoxContainer/TabContainer/Artifacts/ArtifactContainer
@onready var lore_container: VBoxContainer = $GameArea/Panels/ArtifactPanel/VBoxContainer/TabContainer/Lore/LoreContainer
@onready var event_container: VBoxContainer = $GameArea/Panels/EventPanel/VBoxContainer/EventContainer
@onready var event_notification: AcceptDialog = $EventNotification
@onready var event_name_label: Label = $EventNotification/VBoxContainer/EventName
@onready var event_description_label: Label = $EventNotification/VBoxContainer/EventDescription
@onready var event_effects_label: Label = $EventNotification/VBoxContainer/EffectsText
@onready var event_duration_label: Label = $EventNotification/VBoxContainer/DurationText
@onready var event_systems_label: Label = $EventNotification/VBoxContainer/SystemsText
@onready var artifact_notification: AcceptDialog = $ArtifactNotification
@onready var artifact_name_label: Label = $ArtifactNotification/VBoxContainer/ArtifactName
@onready var artifact_description_label: Label = $ArtifactNotification/VBoxContainer/ArtifactDescription
@onready var lore_text_label: Label = $ArtifactNotification/VBoxContainer/LoreText
@onready var effects_text_label: Label = $ArtifactNotification/VBoxContainer/EffectsText

# Game Manager reference
var game_manager: GameManager

# Event display update timer
var event_update_timer: float = 0.0
var event_update_interval: float = 1.0  # Update every second

func _ready():
	# Get game manager reference
	game_manager = get_node("../GameManager")
	
	# Enable processing for event timer updates
	set_process(true)
	
	# Connect to game manager signals
	game_manager.credits_changed.connect(_on_credits_changed)
	game_manager.fuel_changed.connect(_on_fuel_changed)
	game_manager.cargo_changed.connect(_on_cargo_changed)
	game_manager.location_changed.connect(_on_location_changed)
	game_manager.ship_stats_updated.connect(_on_ship_stats_updated)
	
	# Connect artifact system signals
	game_manager.artifact_system.artifact_discovered.connect(_on_artifact_discovered)
	game_manager.artifact_system.artifact_collected.connect(_on_artifact_collected)
	game_manager.artifact_system.precursor_lore_unlocked.connect(_on_precursor_lore_unlocked)
	
	# Connect event system signals
	game_manager.event_system.event_triggered.connect(_on_event_triggered)
	game_manager.event_system.event_expired.connect(_on_event_expired)
	game_manager.event_system.event_effects_updated.connect(_on_event_effects_updated)
	
	# Initial UI update
	_update_location_display()
	_update_market_display()
	_update_travel_display()
	_update_upgrade_display()
	_update_artifact_display()
	_update_event_display()

func _process(delta):
	# Update event display timer
	event_update_timer += delta
	if event_update_timer >= event_update_interval:
		event_update_timer = 0.0
		_update_event_display()

func _on_credits_changed(new_credits: int):
	var credits_text = "Credits: $" + str(new_credits)
	
	# Add artifact bonus indicator if applicable
	var bonuses = game_manager.get_active_artifact_bonuses()
	if bonuses.get("trade_bonus", 0.0) > 0:
		credits_text += " ⚡"
	
	credits_label.text = credits_text

func _on_fuel_changed(new_fuel: int):
	var fuel_text = "Fuel: " + str(new_fuel)
	
	# Add artifact bonus indicator if applicable
	var bonuses = game_manager.get_active_artifact_bonuses()
	if bonuses.get("fuel_efficiency_bonus", 0.0) > 0:
		fuel_text += " ⚡"
	
	fuel_label.text = fuel_text

func _on_cargo_changed(_cargo_dict: Dictionary):
	var total_cargo = game_manager.get_total_cargo()
	var cargo_text = "Cargo: " + str(total_cargo) + "/" + str(game_manager.player_data.ship.cargo_capacity)
	
	# Add artifact bonus indicator if applicable
	var bonuses = game_manager.get_active_artifact_bonuses()
	if bonuses.get("global_efficiency", 0.0) > 0:
		cargo_text += " ⚡"
	
	cargo_label.text = cargo_text
	_update_market_display()

func _on_location_changed(_planet_id: String):
	_update_location_display()
	_update_market_display()
	_update_travel_display()
	_update_upgrade_display()

func _on_ship_stats_updated(_stats: Dictionary):
	_update_upgrade_display()
	_update_ship_stats_display()

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
	
	# Check for event effects on this good
	var current_system = game_manager.player_data.current_system
	var system_events = game_manager.event_system.get_system_events(current_system)
	var has_event_effect = false
	
	for event in system_events:
		if event["effects"].has("specific_goods"):
			var specific_goods = event["effects"]["specific_goods"]
			if specific_goods.has(good_type):
				has_event_effect = true
				break
		elif event["effects"].has("price_multiplier") or event["effects"].has("profit_multiplier"):
			has_event_effect = true
			break
	
	var price_label = Label.new()
	var price_text = "Price: $" + str(price)
	if has_event_effect:
		price_text += " ⚡"  # Event indicator
	price_label.text = price_text
	
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
	
	# Check for event effects on travel
	var fuel_modifier = game_manager.event_system.get_fuel_cost_modifier()
	var has_fuel_event = fuel_modifier != 1.0
	var cargo_risk = game_manager.event_system.get_cargo_loss_risk()
	var has_danger_event = cargo_risk > 0.0
	
	var cost_label = Label.new()
	var cost_text = "Fuel cost: " + str(destination["fuel_cost"])
	if has_fuel_event:
		cost_text += " ⚡"  # Event indicator
	if has_danger_event:
		cost_text += " ⚠"  # Danger indicator
	cost_label.text = cost_text
	
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

# Artifact system signal handlers
func _on_artifact_discovered(artifact_id: String, system_id: String, lore_fragment: String):
	# Show artifact discovery notification
	_show_artifact_discovery_notification(artifact_id, lore_fragment)

func _on_artifact_collected(artifact_id: String, effects: Dictionary):
	# Update artifact display
	_update_artifact_display()

func _on_precursor_lore_unlocked(civilization: String, lore_text: String):
	# Update lore display
	_update_artifact_display()

# Artifact UI functions
func _show_artifact_discovery_notification(artifact_id: String, lore_fragment: String):
	var artifact_data = game_manager.artifact_system._find_artifact_by_id(artifact_id)
	
	if artifact_data.is_empty():
		return
	
	# Set notification content
	artifact_name_label.text = artifact_data["name"]
	artifact_description_label.text = artifact_data["description"]
	lore_text_label.text = lore_fragment
	
	# Format effects text
	var effects_text = ""
	match artifact_data["effect_type"]:
		"travel_speed":
			effects_text = "Increases travel speed by " + str(int(artifact_data["magnitude"] * 100)) + "%"
		"fuel_efficiency":
			effects_text = "Reduces fuel consumption by " + str(int(artifact_data["magnitude"] * 100)) + "%"
		"market_bonus":
			effects_text = "Increases trade profits by " + str(int(artifact_data["magnitude"] * 100)) + "%"
		"global_efficiency":
			effects_text = "Improves all ship operations by " + str(int(artifact_data["magnitude"] * 100)) + "%"
		"new_routes":
			effects_text = "Reveals hidden hyperspace routes"
		"wormhole_access":
			effects_text = "Enables instant travel capabilities"
		_:
			effects_text = "Provides unknown benefits"
	
	effects_text_label.text = effects_text
	
	# Show notification
	artifact_notification.popup_centered()

func _update_artifact_display():
	# Clear existing artifact items
	for child in artifact_container.get_children():
		child.queue_free()
	
	# Clear existing lore items
	for child in lore_container.get_children():
		child.queue_free()
	
	# Update artifacts tab
	var collected_artifacts = game_manager.get_collected_artifacts()
	
	if collected_artifacts.is_empty():
		var no_artifacts_label = Label.new()
		no_artifacts_label.text = "No artifacts discovered yet.\nExplore systems with a scanner to find ancient relics!"
		no_artifacts_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		no_artifacts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		artifact_container.add_child(no_artifacts_label)
	else:
		for artifact in collected_artifacts:
			var artifact_item = _create_artifact_item(artifact)
			artifact_container.add_child(artifact_item)
	
	# Update lore tab
	var precursor_lore = game_manager.get_precursor_lore()
	
	for civ_id in precursor_lore.keys():
		var civ_data = precursor_lore[civ_id]
		var lore_item = _create_lore_item(civ_data)
		lore_container.add_child(lore_item)

func _create_artifact_item(artifact: Dictionary) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	
	# Artifact header
	var header_container = HBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = artifact["name"]
	name_label.add_theme_font_size_override("font_size", 14)
	
	var rarity_label = Label.new()
	rarity_label.text = "[" + artifact["rarity"].capitalize() + "]"
	rarity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rarity_label.add_theme_font_size_override("font_size", 12)
	
	# Color code rarity
	match artifact["rarity"]:
		"common":
			rarity_label.modulate = Color.WHITE
		"rare":
			rarity_label.modulate = Color.GOLD
		"legendary":
			rarity_label.modulate = Color.PURPLE
	
	header_container.add_child(name_label)
	header_container.add_child(rarity_label)
	
	# Description
	var description_label = Label.new()
	description_label.text = artifact["description"]
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 11)
	
	# Lore fragment
	var lore_label = Label.new()
	lore_label.text = "\"" + artifact["lore"] + "\""
	lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_label.add_theme_font_size_override("font_size", 10)
	lore_label.modulate = Color(0.8, 0.8, 1.0)
	
	# Effects
	var effects_label = Label.new()
	var effects_text = _format_artifact_effect(artifact["effect_type"], artifact["magnitude"])
	effects_label.text = "Effect: " + effects_text
	effects_label.add_theme_font_size_override("font_size", 11)
	effects_label.modulate = Color.GREEN
	
	# Add components
	container.add_child(header_container)
	container.add_child(description_label)
	container.add_child(lore_label)
	container.add_child(effects_label)
	
	# Add separator
	var separator = HSeparator.new()
	container.add_child(separator)
	
	return container

func _create_lore_item(civ_data: Dictionary) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	
	# Civilization header
	var header_container = HBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = civ_data["name"]
	name_label.add_theme_font_size_override("font_size", 14)
	
	var artifacts_count_label = Label.new()
	artifacts_count_label.text = "Artifacts Found: " + str(civ_data["artifacts_found"])
	artifacts_count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	artifacts_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	artifacts_count_label.add_theme_font_size_override("font_size", 11)
	
	header_container.add_child(name_label)
	header_container.add_child(artifacts_count_label)
	
	# Lore content
	var lore_label = Label.new()
	if civ_data["discovered"]:
		lore_label.text = civ_data["lore"]
		lore_label.modulate = Color.WHITE
	else:
		lore_label.text = "Discover artifacts from this civilization to unlock their lore..."
		lore_label.modulate = Color(0.6, 0.6, 0.6)
	
	lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_label.add_theme_font_size_override("font_size", 11)
	
	# Add components
	container.add_child(header_container)
	container.add_child(lore_label)
	
	# Add separator
	var separator = HSeparator.new()
	container.add_child(separator)
	
	return container

func _format_artifact_effect(effect_type: String, magnitude: float) -> String:
	match effect_type:
		"travel_speed":
			return "Travel speed +" + str(int(magnitude * 100)) + "%"
		"fuel_efficiency":
			return "Fuel efficiency +" + str(int(magnitude * 100)) + "%"
		"market_bonus":
			return "Trade profits +" + str(int(magnitude * 100)) + "%"
		"global_efficiency":
			return "All operations +" + str(int(magnitude * 100)) + "%"
		"new_routes":
			return "Reveals hidden routes"
		"wormhole_access":
			return "Instant travel capability"
		_:
			return "Unknown effect"

func _update_ship_stats_display():
	# This function updates visual indicators for artifact bonuses
	# The actual stat updates are handled by the signal handlers above
	pass

# Event system signal handlers
func _on_event_triggered(event_type: String, duration: float, effects: Dictionary):
	# Show event notification
	_show_event_notification(event_type, duration, effects)
	# Update event display
	_update_event_display()
	# Update other displays that might be affected by events
	_update_market_display()
	_update_travel_display()

func _on_event_expired(event_type: String):
	# Update event display
	_update_event_display()
	# Update other displays that might be affected by events
	_update_market_display()
	_update_travel_display()

func _on_event_effects_updated(active_effects: Dictionary):
	# Update displays that show event effects
	_update_event_display()

# Event UI functions
func _show_event_notification(event_type: String, duration: float, effects: Dictionary):
	var event_info = game_manager.event_system.get_event_display_info(event_type)
	
	if event_info.is_empty():
		return
	
	# Set notification content
	event_name_label.text = event_info["name"]
	event_description_label.text = event_info["description"]
	
	# Format effects text
	var effects_text = ""
	for effect_key in effects.keys():
		var effect_value = effects[effect_key]
		var effect_description = _format_event_effect(effect_key, effect_value)
		if effect_description != "":
			if effects_text != "":
				effects_text += "\n"
			effects_text += "• " + effect_description
	
	event_effects_label.text = effects_text
	
	# Format duration
	var duration_minutes = int(duration / 60)
	var duration_seconds = int(duration) % 60
	event_duration_label.text = str(duration_minutes) + "m " + str(duration_seconds) + "s"
	
	# Format affected systems
	var systems_text = ""
	var affected_systems = event_info["affected_systems"]
	if affected_systems.has("all"):
		systems_text = "All systems"
	else:
		for system_id in affected_systems:
			var system_data = game_manager.economy_system.get_system_data(system_id)
			if systems_text != "":
				systems_text += ", "
			systems_text += system_data["name"]
	
	event_systems_label.text = systems_text
	
	# Show notification
	event_notification.popup_centered()

func _update_event_display():
	# Clear existing event items
	for child in event_container.get_children():
		child.queue_free()
	
	var active_events = game_manager.event_system.get_active_events_display()
	
	if active_events.is_empty():
		var no_events_label = Label.new()
		no_events_label.text = "No active events.\nThe galaxy is peaceful for now..."
		no_events_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		no_events_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_events_label.modulate = Color(0.7, 0.7, 0.7)
		event_container.add_child(no_events_label)
	else:
		for event in active_events:
			var event_item = _create_event_item(event)
			event_container.add_child(event_item)

func _create_event_item(event: Dictionary) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	
	# Event header
	var header_container = HBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = event["name"]
	name_label.add_theme_font_size_override("font_size", 13)
	
	# Color code by severity
	match event["severity"]:
		"beneficial":
			name_label.modulate = Color.GREEN
		"harmful":
			name_label.modulate = Color.ORANGE_RED
		"dangerous":
			name_label.modulate = Color.RED
		"moderate":
			name_label.modulate = Color.YELLOW
		_:
			name_label.modulate = Color.WHITE
	
	var remaining_time = event["remaining_time"]
	var time_label = Label.new()
	var time_minutes = int(remaining_time / 60)
	var time_seconds = int(remaining_time) % 60
	time_label.text = str(time_minutes) + "m " + str(time_seconds) + "s"
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.add_theme_font_size_override("font_size", 11)
	time_label.modulate = Color(0.8, 0.8, 0.8)
	
	header_container.add_child(name_label)
	header_container.add_child(time_label)
	
	# Description
	var description_label = Label.new()
	description_label.text = event["description"]
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 10)
	description_label.modulate = Color(0.9, 0.9, 0.9)
	
	# Effects summary
	var effects_label = Label.new()
	var effects_text = ""
	for effect_key in event["effects"].keys():
		var effect_value = event["effects"][effect_key]
		var effect_description = _format_event_effect(effect_key, effect_value)
		if effect_description != "":
			if effects_text != "":
				effects_text += ", "
			effects_text += effect_description
	
	effects_label.text = "Effects: " + effects_text
	effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effects_label.add_theme_font_size_override("font_size", 10)
	effects_label.modulate = Color(0.7, 0.9, 1.0)
	
	# Affected systems
	var systems_label = Label.new()
	var systems_text = ""
	var affected_systems = event["affected_systems"]
	if affected_systems.has("all"):
		systems_text = "All systems"
	else:
		for system_id in affected_systems:
			var system_data = game_manager.economy_system.get_system_data(system_id)
			if systems_text != "":
				systems_text += ", "
			systems_text += system_data["name"]
	
	systems_label.text = "Systems: " + systems_text
	systems_label.add_theme_font_size_override("font_size", 10)
	systems_label.modulate = Color(0.8, 0.8, 0.8)
	
	# Add components
	container.add_child(header_container)
	container.add_child(description_label)
	container.add_child(effects_label)
	container.add_child(systems_label)
	
	# Add separator
	var separator = HSeparator.new()
	separator.modulate = Color(0.5, 0.5, 0.5)
	container.add_child(separator)
	
	return container

func _format_event_effect(effect_key: String, effect_value) -> String:
	match effect_key:
		"fuel_cost_multiplier":
			if effect_value > 1.0:
				return "Fuel costs +" + str(int((effect_value - 1.0) * 100)) + "%"
			else:
				return "Fuel costs -" + str(int((1.0 - effect_value) * 100)) + "%"
		"scanner_efficiency":
			if effect_value > 1.0:
				return "Scanner efficiency +" + str(int((effect_value - 1.0) * 100)) + "%"
			else:
				return "Scanner efficiency -" + str(int((1.0 - effect_value) * 100)) + "%"
		"profit_multiplier":
			if effect_value > 1.0:
				return "Trade profits +" + str(int((effect_value - 1.0) * 100)) + "%"
			else:
				return "Trade profits -" + str(int((1.0 - effect_value) * 100)) + "%"
		"price_multiplier":
			if effect_value > 1.0:
				return "Prices +" + str(int((effect_value - 1.0) * 100)) + "%"
			else:
				return "Prices -" + str(int((1.0 - effect_value) * 100)) + "%"
		"price_volatility":
			return "Price volatility +" + str(int((effect_value - 1.0) * 100)) + "%"
		"artifact_discovery_bonus":
			return "Artifact discovery +" + str(int(effect_value * 100)) + "%"
		"cargo_loss_risk":
			return "Cargo loss risk " + str(int(effect_value * 100)) + "%"
		"travel_danger":
			return "Travel danger +" + str(int((effect_value - 1.0) * 100)) + "%"
		"specific_goods":
			return "Affects " + ", ".join(effect_value)
		_:
			return ""
