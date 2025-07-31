extends BasePanel
class_name HUD

# HUD - Always visible status bar with real-time resource counters
# Based on views.md: "Real-time resource counters, mini-map, alerts"

# UI References - using get_node_or_null for safety
@onready var credits_label: Label = get_node_or_null("ResourceBar/CreditsLabel")
@onready var fuel_label: Label = get_node_or_null("ResourceBar/FuelLabel")
@onready var cargo_label: Label = get_node_or_null("ResourceBar/CargoLabel")
@onready var location_label: Label = get_node_or_null("ResourceBar/LocationLabel")
@onready var alert_container: HBoxContainer = get_node_or_null("AlertBar/AlertContainer")
@onready var mini_map: Control = get_node_or_null("MiniMap")

# Alert system
var active_alerts: Array[Dictionary] = []
var max_alerts: int = 3

func _on_panel_initialize():
	panel_title = "HUD"
	can_minimize = false
	can_close = false
	
	# Initialize with current game state
	if game_manager:
		_update_all_displays()

func _update_all_displays():
	"""Update all HUD displays with current game state"""
	if not game_manager:
		return
	
	update_credits(game_manager.player_data.credits)
	update_fuel(game_manager.player_data.ship.current_fuel)
	update_cargo(game_manager.player_data.inventory)
	update_location(game_manager.player_data.current_system)

func update_credits(credits: int):
	"""Update credits display with formatting and change indicators"""
	if not credits_label:
		return
	
	var credits_text = "Credits: $" + _format_number(credits)
	
	# Add artifact bonus indicator if applicable
	if game_manager and game_manager.has_method("get_active_artifact_bonuses"):
		var bonuses = game_manager.get_active_artifact_bonuses()
		if bonuses.get("trade_bonus", 0.0) > 0:
			credits_text += " ⚡"
	
	credits_label.text = credits_text

func update_fuel(fuel: int):
	"""Update fuel display with capacity and efficiency indicators"""
	if not fuel_label:
		return
	
	var max_fuel = game_manager.player_data.ship.fuel_capacity if game_manager else 100
	var fuel_text = "Fuel: " + str(fuel) + "/" + str(max_fuel)
	
	# Color code based on fuel level
	var fuel_percentage = float(fuel) / float(max_fuel)
	if fuel_percentage < 0.2:
		fuel_label.modulate = Color.RED
	elif fuel_percentage < 0.5:
		fuel_label.modulate = Color.YELLOW
	else:
		fuel_label.modulate = Color.WHITE
	
	# Add efficiency bonus indicator
	if game_manager and game_manager.has_method("get_active_artifact_bonuses"):
		var bonuses = game_manager.get_active_artifact_bonuses()
		if bonuses.get("fuel_efficiency_bonus", 0.0) > 0:
			fuel_text += " ⚡"
	
	fuel_label.text = fuel_text

func update_cargo(cargo: Dictionary):
	"""Update cargo display with capacity and contents"""
	if not cargo_label:
		return
	
	var total_cargo = 0
	for amount in cargo.values():
		total_cargo += amount
	
	var max_cargo = game_manager.player_data.ship.cargo_capacity if game_manager else 50
	var cargo_text = "Cargo: " + str(total_cargo) + "/" + str(max_cargo)
	
	# Color code based on cargo level
	var cargo_percentage = float(total_cargo) / float(max_cargo)
	if cargo_percentage > 0.9:
		cargo_label.modulate = Color.ORANGE
	elif cargo_percentage > 0.7:
		cargo_label.modulate = Color.YELLOW
	else:
		cargo_label.modulate = Color.WHITE
	
	# Add efficiency bonus indicator
	if game_manager and game_manager.has_method("get_active_artifact_bonuses"):
		var bonuses = game_manager.get_active_artifact_bonuses()
		if bonuses.get("global_efficiency", 0.0) > 0:
			cargo_text += " ⚡"
	
	cargo_label.text = cargo_text

func update_location(system_id: String):
	"""Update current location display"""
	if not location_label or not game_manager:
		return
	
	var system_data = game_manager.economy_system.get_system_data(system_id)
	var location_text = "Location: " + system_data.get("name", system_id)
	
	# Add risk level indicator
	var risk_level = system_data.get("risk_level", "safe")
	match risk_level:
		"high":
			location_text += " ⚠"
			location_label.modulate = Color.ORANGE
		"dangerous":
			location_text += " ⚠⚠"
			location_label.modulate = Color.RED
		_:
			location_label.modulate = Color.WHITE
	
	location_label.text = location_text

# Alert System
func add_alert(alert_type: String, message: String, duration: float = 5.0):
	"""Add an alert to the HUD"""
	var alert_data = {
		"type": alert_type,
		"message": message,
		"timestamp": Time.get_time_string_from_system(),
		"duration": duration
	}
	
	active_alerts.append(alert_data)
	
	# Remove oldest alert if we exceed max
	if active_alerts.size() > max_alerts:
		_remove_alert(0)
	
	_update_alert_display()
	
	# Auto-remove after duration
	if duration > 0:
		var timer = Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.timeout.connect(func(): _remove_alert_by_data(alert_data))
		add_child(timer)
		timer.start()

func _remove_alert(index: int):
	"""Remove alert by index"""
	if index >= 0 and index < active_alerts.size():
		active_alerts.remove_at(index)
		_update_alert_display()

func _remove_alert_by_data(alert_data: Dictionary):
	"""Remove specific alert"""
	var index = active_alerts.find(alert_data)
	if index >= 0:
		_remove_alert(index)

func _update_alert_display():
	"""Update the visual alert display"""
	if not alert_container:
		return
	
	# Clear existing alert widgets
	for child in alert_container.get_children():
		child.queue_free()
	
	# Create alert widgets
	for alert in active_alerts:
		var alert_widget = _create_alert_widget(alert)
		alert_container.add_child(alert_widget)

func _create_alert_widget(alert_data: Dictionary) -> Control:
	"""Create a visual widget for an alert"""
	var alert_panel = Panel.new()
	alert_panel.custom_minimum_size = Vector2(200, 30)
	
	# Style based on alert type
	var style_box = StyleBoxFlat.new()
	match alert_data.type:
		"warning":
			style_box.bg_color = Color.ORANGE
		"error":
			style_box.bg_color = Color.RED
		"info":
			style_box.bg_color = Color.BLUE
		_:
			style_box.bg_color = Color.GRAY
	
	style_box.bg_color.a = 0.8
	alert_panel.add_theme_stylebox_override("panel", style_box)
	
	# Add alert text
	var alert_label = Label.new()
	alert_label.text = alert_data.message
	alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alert_label.add_theme_color_override("font_color", Color.WHITE)
	alert_label.add_theme_font_size_override("font_size", 12)
	
	alert_panel.add_child(alert_label)
	
	return alert_panel

# Mini-map functionality (placeholder for now)
func update_mini_map():
	"""Update mini-map display"""
	# TODO: Implement mini-map showing nearby systems, trade routes, etc.
	pass

# Utility methods
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

# Game event handlers
func _on_credits_changed(new_credits: int):
	update_credits(new_credits)

func _on_fuel_changed(new_fuel: int):
	update_fuel(new_fuel)

func _on_cargo_changed(cargo_dict: Dictionary):
	update_cargo(cargo_dict)

func _on_location_changed(system_id: String):
	update_location(system_id)