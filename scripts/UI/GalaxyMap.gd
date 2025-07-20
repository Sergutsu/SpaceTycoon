extends Control
class_name GalaxyMap

# Game Manager reference
var game_manager: GameManager

# 3D Viewport reference
var galaxy_3d_viewport: SubViewport
var galaxy_3d_scene: Node3D

# Visual elements (for 2D fallback)
var system_nodes: Dictionary = {}
var ship_node: Control
var current_system_id: String = "terra_prime"
var tooltip_panel: Panel
var tooltip_label: Label

# 3D mode flag
var use_3d_mode: bool = true

# System colors based on type and risk level
var system_colors: Dictionary = {
	"terra_prime": Color.GREEN,
	"minerva_station": Color.ORANGE,
	"luxuria_resort": Color.PURPLE,
	"frontier_outpost": Color.RED,
	"nexus_station": Color.CYAN
}

# System visual characteristics
var system_visual_data: Dictionary = {
	"terra_prime": {"size": 60, "glow": false},
	"minerva_station": {"size": 55, "glow": false},
	"luxuria_resort": {"size": 65, "glow": true},
	"frontier_outpost": {"size": 50, "glow": false},
	"nexus_station": {"size": 70, "glow": true}
}

func _ready():
	# Get game manager reference
	game_manager = get_node("../../../GameManager")
	
	# Connect to game manager signals
	game_manager.location_changed.connect(_on_location_changed)
	game_manager.fuel_changed.connect(_on_fuel_changed)
	game_manager.player_data_updated.connect(_on_player_data_updated)
	
	# Initialize 3D viewport
	_initialize_3d_viewport()
	
	# Create tooltip (for both 2D and 3D modes)
	_create_tooltip()
	
	# Create visual elements (fallback for 2D mode)
	if not use_3d_mode:
		_create_systems()
		_create_ship()

func _initialize_3d_viewport():
	# Get 3D viewport reference
	galaxy_3d_viewport = get_node("Galaxy3DViewport")
	galaxy_3d_scene = galaxy_3d_viewport.get_node("Galaxy3DScene")
	
	if galaxy_3d_viewport and galaxy_3d_scene:
		use_3d_mode = true
		# Connect to resize events to update viewport size
		resized.connect(_on_galaxy_map_resized)
		# Set initial viewport size
		_update_viewport_size()
	else:
		use_3d_mode = false
		print("3D Galaxy view failed to initialize, falling back to 2D mode")

func _update_viewport_size():
	if galaxy_3d_viewport and use_3d_mode:
		galaxy_3d_viewport.size = Vector2i(int(size.x), int(size.y))

func _on_galaxy_map_resized():
	_update_viewport_size()

func _create_tooltip():
	tooltip_panel = Panel.new()
	tooltip_panel.name = "Tooltip"
	tooltip_panel.visible = false
	tooltip_panel.size = Vector2(250, 120)
	tooltip_panel.z_index = 100
	
	# Tooltip styling
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.CYAN
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	tooltip_panel.add_theme_stylebox_override("panel", style_box)
	
	tooltip_label = Label.new()
	tooltip_label.position = Vector2(10, 10)
	tooltip_label.size = Vector2(230, 100)
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.add_theme_color_override("font_color", Color.WHITE)
	tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	
	tooltip_panel.add_child(tooltip_label)
	add_child(tooltip_panel)

func _create_systems():
	var all_systems = game_manager.economy_system.get_all_systems()
	
	for system_id in all_systems.keys():
		var system_data = all_systems[system_id]
		var system_node = _create_system_node(system_id, system_data)
		add_child(system_node)
		system_nodes[system_id] = system_node

func _create_system_node(system_id: String, system_data: Dictionary) -> Control:
	var system_container = Control.new()
	system_container.name = "System_" + system_id
	
	# Position the system
	var pos = system_data["position"]
	system_container.position = pos
	system_container.size = Vector2(140, 120)
	system_container.pivot_offset = Vector2(70, 60)
	
	# Get visual characteristics
	var visual_data = system_visual_data[system_id]
	var system_size = visual_data["size"]
	var has_glow = visual_data["glow"]
	
	# System visual (circle)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = system_colors[system_id]
	
	# Make it circular
	var radius = system_size / 2
	style_box.corner_radius_top_left = radius
	style_box.corner_radius_top_right = radius
	style_box.corner_radius_bottom_left = radius
	style_box.corner_radius_bottom_right = radius
	
	# Border styling based on risk level and exploration
	var border_color = Color.CYAN
	var border_width = 2
	
	if system_data["risk_level"] == "high":
		border_color = Color.RED
		border_width = 3
	elif system_data["type"] == "hub":
		border_color = Color.GOLD
		border_width = 3
	
	# Check if system is explored
	var is_explored = game_manager.player_data.systems_visited.has(system_id)
	if not is_explored:
		# Unexplored systems have dimmed colors and dashed borders
		style_box.bg_color = style_box.bg_color * 0.5
		border_color = border_color * 0.7
	
	style_box.border_width_left = border_width
	style_box.border_width_right = border_width
	style_box.border_width_top = border_width
	style_box.border_width_bottom = border_width
	style_box.border_color = border_color
	
	# Add glow effect for special systems
	if has_glow and is_explored:
		style_box.shadow_color = system_colors[system_id] * 0.8
		style_box.shadow_size = 5
		style_box.shadow_offset = Vector2.ZERO
	
	var system_panel = Panel.new()
	system_panel.size = Vector2(system_size, system_size)
	system_panel.position = Vector2((140 - system_size) / 2, 10)
	system_panel.add_theme_stylebox_override("panel", style_box)
	
	# System name
	var name_label = Label.new()
	name_label.text = system_data["name"]
	name_label.position = Vector2(0, system_size + 20)
	name_label.size = Vector2(140, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color.CYAN if is_explored else Color.GRAY)
	
	# Risk indicator
	var risk_label = Label.new()
	risk_label.text = "Risk: " + system_data["risk_level"].capitalize()
	risk_label.position = Vector2(0, system_size + 40)
	risk_label.size = Vector2(140, 15)
	risk_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	risk_label.add_theme_font_size_override("font_size", 10)
	
	var risk_color = Color.GREEN
	if system_data["risk_level"] == "high":
		risk_color = Color.RED
	elif system_data["risk_level"] == "medium":
		risk_color = Color.YELLOW
	
	risk_label.add_theme_color_override("font_color", risk_color if is_explored else Color.GRAY)
	
	# Make system clickable and hoverable
	var button = Button.new()
	button.size = Vector2(140, 120)
	button.flat = true
	button.pressed.connect(_on_system_clicked.bind(system_id))
	button.mouse_entered.connect(_on_system_hover_start.bind(system_id))
	button.mouse_exited.connect(_on_system_hover_end)
	
	system_container.add_child(system_panel)
	system_container.add_child(name_label)
	system_container.add_child(risk_label)
	system_container.add_child(button)
	
	return system_container

func _create_ship():
	ship_node = Control.new()
	ship_node.name = "PlayerShip"
	ship_node.size = Vector2(30, 30)
	ship_node.z_index = 50
	
	# Ship visual (diamond/triangle shape)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.WHITE
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.GOLD
	style_box.corner_radius_top_left = 3
	style_box.corner_radius_top_right = 3
	style_box.corner_radius_bottom_left = 3
	style_box.corner_radius_bottom_right = 3
	
	var ship_panel = Panel.new()
	ship_panel.size = Vector2(20, 20)
	ship_panel.position = Vector2(5, 5)
	ship_panel.add_theme_stylebox_override("panel", style_box)
	
	# Ship engine glow
	var glow_panel = Panel.new()
	glow_panel.size = Vector2(24, 24)
	glow_panel.position = Vector2(3, 3)
	var glow_style = StyleBoxFlat.new()
	glow_style.bg_color = Color.TRANSPARENT
	glow_style.shadow_color = Color.CYAN
	glow_style.shadow_size = 8
	glow_style.shadow_offset = Vector2.ZERO
	glow_panel.add_theme_stylebox_override("panel", glow_style)
	
	ship_node.add_child(glow_panel)
	ship_node.add_child(ship_panel)
	add_child(ship_node)
	
	# Position ship at starting system
	_position_ship_at_system(current_system_id)

func _position_ship_at_system(system_id: String):
	if system_nodes.has(system_id):
		var all_systems = game_manager.economy_system.get_all_systems()
		var system_pos = all_systems[system_id]["position"]
		# Position ship slightly offset from system center
		ship_node.position = system_pos + Vector2(80, 45)

func _on_system_clicked(system_id: String):
	if system_id != current_system_id:
		# Get travel cost and check if we can travel
		var destinations = game_manager.get_available_destinations()
		var can_travel = false
		
		for dest in destinations:
			if dest["id"] == system_id:
				can_travel = dest["can_travel"]
				break
		
		if can_travel:
			var result = game_manager.travel_to_system(system_id)
			if not result.success:
				# Show error feedback (could emit signal for UI to handle)
				print("Travel failed: " + result.error)
		else:
			print("Insufficient fuel for travel to " + system_id)

func _on_system_hover_start(system_id: String):
	_show_tooltip(system_id)

func _on_system_hover_end():
	_hide_tooltip()

func _show_tooltip(system_id: String):
	var all_systems = game_manager.economy_system.get_all_systems()
	var system_data = all_systems[system_id]
	var destinations = game_manager.get_available_destinations()
	
	# Find travel cost
	var travel_cost = 0
	var can_travel = false
	for dest in destinations:
		if dest["id"] == system_id:
			travel_cost = dest["fuel_cost"]
			can_travel = dest["can_travel"]
			break
	
	# Build tooltip text
	@warning_ignore("shadowed_variable_base_class")
	var tooltip_text = system_data["name"] + "\n"
	tooltip_text += "Type: " + system_data["type"].capitalize() + "\n"
	tooltip_text += "Risk: " + system_data["risk_level"].capitalize() + "\n"
	
	if system_id != current_system_id:
		tooltip_text += "Travel Cost: " + str(travel_cost) + " fuel\n"
		tooltip_text += "Can Travel: " + ("Yes" if can_travel else "No") + "\n"
	else:
		tooltip_text += "Current Location\n"
	
	# Add special features
	if system_data.has("special_features") and system_data["special_features"].size() > 0:
		tooltip_text += "Features: " + ", ".join(system_data["special_features"])
	
	tooltip_label.text = tooltip_text
	
	# Position tooltip near mouse
	var mouse_pos = get_global_mouse_position()
	tooltip_panel.position = mouse_pos + Vector2(10, -60)
	
	# Keep tooltip within screen bounds
	var screen_size = get_viewport().get_visible_rect().size
	if tooltip_panel.position.x + tooltip_panel.size.x > screen_size.x:
		tooltip_panel.position.x = mouse_pos.x - tooltip_panel.size.x - 10
	if tooltip_panel.position.y < 0:
		tooltip_panel.position.y = mouse_pos.y + 20
	
	tooltip_panel.visible = true

func _hide_tooltip():
	tooltip_panel.visible = false

func _on_location_changed(system_id: String):
	current_system_id = system_id
	
	# Animate ship movement
	var tween = create_tween()
	var all_systems = game_manager.economy_system.get_all_systems()
	var target_pos = all_systems[system_id]["position"] + Vector2(80, 45)
	tween.tween_property(ship_node, "position", target_pos, 1.0)
	tween.tween_callback(_on_ship_movement_complete)
	
	# Update visual indicators for newly explored systems
	_update_system_visuals()

@warning_ignore("unused_parameter")
func _on_fuel_changed(new_fuel: int):
	# Update travel button states based on fuel availability
	_update_system_visuals()

@warning_ignore("unused_parameter")
func _on_player_data_updated(data: Dictionary):
	# Update system visuals when player data changes
	_update_system_visuals()

func _update_system_visuals():
	# Refresh all system visuals to reflect current exploration status
	for system_id in system_nodes.keys():
		var system_node = system_nodes[system_id]
		system_node.queue_free()
	
	system_nodes.clear()
	_create_systems()

func _on_ship_movement_complete():
	# Ship has arrived at destination
	pass
