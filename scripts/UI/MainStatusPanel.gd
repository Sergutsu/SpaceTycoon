extends Control
class_name MainStatusPanel

# Main Status Panel - Detailed overview of credits, energy, materials, fleet strength
# Based on views.md: "Overview: credits, energy, materials, fleet strength"

# UI References - using get_node_or_null for safety
@onready var credits_section: VBoxContainer = get_node_or_null("ContentArea/ScrollContainer/VBoxContainer/CreditsSection")
@onready var fleet_section: VBoxContainer = get_node_or_null("ContentArea/ScrollContainer/VBoxContainer/FleetSection")
@onready var materials_section: VBoxContainer = get_node_or_null("ContentArea/ScrollContainer/VBoxContainer/MaterialsSection")
@onready var statistics_section: VBoxContainer = get_node_or_null("ContentArea/ScrollContainer/VBoxContainer/StatisticsSection")

# Data tracking
var last_credits: int = 0
var credits_history: Array[int] = []
var max_history_length: int = 10

# Panel properties
var panel_title: String = "Status Overview"
var can_minimize: bool = true
var can_close: bool = false
var game_manager: GameManager

func initialize(gm: GameManager):
	"""Initialize panel with game manager reference"""
	game_manager = gm
	
	# Initialize displays
	_setup_sections()
	_update_all_displays()
	
	print("MainStatusPanel: Initialized with GameManager")

func _setup_sections():
	"""Set up all status sections"""
	_setup_credits_section()
	_setup_fleet_section()
	_setup_materials_section()
	_setup_statistics_section()

func _setup_credits_section():
	"""Set up the credits overview section"""
	if not credits_section:
		return
	
	# Clear existing content
	for child in credits_section.get_children():
		child.queue_free()
	
	# Section title
	var title_label = Label.new()
	title_label.text = "Financial Status"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color.CYAN)
	credits_section.add_child(title_label)
	
	# Current credits
	var credits_label = Label.new()
	credits_label.name = "CurrentCredits"
	credits_label.text = "Credits: $0"
	credits_section.add_child(credits_label)
	
	# Credits trend
	var trend_label = Label.new()
	trend_label.name = "CreditsTrend"
	trend_label.text = "Trend: --"
	credits_section.add_child(trend_label)
	
	# Net worth
	var networth_label = Label.new()
	networth_label.name = "NetWorth"
	networth_label.text = "Net Worth: $0"
	credits_section.add_child(networth_label)
	
	# Profit per hour (if available)
	var profit_rate_label = Label.new()
	profit_rate_label.name = "ProfitRate"
	profit_rate_label.text = "Profit Rate: $0/hr"
	credits_section.add_child(profit_rate_label)
	
	# Automation income
	var automation_label = Label.new()
	automation_label.name = "AutomationIncome"
	automation_label.text = "Automation: $0"
	credits_section.add_child(automation_label)

func _setup_fleet_section():
	"""Set up the fleet status section"""
	if not fleet_section:
		return
	
	# Clear existing content
	for child in fleet_section.get_children():
		child.queue_free()
	
	# Section title
	var title_label = Label.new()
	title_label.text = "Fleet Status"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color.GREEN)
	fleet_section.add_child(title_label)
	
	# Ship name and status
	var ship_name_label = Label.new()
	ship_name_label.name = "ShipName"
	ship_name_label.text = "Ship: Stellar Hauler"
	fleet_section.add_child(ship_name_label)
	
	# Fleet capacity
	var capacity_label = Label.new()
	capacity_label.name = "FleetCapacity"
	capacity_label.text = "Cargo: 0/50"
	fleet_section.add_child(capacity_label)
	
	# Fuel status
	var fuel_status_label = Label.new()
	fuel_status_label.name = "FuelStatus"
	fuel_status_label.text = "Fuel: 100/100"
	fleet_section.add_child(fuel_status_label)
	
	# Fleet efficiency
	var efficiency_label = Label.new()
	efficiency_label.name = "FleetEfficiency"
	efficiency_label.text = "Efficiency: 100%"
	fleet_section.add_child(efficiency_label)
	
	# Upgrade levels
	var upgrades_label = Label.new()
	upgrades_label.name = "UpgradeLevels"
	upgrades_label.text = "Upgrades: Cargo(0) Engine(0) Scanner(0) AI(0)"
	fleet_section.add_child(upgrades_label)

func _setup_materials_section():
	"""Set up the materials/inventory section"""
	if not materials_section:
		return
	
	# Clear existing content
	for child in materials_section.get_children():
		child.queue_free()
	
	# Section title
	var title_label = Label.new()
	title_label.text = "Inventory"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color.ORANGE)
	materials_section.add_child(title_label)
	
	# Inventory will be populated dynamically

func _setup_statistics_section():
	"""Set up the statistics section"""
	if not statistics_section:
		return
	
	# Clear existing content
	for child in statistics_section.get_children():
		child.queue_free()
	
	# Section title
	var title_label = Label.new()
	title_label.text = "Statistics"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color.PURPLE)
	statistics_section.add_child(title_label)
	
	# Statistics will be populated from game data

func _update_all_displays():
	"""Update all status displays"""
	if not game_manager:
		return
	
	update_credits(game_manager.player_data.credits)
	update_cargo(game_manager.player_data.inventory)
	_update_fleet_status()
	_update_statistics()

func update_credits(credits: int):
	"""Update credits display with trend analysis"""
	var credits_label = credits_section.get_node_or_null("CurrentCredits") as Label
	if credits_label:
		credits_label.text = "Credits: $" + _format_number(credits)
	
	# Update trend
	_update_credits_trend(credits)
	
	# Update net worth calculation
	_update_net_worth(credits)

func _update_credits_trend(credits: int):
	"""Update credits trend analysis"""
	var trend_label = credits_section.get_node_or_null("CreditsTrend") as Label
	if not trend_label:
		return
	
	# Add to history
	credits_history.append(credits)
	if credits_history.size() > max_history_length:
		credits_history.remove_at(0)
	
	# Calculate trend
	if credits_history.size() < 2:
		trend_label.text = "Trend: --"
		return
	
	var recent_avg = 0
	var older_avg = 0
	var half_point = credits_history.size() / 2
	
	# Calculate recent average
	for i in range(half_point, credits_history.size()):
		recent_avg += credits_history[i]
	recent_avg /= (credits_history.size() - half_point)
	
	# Calculate older average
	for i in range(0, half_point):
		older_avg += credits_history[i]
	older_avg /= half_point
	
	# Determine trend
	var trend_text = "Trend: "
	if recent_avg > older_avg * 1.1:
		trend_text += "↗ Rising"
		trend_label.modulate = Color.GREEN
	elif recent_avg < older_avg * 0.9:
		trend_text += "↘ Falling"
		trend_label.modulate = Color.RED
	else:
		trend_text += "→ Stable"
		trend_label.modulate = Color.YELLOW
	
	trend_label.text = trend_text

func _update_net_worth(credits: int):
	"""Update net worth calculation"""
	var networth_label = credits_section.get_node_or_null("NetWorth") as Label
	if not networth_label:
		return
	
	# Calculate net worth (credits + cargo value + ship value)
	var cargo_value = _calculate_cargo_value()
	var ship_value = _calculate_ship_value()
	var net_worth = credits + cargo_value + ship_value
	
	networth_label.text = "Net Worth: $" + _format_number(net_worth)
	
	# Update profit rate
	var profit_rate_label = credits_section.get_node_or_null("ProfitRate") as Label
	if profit_rate_label:
		var playtime_hours = game_manager.player_data.statistics.playtime_seconds / 3600.0
		if playtime_hours > 0:
			var profit_per_hour = game_manager.player_data.statistics.total_credits_earned / playtime_hours
			profit_rate_label.text = "Profit Rate: $" + _format_number(int(profit_per_hour)) + "/hr"
		else:
			profit_rate_label.text = "Profit Rate: --"
	
	# Update automation income
	var automation_label = credits_section.get_node_or_null("AutomationIncome") as Label
	if automation_label:
		var automation_income = game_manager.player_data.automation_profits
		automation_label.text = "Automation: $" + _format_number(automation_income)

func _calculate_cargo_value() -> int:
	"""Calculate current cargo value"""
	if not game_manager:
		return 0
	
	var total_value = 0
	var current_system = game_manager.player_data.current_system
	
	for good_type in game_manager.player_data.inventory.keys():
		var quantity = game_manager.player_data.inventory[good_type]
		var price = game_manager.economy_system.calculate_dynamic_price(current_system, good_type)
		total_value += quantity * price
	
	return total_value

func _calculate_ship_value() -> int:
	"""Calculate current ship value based on upgrades"""
	if not game_manager:
		return 10000
	
	var base_value = 10000
	var upgrade_value = 0
	
	# Calculate upgrade values (rough estimates)
	var upgrades = game_manager.player_data.ship.upgrades
	upgrade_value += upgrades.cargo_hold * 2000  # Each cargo upgrade worth 2k
	upgrade_value += upgrades.engine * 3000      # Each engine upgrade worth 3k
	upgrade_value += upgrades.scanner * 1500     # Each scanner upgrade worth 1.5k
	upgrade_value += upgrades.ai_core * 5000     # Each AI upgrade worth 5k
	
	return base_value + upgrade_value

func update_cargo(cargo: Dictionary):
	"""Update materials/inventory display with values"""
	if not materials_section:
		return
	
	# Clear existing inventory items (keep title)
	var children = materials_section.get_children()
	for i in range(1, children.size()):  # Skip title
		children[i].queue_free()
	
	var total_cargo_value = 0
	
	# Add current inventory with values
	for good_type in cargo.keys():
		var quantity = cargo[good_type]
		if quantity > 0:
			var item_container = HBoxContainer.new()
			materials_section.add_child(item_container)
			
			# Item name and quantity
			var item_label = Label.new()
			item_label.text = good_type.capitalize() + ": " + str(quantity)
			item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item_container.add_child(item_label)
			
			# Item value
			if game_manager:
				var current_system = game_manager.player_data.current_system
				var price = game_manager.economy_system.calculate_dynamic_price(current_system, good_type)
				var item_value = quantity * price
				total_cargo_value += item_value
				
				var value_label = Label.new()
				value_label.text = "$" + _format_number(item_value)
				value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				value_label.modulate = Color.YELLOW
				item_container.add_child(value_label)
	
	# Add total cargo value
	if total_cargo_value > 0:
		var separator = HSeparator.new()
		materials_section.add_child(separator)
		
		var total_container = HBoxContainer.new()
		materials_section.add_child(total_container)
		
		var total_label = Label.new()
		total_label.text = "Total Value:"
		total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		total_label.add_theme_color_override("font_color", Color.CYAN)
		total_container.add_child(total_label)
		
		var total_value_label = Label.new()
		total_value_label.text = "$" + _format_number(total_cargo_value)
		total_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		total_value_label.add_theme_color_override("font_color", Color.CYAN)
		total_container.add_child(total_value_label)
	
	# Add empty message if no cargo
	if cargo.is_empty() or _get_total_cargo(cargo) == 0:
		var empty_label = Label.new()
		empty_label.text = "No cargo"
		empty_label.modulate = Color.GRAY
		materials_section.add_child(empty_label)

func _update_fleet_status():
	"""Update fleet status information"""
	if not game_manager:
		return
	
	# Update ship name
	var ship_name_label = fleet_section.get_node_or_null("ShipName") as Label
	if ship_name_label:
		ship_name_label.text = "Ship: " + game_manager.player_data.ship.name
	
	# Update fleet capacity
	var capacity_label = fleet_section.get_node_or_null("FleetCapacity") as Label
	if capacity_label:
		var total_cargo = _get_total_cargo(game_manager.player_data.inventory)
		var max_cargo = game_manager.player_data.ship.cargo_capacity
		capacity_label.text = "Cargo: " + str(total_cargo) + "/" + str(max_cargo)
		
		# Color code based on capacity
		var capacity_percentage = float(total_cargo) / float(max_cargo)
		if capacity_percentage > 0.9:
			capacity_label.modulate = Color.RED
		elif capacity_percentage > 0.7:
			capacity_label.modulate = Color.ORANGE
		else:
			capacity_label.modulate = Color.WHITE
	
	# Update fuel status
	var fuel_status_label = fleet_section.get_node_or_null("FuelStatus") as Label
	if fuel_status_label:
		var current_fuel = game_manager.player_data.ship.current_fuel
		var max_fuel = game_manager.player_data.ship.fuel_capacity
		fuel_status_label.text = "Fuel: " + str(current_fuel) + "/" + str(max_fuel)
		
		# Color code based on fuel level
		var fuel_percentage = float(current_fuel) / float(max_fuel)
		if fuel_percentage < 0.2:
			fuel_status_label.modulate = Color.RED
		elif fuel_percentage < 0.5:
			fuel_status_label.modulate = Color.YELLOW
		else:
			fuel_status_label.modulate = Color.WHITE
	
	# Update efficiency (based on fuel and cargo levels)
	var efficiency_label = fleet_section.get_node_or_null("FleetEfficiency") as Label
	if efficiency_label:
		var fuel_efficiency = game_manager.player_data.ship.bonuses.fuel_efficiency
		var efficiency = int(fuel_efficiency * 100)
		efficiency_label.text = "Fuel Efficiency: " + str(efficiency) + "%"
	
	# Update upgrade levels
	var upgrades_label = fleet_section.get_node_or_null("UpgradeLevels") as Label
	if upgrades_label:
		var upgrades = game_manager.player_data.ship.upgrades
		upgrades_label.text = "Upgrades: Cargo(%d) Engine(%d) Scanner(%d) AI(%d)" % [
			upgrades.cargo_hold,
			upgrades.engine,
			upgrades.scanner,
			upgrades.ai_core
		]

func _update_statistics():
	"""Update game statistics"""
	if not game_manager or not statistics_section:
		return
	
	# Clear existing stats (keep title)
	var children = statistics_section.get_children()
	for i in range(1, children.size()):  # Skip title
		children[i].queue_free()
	
	# Add statistics from game data
	var stats = game_manager.player_data.statistics
	
	var stats_to_show = [
		["Systems Explored", str(stats.systems_explored)],
		["Distance Traveled", str(stats.distance_traveled) + " units"],
		["Trades Completed", str(stats.trades_completed)],
		["Total Earned", "$" + _format_number(stats.total_credits_earned)],
		["Artifacts Found", str(stats.artifacts_found)],
		["Playtime", _format_playtime(stats.playtime_seconds)]
	]
	
	for stat_pair in stats_to_show:
		var stat_label = Label.new()
		stat_label.text = stat_pair[0] + ": " + stat_pair[1]
		statistics_section.add_child(stat_label)

# Utility methods
func _get_total_cargo(cargo: Dictionary) -> int:
	"""Calculate total cargo quantity"""
	var total = 0
	for amount in cargo.values():
		total += amount
	return total

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

func _format_playtime(seconds: int) -> String:
	"""Format playtime in hours and minutes"""
	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	
	if hours > 0:
		return "%dh %dm" % [hours, minutes]
	else:
		return "%dm" % minutes
