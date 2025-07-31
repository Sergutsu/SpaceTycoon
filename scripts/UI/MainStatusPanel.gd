extends BasePanel
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

func _on_panel_initialize():
	panel_title = "Status Overview"
	can_minimize = true
	can_close = false
	
	# Initialize displays
	_setup_sections()
	_update_all_displays()

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
	
	# Net worth (if applicable)
	var networth_label = Label.new()
	networth_label.name = "NetWorth"
	networth_label.text = "Net Worth: $0"
	credits_section.add_child(networth_label)

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
	
	# Ship count
	var ship_count_label = Label.new()
	ship_count_label.name = "ShipCount"
	ship_count_label.text = "Active Ships: 1"
	fleet_section.add_child(ship_count_label)
	
	# Fleet capacity
	var capacity_label = Label.new()
	capacity_label.name = "FleetCapacity"
	capacity_label.text = "Total Cargo: 0/50"
	fleet_section.add_child(capacity_label)
	
	# Fleet efficiency
	var efficiency_label = Label.new()
	efficiency_label.name = "FleetEfficiency"
	efficiency_label.text = "Efficiency: 100%"
	fleet_section.add_child(efficiency_label)

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
	"""Calculate current ship value"""
	# TODO: Implement ship valuation based on upgrades
	return 10000  # Base ship value

func update_cargo(cargo: Dictionary):
	"""Update materials/inventory display"""
	if not materials_section:
		return
	
	# Clear existing inventory items (keep title)
	var children = materials_section.get_children()
	for i in range(1, children.size()):  # Skip title
		children[i].queue_free()
	
	# Add current inventory
	for good_type in cargo.keys():
		var quantity = cargo[good_type]
		if quantity > 0:
			var item_label = Label.new()
			item_label.text = good_type.capitalize() + ": " + str(quantity)
			materials_section.add_child(item_label)
	
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
	
	# Update ship count (currently always 1)
	var ship_count_label = fleet_section.get_node_or_null("ShipCount") as Label
	if ship_count_label:
		ship_count_label.text = "Active Ships: 1"
	
	# Update fleet capacity
	var capacity_label = fleet_section.get_node_or_null("FleetCapacity") as Label
	if capacity_label:
		var total_cargo = _get_total_cargo(game_manager.player_data.inventory)
		var max_cargo = game_manager.player_data.ship.cargo_capacity
		capacity_label.text = "Total Cargo: " + str(total_cargo) + "/" + str(max_cargo)
	
	# Update efficiency
	var efficiency_label = fleet_section.get_node_or_null("FleetEfficiency") as Label
	if efficiency_label:
		var efficiency = 100
		# TODO: Calculate actual efficiency based on ship condition, upgrades, etc.
		efficiency_label.text = "Efficiency: " + str(efficiency) + "%"

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
		["Total Profit", "$" + _format_number(stats.total_profit)]
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