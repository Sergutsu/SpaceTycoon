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
	game_manager = get_node("../GameManager")
	if game_manager:
		_connect_signals()
		_update_all_displays()
		print("SimpleHUD: Connected to GameManager")
		
		# Add welcome alert
		add_alert("info", "Welcome to Space Transport Tycoon!", 4.0)
		add_alert("success", "Enhanced HUD loaded successfully", 3.0)
		
		# Initialize MainStatusPanel if it exists
		var status_panel = get_node("../MainStatusPanel")
		if status_panel and status_panel.has_method("initialize"):
			status_panel.initialize(game_manager)
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
	fps_label.offset_top = -50
	fps_label.offset_right = 150
	fps_label.offset_bottom = -30
	fps_label.text = "FPS: --"
	fps_label.add_theme_font_size_override("font_size", 10)
	fps_label.modulate = Color(0.7, 0.7, 0.7)
	add_child(fps_label)
	
	# Resource trend indicators (bottom left, above FPS)
	var trend_panel = Panel.new()
	trend_panel.anchors_preset = Control.PRESET_BOTTOM_LEFT
	trend_panel.offset_left = 10
	trend_panel.offset_top = -120
	trend_panel.offset_right = 200
	trend_panel.offset_bottom = -55
	trend_panel.name = "TrendPanel"
	add_child(trend_panel)
	
	var trend_container = VBoxContainer.new()
	trend_container.anchors_preset = Control.PRESET_FULL_RECT
	trend_container.offset_left = 5
	trend_container.offset_right = -5
	trend_container.offset_top = 5
	trend_container.offset_bottom = -5
	trend_panel.add_child(trend_container)
	
	var trend_title = Label.new()
	trend_title.text = "Market Trends"
	trend_title.add_theme_font_size_override("font_size", 10)
	trend_title.add_theme_color_override("font_color", Color.CYAN)
	trend_container.add_child(trend_title)
	
	# Artifact bonus indicators (top right, below stats)
	var artifact_panel = Panel.new()
	artifact_panel.anchors_preset = Control.PRESET_TOP_RIGHT
	artifact_panel.offset_left = -220
	artifact_panel.offset_top = 85
	artifact_panel.offset_right = -10
	artifact_panel.offset_bottom = 140
	artifact_panel.name = "ArtifactPanel"
	artifact_panel.visible = false  # Only show when artifacts are active
	add_child(artifact_panel)
	
	var artifact_container = HBoxContainer.new()
	artifact_container.anchors_preset = Control.PRESET_FULL_RECT
	artifact_container.offset_left = 5
	artifact_container.offset_right = -5
	artifact_container.offset_top = 5
	artifact_container.offset_bottom = -5
	artifact_panel.add_child(artifact_container)
	
	var artifact_title = Label.new()
	artifact_title.text = "Active Bonuses: "
	artifact_title.add_theme_font_size_override("font_size", 10)
	artifact_title.add_theme_color_override("font_color", Color.GOLD)
	artifact_container.add_child(artifact_title)

func _connect_signals():
	"""Connect to GameManager signals"""
	if game_manager:
		game_manager.credits_changed.connect(_on_credits_changed)
		game_manager.fuel_changed.connect(_on_fuel_changed)
		game_manager.cargo_changed.connect(_on_cargo_changed)
		game_manager.location_changed.connect(_on_location_changed)
		game_manager.travel_started.connect(_on_travel_started)
		game_manager.ship_stats_updated.connect(_on_ship_stats_updated)
		
		# Connect to system signals if available
		if game_manager.economy_system:
			game_manager.economy_system.trade_executed.connect(_on_trade_executed)
		if game_manager.artifact_system:
			game_manager.artifact_system.artifact_discovered.connect(_on_artifact_discovered)
		if game_manager.event_system:
			game_manager.event_system.event_triggered.connect(_on_event_triggered)

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
	alert_panel.custom_minimum_size = Vector2(250, 30)
	
	# Style based on alert type with enhanced visuals
	var style_box = StyleBoxFlat.new()
	var icon_text = ""
	
	match alert_data.type:
		"warning":
			style_box.bg_color = Color(1.0, 0.6, 0.0, 0.9)  # Orange
			icon_text = "⚠ "
		"error":
			style_box.bg_color = Color(0.8, 0.2, 0.2, 0.9)  # Red
			icon_text = "❌ "
		"info":
			style_box.bg_color = Color(0.2, 0.6, 1.0, 0.9)  # Blue
			icon_text = "ℹ "
		"success":
			style_box.bg_color = Color(0.2, 0.8, 0.2, 0.9)  # Green
			icon_text = "✓ "
		"trade":
			style_box.bg_color = Color(0.8, 0.6, 0.2, 0.9)  # Gold
			icon_text = "💰 "
		"travel":
			style_box.bg_color = Color(0.4, 0.2, 0.8, 0.9)  # Purple
			icon_text = "🚀 "
		"discovery":
			style_box.bg_color = Color(0.8, 0.4, 0.8, 0.9)  # Magenta
			icon_text = "🔍 "
		_:
			style_box.bg_color = Color(0.5, 0.5, 0.5, 0.9)  # Gray
			icon_text = "• "
	
	# Enhanced styling
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.WHITE
	alert_panel.add_theme_stylebox_override("panel", style_box)
	
	# Add alert content container
	var content_container = HBoxContainer.new()
	content_container.anchors_preset = Control.PRESET_FULL_RECT
	content_container.offset_left = 8
	content_container.offset_right = -8
	content_container.offset_top = 4
	content_container.offset_bottom = -4
	alert_panel.add_child(content_container)
	
	# Add alert text with icon
	var alert_label = Label.new()
	alert_label.text = icon_text + alert_data.message
	alert_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	alert_label.add_theme_color_override("font_color", Color.WHITE)
	alert_label.add_theme_font_size_override("font_size", 11)
	alert_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_child(alert_label)
	
	# Add timestamp for longer alerts
	if alert_data.duration > 3.0:
		var time_label = Label.new()
		time_label.text = alert_data.timestamp.substr(0, 5)  # HH:MM
		time_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		time_label.add_theme_font_size_override("font_size", 9)
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		content_container.add_child(time_label)
	
	return alert_panel

# Performance Monitoring
var trend_update_timer: float = 0.0
var trend_update_interval: float = 2.0  # Update trends every 2 seconds

func _process(delta):
	"""Update performance metrics and trends"""
	_update_fps_display()
	
	# Update trends periodically
	trend_update_timer += delta
	if trend_update_timer >= trend_update_interval:
		trend_update_timer = 0.0
		_update_market_trends()
		_update_artifact_bonuses()

func _input(event):
	"""Handle keyboard shortcuts"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_TAB:
				_toggle_status_panel()

func _toggle_status_panel():
	"""Toggle the main status panel"""
	var status_panel = get_node("../MainStatusPanel")
	if status_panel:
		status_panel.visible = not status_panel.visible
		if status_panel.visible:
			add_alert("info", "Status panel opened (TAB to close)", 2.0)
		else:
			add_alert("info", "Status panel closed", 1.0)

# Specialized alert methods for different game events
func add_trade_alert(good_type: String, quantity: int, profit: int, is_buying: bool):
	"""Add a trade-specific alert"""
	var action = "Bought" if is_buying else "Sold"
	var message = "%s %d %s for %s%d profit" % [action, quantity, good_type.capitalize(), "$" if profit >= 0 else "-$", abs(profit)]
	add_alert("trade", message, 3.0)

func add_travel_alert(from_system: String, to_system: String, fuel_cost: int):
	"""Add a travel-specific alert"""
	var message = "Traveled from %s to %s (-%d fuel)" % [from_system.capitalize(), to_system.capitalize(), fuel_cost]
	add_alert("travel", message, 3.0)

func add_discovery_alert(discovery_type: String, item_name: String):
	"""Add a discovery-specific alert"""
	var message = "Discovered %s: %s" % [discovery_type, item_name]
	add_alert("discovery", message, 5.0)

func add_system_alert(system_name: String, alert_type: String, message: String):
	"""Add a system-specific alert"""
	var full_message = "[%s] %s" % [system_name, message]
	add_alert(alert_type, full_message, 4.0)

func add_performance_alert(fps: int):
	"""Add performance warning if FPS is low"""
	if fps < 20:
		add_alert("warning", "Low performance detected (%d FPS)" % fps, 3.0)

var last_performance_alert_time: float = 0.0

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
	
	# Update display with memory usage
	var memory_usage = OS.get_static_memory_usage_by_type()
	var total_memory = 0
	for usage in memory_usage.values():
		total_memory += usage
	
	fps_label.text = "FPS: %d (%.1fms) | Mem: %.1fMB" % [fps, avg_frame_time, total_memory / 1024.0 / 1024.0]
	
	# Color code based on performance
	if fps >= 55:
		fps_label.modulate = Color.GREEN
	elif fps >= 30:
		fps_label.modulate = Color.YELLOW
	else:
		fps_label.modulate = Color.RED
		
		# Add performance alert (throttled to once per 10 seconds)
		var current_time = Time.get_time_string_from_system()
		if Time.get_unix_time_from_system() - last_performance_alert_time > 10:
			add_performance_alert(fps)
			last_performance_alert_time = Time.get_unix_time_from_system()

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

# Enhanced signal handlers
func _on_travel_started(from_system: String, to_system: String):
	"""Handle travel started event"""
	var fuel_cost = game_manager.economy_system.get_travel_cost(from_system, to_system)
	add_travel_alert(from_system, to_system, fuel_cost)

func _on_ship_stats_updated(stats: Dictionary):
	"""Handle ship stats update"""
	_update_artifact_bonuses()  # Refresh artifact bonuses display

func _on_trade_executed(system_id: String, good_type: String, quantity: int, is_buying: bool, profit: int):
	"""Handle trade execution"""
	add_trade_alert(good_type, quantity, profit, is_buying)

func _on_artifact_discovered(artifact_id: String, system_id: String, lore_fragment: String):
	"""Handle artifact discovery"""
	add_discovery_alert("Artifact", artifact_id.replace("_", " ").capitalize())

func _on_event_triggered(event_type: String, duration: float, effects: Dictionary):
	"""Handle dynamic event"""
	var message = "Galactic event: %s (%.0fs)" % [event_type.replace("_", " ").capitalize(), duration]
	add_system_alert("Galaxy", "warning", message)

# Resource trend tracking
var market_trends: Dictionary = {}

func _update_market_trends():
	"""Update market trend indicators"""
	if not game_manager:
		return
	
	var trend_panel = get_node_or_null("TrendPanel")
	if not trend_panel:
		return
	
	var trend_container = trend_panel.get_child(0) as VBoxContainer
	if not trend_container:
		return
	
	# Clear existing trend labels (keep title)
	var children = trend_container.get_children()
	for i in range(1, children.size()):
		children[i].queue_free()
	
	# Get current system market data
	var current_system = game_manager.player_data.current_system
	var goods = ["food", "minerals", "tech", "passengers"]
	
	for good in goods:
		var market_data = game_manager.get_market_data(good, current_system)
		var trend_label = Label.new()
		
		var trend_text = good.capitalize() + ": "
		var price_trend = market_data.get("price_trend", 0)
		
		if price_trend > 0.05:
			trend_text += "↗"
			trend_label.modulate = Color.GREEN
		elif price_trend < -0.05:
			trend_text += "↘"
			trend_label.modulate = Color.RED
		else:
			trend_text += "→"
			trend_label.modulate = Color.YELLOW
		
		trend_label.text = trend_text
		trend_label.add_theme_font_size_override("font_size", 9)
		trend_container.add_child(trend_label)

func _update_artifact_bonuses():
	"""Update artifact bonus indicators"""
	if not game_manager:
		return
	
	var artifact_panel = get_node_or_null("ArtifactPanel")
	if not artifact_panel:
		return
	
	var bonuses = game_manager.get_active_artifact_bonuses()
	var has_bonuses = false
	
	# Clear existing bonus indicators
	var artifact_container = artifact_panel.get_child(0) as HBoxContainer
	var children = artifact_container.get_children()
	for i in range(1, children.size()):  # Keep title
		children[i].queue_free()
	
	# Add bonus indicators
	for bonus_type in bonuses.keys():
		var bonus_value = bonuses[bonus_type]
		if bonus_value > 0:
			has_bonuses = true
			var bonus_label = Label.new()
			
			match bonus_type:
				"trade_bonus":
					bonus_label.text = "💰+" + str(int(bonus_value * 100)) + "%"
					bonus_label.modulate = Color.GOLD
				"fuel_efficiency_bonus":
					bonus_label.text = "⛽-" + str(int(bonus_value * 100)) + "%"
					bonus_label.modulate = Color.CYAN
				"global_efficiency":
					bonus_label.text = "⚡+" + str(int(bonus_value * 100)) + "%"
					bonus_label.modulate = Color.PURPLE
			
			bonus_label.add_theme_font_size_override("font_size", 10)
			artifact_container.add_child(bonus_label)
	
	artifact_panel.visible = has_bonuses