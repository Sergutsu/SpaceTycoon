extends Control
class_name GalaxyMapPanel

# Galaxy Map Panel - Enhanced 3D galaxy interface with overlays and controls
# Integrates with existing Galaxy3DScene

# References
var game_manager: GameManager
var galaxy_3d_scene: Node3D
var info_overlay: Panel
var travel_controls: Panel
var system_info_label: Label
var trade_lanes_container: Node3D
var political_borders_container: Node3D

# State
var selected_system: String = ""
var is_travel_mode: bool = false
var show_trade_lanes: bool = true
var show_political_borders: bool = false
var show_system_info: bool = true

# Trade lane visualization
var trade_lane_materials: Dictionary = {}
var active_trade_lanes: Array[MeshInstance3D] = []

func _ready():
	print("GalaxyMapPanel: Initializing...")
	
	# Get game manager reference
	game_manager = get_node("../GameManager")
	
	# Find the Galaxy3DScene
	galaxy_3d_scene = get_node("../Galaxy3DScene")
	
	if galaxy_3d_scene:
		print("GalaxyMapPanel: Connected to Galaxy3DScene")
		_setup_ui_overlays()
		_setup_3d_overlays()
		_connect_galaxy_signals()
		_initialize_trade_lanes()
	else:
		print("GalaxyMapPanel: Galaxy3DScene not found")

func _setup_ui_overlays():
	"""Create UI overlays for the 3D galaxy"""
	# System information overlay (top left)
	info_overlay = Panel.new()
	info_overlay.anchors_preset = Control.PRESET_TOP_LEFT
	info_overlay.offset_right = 300
	info_overlay.offset_bottom = 150
	info_overlay.offset_left = 10
	info_overlay.offset_top = 10
	info_overlay.visible = false
	add_child(info_overlay)
	
	# System info content
	var info_container = VBoxContainer.new()
	info_container.anchors_preset = Control.PRESET_FULL_RECT
	info_container.offset_left = 10
	info_container.offset_right = -10
	info_container.offset_top = 10
	info_container.offset_bottom = -10
	info_overlay.add_child(info_container)
	
	system_info_label = Label.new()
	system_info_label.text = "System Information"
	system_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(system_info_label)
	
	# Travel controls (bottom center)
	travel_controls = Panel.new()
	travel_controls.anchors_preset = Control.PRESET_BOTTOM_WIDE
	travel_controls.offset_left = 200
	travel_controls.offset_right = -200
	travel_controls.offset_top = -60
	travel_controls.offset_bottom = -10
	travel_controls.visible = false
	add_child(travel_controls)
	
	# Travel controls content
	var travel_container = HBoxContainer.new()
	travel_container.anchors_preset = Control.PRESET_FULL_RECT
	travel_container.offset_left = 10
	travel_container.offset_right = -10
	travel_container.offset_top = 10
	travel_container.offset_bottom = -10
	travel_container.alignment = BoxContainer.ALIGNMENT_CENTER
	travel_controls.add_child(travel_container)
	
	# Travel button
	var travel_button = Button.new()
	travel_button.text = "Travel Here"
	travel_button.custom_minimum_size = Vector2(100, 30)
	travel_button.pressed.connect(_on_travel_button_pressed)
	travel_container.add_child(travel_button)
	
	# Cancel button
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(80, 30)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	travel_container.add_child(cancel_button)
	
	# Instructions overlay (bottom left)
	var instructions_label = Label.new()
	instructions_label.anchors_preset = Control.PRESET_BOTTOM_LEFT
	instructions_label.offset_left = 10
	instructions_label.offset_top = -100
	instructions_label.offset_right = 300
	instructions_label.offset_bottom = -50
	instructions_label.text = "Left-drag: Orbit | Wheel: Zoom | Right-click: Info\nT: Toggle Trade Lanes | B: Toggle Borders | I: Toggle Info"
	instructions_label.add_theme_font_size_override("font_size", 10)
	instructions_label.modulate = Color(0.8, 0.8, 0.8)
	add_child(instructions_label)
	
	# View options panel (top right)
	var options_panel = Panel.new()
	options_panel.anchors_preset = Control.PRESET_TOP_RIGHT
	options_panel.offset_left = -200
	options_panel.offset_top = 10
	options_panel.offset_right = -10
	options_panel.offset_bottom = 120
	add_child(options_panel)
	
	var options_container = VBoxContainer.new()
	options_container.anchors_preset = Control.PRESET_FULL_RECT
	options_container.offset_left = 10
	options_container.offset_right = -10
	options_container.offset_top = 10
	options_container.offset_bottom = -10
	options_panel.add_child(options_container)
	
	var options_title = Label.new()
	options_title.text = "View Options"
	options_title.add_theme_font_size_override("font_size", 12)
	options_title.add_theme_color_override("font_color", Color.CYAN)
	options_container.add_child(options_title)
	
	# Trade lanes toggle
	var trade_lanes_check = CheckBox.new()
	trade_lanes_check.text = "Trade Lanes"
	trade_lanes_check.button_pressed = show_trade_lanes
	trade_lanes_check.toggled.connect(_on_trade_lanes_toggled)
	options_container.add_child(trade_lanes_check)
	
	# Political borders toggle
	var borders_check = CheckBox.new()
	borders_check.text = "Political Borders"
	borders_check.button_pressed = show_political_borders
	borders_check.toggled.connect(_on_political_borders_toggled)
	options_container.add_child(borders_check)
	
	# System info toggle
	var info_check = CheckBox.new()
	info_check.text = "System Info"
	info_check.button_pressed = show_system_info
	info_check.toggled.connect(_on_system_info_toggled)
	options_container.add_child(info_check)

func _connect_galaxy_signals():
	"""Connect to Galaxy3D signals if available"""
	if galaxy_3d_scene and galaxy_3d_scene.has_signal("planet_selected"):
		galaxy_3d_scene.planet_selected.connect(_on_planet_selected)
	if galaxy_3d_scene and galaxy_3d_scene.has_signal("planet_hovered"):
		galaxy_3d_scene.planet_hovered.connect(_on_planet_hovered)

func _input(event):
	"""Handle input events for galaxy interaction"""
	if not visible:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_handle_right_click(event.position)
	elif event is InputEventKey and event.pressed:
		handle_shortcut(event.keycode)

func _handle_right_click(screen_pos: Vector2):
	"""Handle right-click for system information"""
	# This would need integration with the 3D scene's raycast system
	# For now, show info for currently selected system
	if selected_system != "":
		_show_system_info(selected_system)

func _on_planet_selected(system_id: String):
	"""Handle planet selection from 3D galaxy"""
	selected_system = system_id
	_show_system_info(system_id)
	_show_travel_controls(system_id)
	
	# Add HUD alert
	var hud = get_node("../SimpleHUD")
	if hud and hud.has_method("add_alert"):
		hud.add_alert("info", "Selected system: " + system_id, 2.0)

func _on_planet_hovered(system_id: String):
	"""Handle planet hover from 3D galaxy"""
	# Could show quick info tooltip here
	pass

func _show_system_info(system_id: String):
	"""Display detailed system information"""
	if not game_manager or not system_info_label or not show_system_info:
		return
	
	var system_data = game_manager.economy_system.get_system_data(system_id)
	var info_text = ""
	
	info_text += "System: " + system_data.get("name", system_id) + "\n"
	info_text += "Type: " + system_data.get("type", "Unknown").capitalize() + "\n"
	info_text += "Risk Level: " + system_data.get("risk_level", "Unknown").capitalize() + "\n"
	
	# Add population and economy info
	var population = system_data.get("population", 0)
	if population > 0:
		info_text += "Population: " + _format_population(population) + "\n"
	
	var economy_type = system_data.get("economy_type", "mixed")
	info_text += "Economy: " + economy_type.capitalize() + "\n"
	
	# Add special features
	var features = system_data.get("special_features", [])
	if features.size() > 0:
		info_text += "Features: " + ", ".join(features).replace("_", " ") + "\n"
	
	# Add market information
	info_text += "\nMarket Prices:\n"
	var goods = ["food", "minerals", "tech", "passengers"]
	for good in goods:
		var price = game_manager.economy_system.calculate_dynamic_price(system_id, good)
		var trend = game_manager.get_market_data(good, system_id).get("price_trend", 0)
		var trend_indicator = "→"
		if trend > 0.05:
			trend_indicator = "↗"
		elif trend < -0.05:
			trend_indicator = "↘"
		
		info_text += "  " + good.capitalize() + ": $" + str(price) + " " + trend_indicator + "\n"
	
	# Add travel information
	if system_id != game_manager.player_data.current_system:
		var destinations = game_manager.get_available_destinations()
		for dest in destinations:
			if dest["id"] == system_id:
				info_text += "\nTravel Cost: " + str(dest["fuel_cost"]) + " fuel"
				info_text += "\nCan Travel: " + ("Yes" if dest["can_travel"] else "No")
				
				# Add estimated travel time
				var distance = _get_system_position(game_manager.player_data.current_system).distance_to(_get_system_position(system_id))
				var travel_time = distance / 10.0  # Rough estimate
				info_text += "\nEst. Time: " + "%.1f units" % travel_time
				break
	else:
		info_text += "\n[Current Location]"
		
		# Add current system bonuses/penalties
		var bonuses = system_data.get("trade_bonuses", {})
		if bonuses.size() > 0:
			info_text += "\nTrade Bonuses:\n"
			for bonus_type in bonuses.keys():
				var bonus_value = bonuses[bonus_type]
				info_text += "  " + bonus_type.capitalize() + ": +" + str(int(bonus_value * 100)) + "%\n"
	
	system_info_label.text = info_text
	info_overlay.visible = true

func _format_population(population: int) -> String:
	"""Format population numbers"""
	if population >= 1000000000:
		return "%.1fB" % (population / 1000000000.0)
	elif population >= 1000000:
		return "%.1fM" % (population / 1000000.0)
	elif population >= 1000:
		return "%.1fK" % (population / 1000.0)
	else:
		return str(population)

func _show_travel_controls(system_id: String):
	"""Show travel controls for selected system"""
	if system_id == game_manager.player_data.current_system:
		travel_controls.visible = false
		return
	
	# Check if travel is possible
	var destinations = game_manager.get_available_destinations()
	var can_travel = false
	
	for dest in destinations:
		if dest["id"] == system_id:
			can_travel = dest["can_travel"]
			break
	
	if can_travel:
		travel_controls.visible = true
		is_travel_mode = true
	else:
		travel_controls.visible = false

func _on_travel_button_pressed():
	"""Handle travel button press"""
	if selected_system != "" and game_manager:
		var result = game_manager.travel_to_system(selected_system)
		
		var hud = get_node("../SimpleHUD")
		if hud and hud.has_method("add_alert"):
			if result.success:
				hud.add_alert("success", "Traveling to " + selected_system, 3.0)
			else:
				hud.add_alert("error", "Travel failed: " + result.error, 4.0)
		
		_hide_travel_controls()

func _on_cancel_button_pressed():
	"""Handle cancel button press"""
	_hide_travel_controls()
	_hide_system_info()

func _hide_travel_controls():
	"""Hide travel controls"""
	travel_controls.visible = false
	is_travel_mode = false

func _hide_system_info():
	"""Hide system information"""
	info_overlay.visible = false
	selected_system = ""

# Public API
func focus_on_system(system_id: String):
	"""Focus the 3D view on a specific system"""
	if galaxy_3d_scene and galaxy_3d_scene.has_method("focus_camera_on_planet"):
		galaxy_3d_scene.focus_camera_on_planet(system_id)

func reset_view():
	"""Reset the 3D view to default position"""
	if galaxy_3d_scene and galaxy_3d_scene.has_method("reset_camera_view"):
		galaxy_3d_scene.reset_camera_view()

func get_selected_system() -> String:
	"""Get currently selected system"""
	return selected_system

# Keyboard shortcuts
func _setup_3d_overlays():
	"""Set up 3D overlays in the galaxy scene"""
	if not galaxy_3d_scene:
		return
	
	# Create trade lanes container
	trade_lanes_container = Node3D.new()
	trade_lanes_container.name = "TradeLanes"
	galaxy_3d_scene.add_child(trade_lanes_container)
	
	# Create political borders container
	political_borders_container = Node3D.new()
	political_borders_container.name = "PoliticalBorders"
	galaxy_3d_scene.add_child(political_borders_container)
	
	# Initialize materials
	_setup_trade_lane_materials()

func _setup_trade_lane_materials():
	"""Set up materials for trade lane visualization"""
	# Active trade lane (high traffic)
	var active_material = StandardMaterial3D.new()
	active_material.albedo_color = Color.GREEN
	active_material.emission_enabled = true
	active_material.emission = Color.GREEN * 0.5
	active_material.flags_unshaded = true
	active_material.flags_transparent = true
	active_material.albedo_color.a = 0.7
	trade_lane_materials["active"] = active_material
	
	# Moderate trade lane
	var moderate_material = StandardMaterial3D.new()
	moderate_material.albedo_color = Color.YELLOW
	moderate_material.emission_enabled = true
	moderate_material.emission = Color.YELLOW * 0.3
	moderate_material.flags_unshaded = true
	moderate_material.flags_transparent = true
	moderate_material.albedo_color.a = 0.5
	trade_lane_materials["moderate"] = moderate_material
	
	# Low traffic trade lane
	var low_material = StandardMaterial3D.new()
	low_material.albedo_color = Color.BLUE
	low_material.emission_enabled = true
	low_material.emission = Color.BLUE * 0.2
	low_material.flags_unshaded = true
	low_material.flags_transparent = true
	low_material.albedo_color.a = 0.3
	trade_lane_materials["low"] = low_material

func _initialize_trade_lanes():
	"""Initialize trade lane visualization"""
	if not game_manager or not trade_lanes_container:
		return
	
	# Get all systems and create trade lanes between connected systems
	var systems = game_manager.economy_system.get_all_systems()
	
	for system_id in systems.keys():
		var destinations = game_manager.get_available_destinations()
		
		# Create trade lanes from current system to all reachable destinations
		for dest in destinations:
			if dest["id"] != system_id:
				_create_trade_lane(system_id, dest["id"])

func _create_trade_lane(from_system: String, to_system: String):
	"""Create a visual trade lane between two systems"""
	if not trade_lanes_container:
		return
	
	# Get system positions (this would need to be implemented in the galaxy scene)
	var from_pos = _get_system_position(from_system)
	var to_pos = _get_system_position(to_system)
	
	if from_pos == Vector3.ZERO or to_pos == Vector3.ZERO:
		return
	
	# Create trade lane mesh
	var trade_lane = MeshInstance3D.new()
	trade_lane.name = "TradeLane_%s_%s" % [from_system, to_system]
	
	# Create line mesh between systems
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var colors = PackedColorArray()
	
	# Create a curved line with multiple segments
	var segments = 20
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var pos = from_pos.lerp(to_pos, t)
		
		# Add slight curve for visual appeal
		var mid_point = (from_pos + to_pos) * 0.5
		var curve_height = from_pos.distance_to(to_pos) * 0.1
		pos.y += sin(t * PI) * curve_height
		
		vertices.push_back(pos)
		colors.push_back(Color.GREEN)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	
	# Create line strip
	var indices = PackedInt32Array()
	for i in range(segments):
		indices.push_back(i)
		indices.push_back(i + 1)
	
	arrays[Mesh.ARRAY_INDEX] = indices
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	trade_lane.mesh = array_mesh
	trade_lane.material_override = trade_lane_materials["active"]
	trade_lane.visible = show_trade_lanes
	
	trade_lanes_container.add_child(trade_lane)
	active_trade_lanes.append(trade_lane)

func _get_system_position(system_id: String) -> Vector3:
	"""Get 3D position of a system (placeholder implementation)"""
	# This should match the positions in the Galaxy3DScene
	var positions = {
		"terra_prime": Vector3(0, 0, 0),
		"minerva_station": Vector3(8, 2, 5),
		"luxuria_resort": Vector3(-6, -2, 8),
		"frontier_outpost": Vector3(12, 3, -4),
		"nexus_station": Vector3(-10, 1, -6)
	}
	
	return positions.get(system_id, Vector3.ZERO)

# Toggle methods for view options
func _on_trade_lanes_toggled(enabled: bool):
	"""Toggle trade lanes visibility"""
	show_trade_lanes = enabled
	if trade_lanes_container:
		trade_lanes_container.visible = enabled

func _on_political_borders_toggled(enabled: bool):
	"""Toggle political borders visibility"""
	show_political_borders = enabled
	if political_borders_container:
		political_borders_container.visible = enabled

func _on_system_info_toggled(enabled: bool):
	"""Toggle system info overlay"""
	show_system_info = enabled
	if info_overlay:
		info_overlay.visible = enabled and selected_system != ""

func handle_shortcut(key: int):
	"""Handle keyboard shortcuts"""
	match key:
		KEY_ESCAPE:
			_hide_travel_controls()
			_hide_system_info()
		KEY_R:
			reset_view()
		KEY_SPACE:
			if selected_system != "":
				focus_on_system(selected_system)
		KEY_T:
			_on_trade_lanes_toggled(not show_trade_lanes)
		KEY_B:
			_on_political_borders_toggled(not show_political_borders)
		KEY_I:
			_on_system_info_toggled(not show_system_info)