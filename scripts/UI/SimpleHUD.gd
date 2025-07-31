extends Control
class_name SimpleHUD

# Simple HUD - Standalone version that doesn't require complex node structure
# Can be used immediately without scene setup

# UI Elements created dynamically
var credits_label: Label
var fuel_label: Label
var cargo_label: Label
var location_label: Label
var alert_container: HBoxContainer
var mini_map_placeholder: Panel

# Game Manager reference
var game_manager: GameManager

# Alert system
var active_alerts: Array[Dictionary] = []
var max_alerts: int = 3

# Performance tracking
var fps_label: Label
var frame_time_history: Array[float] = []

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
		
		# Add welcome alert
		add_alert("info", "Welcome to Space Transport Tycoon!", 4.0)
		add_alert("success", "Enhanced HUD loaded successfully", 3.0)
	else:
		print("SimpleHUD: GameManager not found")
		add_alert("error", "GameManager not found - some features may not work", 10.0)

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
	
	# Alert bar (below header)
	var alert_bar = Panel.new()
	alert_bar.anchors_preset = Control.PRESET_TOP_WIDE
	alert_bar.offset_top = 80
	alert_bar.offset_bottom = 110
	alert_bar.visible = false  # Only show when there are alerts
	alert_bar.name = "AlertBar"
	add_child(alert_bar)
	
	alert_container = HBoxContainer.new()
	alert_container.anchors_preset = Control.PRESET_FULL_RECT
	alert_container.offset_left = 10
	alert_container.offset_right = -10
	alert_container.offset_top = 5
	alert_container.offset_bottom = -5
	alert_bar.add_child(alert_container)
	
	# Mini-map placeholder (bottom right)
	mini_map_placeholder = Panel.new()
	mini_map_placeholder.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	mini_map_placeholder.offset_left = -200
	mini_map_placeholder.offset_top = -150
	mini_map_placeholder.offset_right = -10
	mini_map_placeholder.offset_bottom = -10
	mini_map_placeholder.name = "MiniMap"
	add_child(mini_map_placeholder)
	
	# Mini-map label
	var minimap_label = Label.new()
	minimap_label.text = "Mini-Map\n(Coming Soon)"
	minimap_label.anchors_preset = Control.PRESET_CENTER
	minimap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	minimap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mini_map_placeholder.add_child(minimap_label)
	
	# Performance display (bottom left)
	fps_label = Label.new()
	fps_label.anchors_preset = Control.PRESET_BOTTOM_LEFT
	fps_label.offset_left = 10
	fps_label.offset_top = -30
	fps_label.offset_right = 150
	fps_label.offset_bottom = -10
	fps_label.text = "FPS: --"
	fps_label.add_theme_font_size_override("font_size", 10)
	fps_label.modulate = Color(0.7, 0.7, 0.7)
	add_child(fps_label)

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

# This method is now defined at the end of the file with trend analysis

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
		var location_text = "Location: " + system_data.get("name", system_id)
		
		# Add risk level indicator
		var risk_level = system_data.get("risk_level", "safe")
		match risk_level:
			"high":
				location_text += " ⚠"
				location_label.modulate = Color.ORANGE
				add_alert("warning", "Entered high-risk system: " + system_data.get("name", system_id), 3.0)
			"dangerous":
				location_text += " ⚠⚠"
				location_label.modulate = Color.RED
				add_alert("error", "Entered dangerous system: " + system_data.get("name", system_id), 5.0)
			_:
				location_label.modulate = Color.WHITE
		
		location_label.text = location_text

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
	
	# Show/hide alert bar based on alerts
	var alert_bar = get_node("AlertBar")
	if alert_bar:
		alert_bar.visible = active_alerts.size() > 0
	
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
	alert_panel.custom_minimum_size = Vector2(200, 25)
	
	# Style based on alert type
	var style_box = StyleBoxFlat.new()
	match alert_data.type:
		"warning":
			style_box.bg_color = Color.ORANGE
		"error":
			style_box.bg_color = Color.RED
		"info":
			style_box.bg_color = Color.BLUE
		"success":
			style_box.bg_color = Color.GREEN
		_:
			style_box.bg_color = Color.GRAY
	
	style_box.bg_color.a = 0.8
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	alert_panel.add_theme_stylebox_override("panel", style_box)
	
	# Add alert text
	var alert_label = Label.new()
	alert_label.text = alert_data.message
	alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alert_label.add_theme_color_override("font_color", Color.WHITE)
	alert_label.add_theme_font_size_override("font_size", 11)
	alert_label.anchors_preset = Control.PRESET_FULL_RECT
	alert_label.offset_left = 5
	alert_label.offset_right = -5
	alert_label.offset_top = 2
	alert_label.offset_bottom = -2
	
	alert_panel.add_child(alert_label)
	
	return alert_panel

# Performance Monitoring
func _process(_delta):
	"""Update performance metrics"""
	_update_fps_display()

func _update_fps_display():
	"""Update FPS and performance display"""
	if not fps_label:
		return
	
	var fps = Engine.get_frames_per_second()
	var frame_time = 1000.0 / max(fps, 1)  # Convert to milliseconds
	
	# Track frame time history for smoothing
	frame_time_history.append(frame_time)
	if frame_time_history.size() > 10:
		frame_time_history.remove_at(0)
	
	# Calculate average frame time
	var avg_frame_time = 0.0
	for ft in frame_time_history:
		avg_frame_time += ft
	avg_frame_time /= frame_time_history.size()
	
	# Update display
	fps_label.text = "FPS: %d (%.1fms)" % [fps, avg_frame_time]
	
	# Color code based on performance
	if fps >= 55:
		fps_label.modulate = Color.GREEN
	elif fps >= 30:
		fps_label.modulate = Color.YELLOW
	else:
		fps_label.modulate = Color.RED

# Enhanced update methods with trend indicators
func _on_credits_changed(new_credits: int):
	"""Handle credits change with trend analysis"""
	if credits_label:
		var credits_text = "Credits: $" + _format_number(new_credits)
		
		# Add trend indicator
		var trend = _calculate_credits_trend(new_credits)
		if trend > 0:
			credits_text += " ↗"
			credits_label.modulate = Color.GREEN
		elif trend < 0:
			credits_text += " ↘"
			credits_label.modulate = Color.RED
		else:
			credits_label.modulate = Color.WHITE
		
		# Add artifact bonus indicator
		if game_manager and game_manager.has_method("get_active_artifact_bonuses"):
			var bonuses = game_manager.get_active_artifact_bonuses()
			if bonuses.get("trade_bonus", 0.0) > 0:
				credits_text += " ⚡"
		
		credits_label.text = credits_text

var credits_history: Array[int] = []
func _calculate_credits_trend(credits: int) -> int:
	"""Calculate credits trend for indicator"""
	credits_history.append(credits)
	if credits_history.size() > 5:
		credits_history.remove_at(0)
	
	if credits_history.size() < 3:
		return 0
	
	var recent = credits_history[-1]
	var older = credits_history[0]
	
	if recent > older * 1.05:
		return 1  # Rising
	elif recent < older * 0.95:
		return -1  # Falling
	else:
		return 0  # Stable