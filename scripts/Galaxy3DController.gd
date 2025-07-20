extends Node3D
class_name Galaxy3DController

# Signals for 3D galaxy events
signal planet_selected(system_id: String)
signal planet_hovered(system_id: String)
signal planet_unhovered(system_id: String)

# Node references
@onready var camera_3d: CameraController3D = $Camera3D
@onready var planet_container: Node3D = $PlanetContainer
@onready var ship_container: Node3D = $ShipContainer
@onready var effects_container: Node3D = $EffectsContainer

# Game manager reference
var game_manager: GameManager

# Planet management
var planet_nodes: Dictionary = {}  # system_id -> Planet3D node
var ship_node: Ship3D

# 3D space configuration
const GALAXY_SCALE: float = 8.0  # Scale factor for 3D positioning
const GALAXY_CENTER: Vector3 = Vector3.ZERO
const Y_SPREAD: float = 2.0  # Vertical spread for planets

# Current state
var selected_planet: String = ""
var current_location: String = ""

func _ready():
	# Find GameManager in the scene tree
	# Try multiple possible paths
	var possible_paths = [
		"/root/Main/GameManager",
		"../../../GameManager",
		"../../GameManager"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node and node is GameManager:
			game_manager = node
			break
	
	if game_manager:
		_connect_game_manager_signals()
		# Delay initialization to ensure all systems are ready
		call_deferred("_initialize_galaxy")
		print("Galaxy3DController: Connected to GameManager")
	else:
		push_error("Galaxy3DController: GameManager not found in any expected location!")

func _connect_game_manager_signals():
	"""Connect to GameManager signals for state updates"""
	if game_manager:
		game_manager.location_changed.connect(_on_location_changed)
		game_manager.travel_started.connect(_on_travel_started)
		game_manager.player_data_updated.connect(_on_player_data_updated)

func _initialize_galaxy():
	"""Initialize 3D galaxy with planets from GameManager data"""
	if not _validate_initialization_requirements():
		return
	
	var systems_data = game_manager.economy_system.get_all_systems()
	if systems_data.is_empty():
		push_error("Galaxy3DController: No systems data available")
		return
	
	# Clear existing planets
	_clear_existing_planets()
	
	# Create planets from system data
	for system_id in systems_data.keys():
		var system_data = systems_data[system_id]
		_create_planet_node(system_id, system_data)
	
	# Set initial current location
	if game_manager.player_data.has("current_system"):
		current_location = game_manager.player_data.current_system
	else:
		current_location = "terra_prime"  # Default fallback
	
	_update_planet_states()
	
	# Organize planets in container for better scene management
	organize_planet_container()
	
	print("Galaxy3DController: Initialized with ", systems_data.size(), " planets")
	print("Galaxy3DController: Current location set to ", current_location)
	
	# Print container stats for debugging
	var stats = get_planet_container_stats()
	print("Galaxy3DController: Planet distribution - ", stats)
	
	# Update camera bounds after planets are initialized
	if camera_3d:
		camera_3d.refresh_bounds()
	
	# Add ambient effects to planets
	_add_planet_ambient_effects()
	
	# Create and position ship
	_create_ship()

func _clear_existing_planets():
	"""Clear all existing planet nodes"""
	for child in planet_container.get_children():
		child.queue_free()
	planet_nodes.clear()

func _create_planet_node(system_id: String, system_data: Dictionary):
	"""Create a 3D planet node from system data"""
	# Create planet node
	var planet_node = Node3D.new()
	planet_node.name = "Planet_" + system_id
	
	# Calculate planet size based on system characteristics
	var planet_size = _calculate_planet_size(system_data)
	
	# Create mesh instance for visual representation
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = planet_size
	sphere_mesh.height = planet_size * 2.0
	# Optimize mesh detail based on planet size
	sphere_mesh.radial_segments = max(8, int(planet_size * 20))
	sphere_mesh.rings = max(6, int(planet_size * 12))
	mesh_instance.mesh = sphere_mesh
	
	# Create material based on planet type with enhanced properties
	var material = StandardMaterial3D.new()
	var planet_color = _get_planet_color(system_data.get("type", "unknown"))
	material.albedo_color = planet_color
	material.emission_enabled = true
	material.emission = planet_color * 0.3  # Subtle glow
	material.flags_unshaded = false  # Allow proper lighting
	material.flags_do_not_receive_shadows = false
	material.flags_disable_ambient_light = false
	mesh_instance.material_override = material
	
	# Create collision area for mouse interaction
	var area_3d = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = planet_size * 1.2  # Slightly larger than visual for easier clicking
	collision_shape.shape = sphere_shape
	area_3d.add_child(collision_shape)
	
	# Optimize collision detection
	area_3d.collision_layer = 1
	area_3d.collision_mask = 0
	area_3d.monitoring = true
	area_3d.monitorable = false
	
	# Connect area signals for interaction
	area_3d.input_event.connect(_on_planet_input_event.bind(system_id))
	area_3d.mouse_entered.connect(_on_planet_mouse_entered.bind(system_id))
	area_3d.mouse_exited.connect(_on_planet_mouse_exited.bind(system_id))
	
	# Add components to planet node
	planet_node.add_child(mesh_instance)
	planet_node.add_child(area_3d)
	
	# Position planet in 3D space using improved positioning logic
	var position_3d = _convert_2d_to_3d_position(system_data.get("position", Vector2.ZERO), system_data)
	planet_node.position = position_3d
	
	# Store references
	planet_nodes[system_id] = planet_node
	
	# Add to scene
	planet_container.add_child(planet_node)
	
	# Store system data and size in the node for easy access
	planet_node.set_meta("system_id", system_id)
	planet_node.set_meta("system_data", system_data)
	planet_node.set_meta("planet_size", planet_size)
	
	# Add subtle rotation animation
	_add_planet_rotation(planet_node, system_id)

func _convert_2d_to_3d_position(pos_2d: Vector2, system_data: Dictionary = {}) -> Vector3:
	"""Convert 2D galaxy position to 3D space coordinates with enhanced positioning logic"""
	# Calculate center point from all system positions for better centering
	var center_x = 275.0  # Approximate center of current system positions
	var center_y = 240.0
	
	# Normalize 2D position to center around origin
	var normalized_x = (pos_2d.x - center_x) / 100.0
	var normalized_z = (pos_2d.y - center_y) / 100.0
	
	# Scale for 3D space
	var x = normalized_x * GALAXY_SCALE
	var z = normalized_z * GALAXY_SCALE
	
	# Enhanced vertical positioning based on system type and characteristics
	var y = _calculate_planet_y_position(normalized_x, normalized_z, system_data)
	
	return Vector3(x, y, z)

func _get_planet_color(planet_type: String) -> Color:
	"""Get color for planet based on its type - enhanced color system"""
	match planet_type:
		"agricultural":
			return Color(0.0, 0.8, 0.2)  # Terra Prime - Rich Green
		"industrial":
			return Color(1.0, 0.6, 0.0)  # Minerva Station - Industrial Orange
		"luxury":
			return Color(0.7, 0.2, 0.9)  # Luxuria Resort - Luxury Purple
		"frontier":
			return Color(0.9, 0.2, 0.1)  # Frontier Outpost - Danger Red
		"hub":
			return Color(0.0, 0.8, 0.9)  # Nexus Station - Hub Cyan
		_:
			return Color(0.8, 0.8, 0.8)  # Default - Neutral Gray

func _update_planet_states():
	"""Update visual states of all planets based on game state"""
	var visited_systems = game_manager.player_data.get("systems_visited", [])
	
	for system_id in planet_nodes.keys():
		var planet_node = planet_nodes[system_id]
		var mesh_instance = planet_node.get_child(0) as MeshInstance3D
		var material = mesh_instance.material_override as StandardMaterial3D
		var base_size = planet_node.get_meta("planet_size", 0.5)
		
		if system_id == current_location:
			# Current location - bright glow and slight size increase
			material.emission = material.albedo_color * 0.8
			planet_node.scale = Vector3.ONE * (1.0 + base_size * 0.2)  # Scale based on base size
		elif system_id in visited_systems:
			# Visited - normal glow and base scale
			material.emission = material.albedo_color * 0.4
			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			material.albedo_color.a = 1.0
			planet_node.scale = Vector3.ONE
		else:
			# Unexplored - reduced opacity and glow, smaller scale
			material.emission = material.albedo_color * 0.1
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color.a = 0.5
			planet_node.scale = Vector3.ONE * 0.8

func select_planet(system_id: String):
	"""Select a planet and emit selection signal"""
	if system_id == selected_planet:
		return
	
	# Clear previous selection
	if selected_planet != "" and planet_nodes.has(selected_planet):
		_set_planet_selection_state(selected_planet, false)
	
	# Set new selection
	selected_planet = system_id
	if planet_nodes.has(system_id):
		_set_planet_selection_state(system_id, true)
		
		# Focus camera on selected planet
		if camera_3d:
			var planet_position = planet_nodes[system_id].position
			camera_3d.focus_on_planet(planet_position, 10.0, true)
		
		planet_selected.emit(system_id)

func _set_planet_selection_state(system_id: String, is_selected: bool):
	"""Set visual selection state for a planet"""
	if not planet_nodes.has(system_id):
		return
	
	_animate_planet_selection(system_id, is_selected)

func update_planet_data(system_id: String, data: Dictionary):
	"""Update planet data and visual representation"""
	if not planet_nodes.has(system_id):
		return
	
	var planet_node = planet_nodes[system_id]
	planet_node.set_meta("system_data", data)
	
	# Update visual representation if needed
	# This could include updating colors, effects, etc. based on new data

func get_planet_position_3d(system_id: String) -> Vector3:
	"""Get 3D position of a planet"""
	if planet_nodes.has(system_id):
		return planet_nodes[system_id].position
	return Vector3.ZERO

func get_all_planet_positions() -> Dictionary:
	"""Get all planet positions for camera bounds calculation"""
	var positions = {}
	for system_id in planet_nodes.keys():
		positions[system_id] = planet_nodes[system_id].position
	return positions

# Signal handlers
func _on_travel_started(from_system: String, to_system: String):
	"""Handle travel start - trigger ship animation"""
	animate_ship_travel(from_system, to_system)

func _on_location_changed(system_id: String):
	"""Handle player location change"""
	current_location = system_id
	_update_planet_states()
	
	# Only reposition ship immediately if not currently traveling
	if ship_node and not ship_node.is_traveling:
		_position_ship_at_current_location()

func _on_player_data_updated(_data: Dictionary):
	"""Handle player data updates"""
	# Update planet states when player data changes
	_update_planet_states()

# Planet interaction handlers
func _on_planet_input_event(system_id: String, _camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int):
	"""Handle planet click events"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			select_planet(system_id)

func _on_planet_mouse_entered(system_id: String):
	"""Handle planet hover start"""
	if planet_nodes.has(system_id) and system_id != selected_planet:
		_animate_planet_hover(system_id, true)
	planet_hovered.emit(system_id)

func _on_planet_mouse_exited(system_id: String):
	"""Handle planet hover end"""
	if planet_nodes.has(system_id) and system_id != selected_planet:
		_animate_planet_hover(system_id, false)
	planet_unhovered.emit(system_id)

# Public API methods
func get_selected_planet() -> String:
	"""Get currently selected planet ID"""
	return selected_planet

func get_current_location() -> String:
	"""Get current player location"""
	return current_location

func get_planet_data(system_id: String) -> Dictionary:
	"""Get planet data for a specific system"""
	if planet_nodes.has(system_id):
		return planet_nodes[system_id].get_meta("system_data", {})
	return {}

func _calculate_planet_size(system_data: Dictionary) -> float:
	"""Calculate planet size based on system characteristics"""
	var base_size = 0.5  # Default planet radius
	var system_type = system_data.get("type", "unknown")
	
	# Size variation based on planet type
	match system_type:
		"agricultural":
			base_size = 0.6  # Terra Prime - Larger agricultural world
		"industrial":
			base_size = 0.7  # Minerva Station - Large industrial complex
		"luxury":
			base_size = 0.4  # Luxuria Resort - Smaller luxury destination
		"frontier":
			base_size = 0.3  # Frontier Outpost - Small outpost
		"hub":
			base_size = 0.8  # Nexus Station - Large hub station
		_:
			base_size = 0.5  # Default size
	
	# Add some variation based on risk level
	var risk_level = system_data.get("risk_level", "safe")
	match risk_level:
		"safe":
			base_size *= 1.1  # Safe systems tend to be larger/more developed
		"high":
			base_size *= 0.9  # High risk systems tend to be smaller
		_:
			base_size *= 1.0  # No change for unknown risk levels
	
	# Add variation based on special features
	var special_features = system_data.get("special_features", [])
	if special_features.has("trade_hub"):
		base_size *= 1.2  # Trade hubs are larger
	if special_features.has("upgrade_shop"):
		base_size *= 1.1  # Systems with upgrade shops are slightly larger
	if special_features.has("volatile_prices"):
		base_size *= 0.8  # Volatile systems tend to be smaller/less stable
	
	# Clamp size to reasonable bounds
	return clamp(base_size, 0.2, 1.0)

func _calculate_planet_y_position(normalized_x: float, normalized_z: float, system_data: Dictionary) -> float:
	"""Calculate Y position for planet based on system characteristics"""
	var base_y = sin(normalized_x + normalized_z) * Y_SPREAD * 0.5
	var system_type = system_data.get("type", "unknown")
	
	# Adjust Y position based on system type for visual variety
	match system_type:
		"agricultural":
			base_y += 0.2  # Agricultural worlds slightly elevated
		"industrial":
			base_y -= 0.3  # Industrial systems lower (heavy/grounded)
		"luxury":
			base_y += 0.5  # Luxury resorts elevated (aspirational)
		"frontier":
			base_y += sin(normalized_x * 3.0) * 0.4  # Frontier systems more varied
		"hub":
			base_y *= 0.5  # Hub systems closer to center plane
		_:
			pass  # Default positioning
	
	# Add some randomness based on position for natural variation
	var position_seed = abs(int(normalized_x * 1000) + int(normalized_z * 1000))
	var rng = RandomNumberGenerator.new()
	rng.seed = position_seed
	base_y += rng.randf_range(-0.2, 0.2)
	
	# Clamp Y position to reasonable bounds
	return clamp(base_y, -Y_SPREAD, Y_SPREAD)

func animate_ship_travel(from_system: String, to_system: String):
	"""Animate ship travel between systems"""
	if not ship_node or not planet_nodes.has(from_system) or not planet_nodes.has(to_system):
		print("Galaxy3DController: Cannot animate travel - missing ship or planets")
		return
	
	var from_position = planet_nodes[from_system].position
	var to_position = planet_nodes[to_system].position
	var from_planet_size = planet_nodes[from_system].get_meta("planet_size", 0.5)
	var to_planet_size = planet_nodes[to_system].get_meta("planet_size", 0.5)
	
	# Calculate ship positions (offset from planets)
	var from_ship_pos = from_position + Vector3(0, from_planet_size + 0.5, from_planet_size + 0.3)
	var to_ship_pos = to_position + Vector3(0, to_planet_size + 0.5, to_planet_size + 0.3)
	
	# Calculate travel path with arc
	var travel_distance = from_position.distance_to(to_position)
	var travel_duration = clamp(travel_distance * 0.3, 1.0, 4.0)  # Scale duration with distance
	
	# Set ship to traveling state
	ship_node.set_traveling_state(true)
	ship_node.add_departure_effect()
	
	# Orient ship towards destination
	ship_node.orient_towards(to_ship_pos)
	
	# Create travel animation
	var travel_tween = create_tween()
	travel_tween.set_parallel(true)
	
	# Animate ship position along curved path
	travel_tween.tween_method(_update_ship_travel_position, 0.0, 1.0, travel_duration)
	
	# Store travel data for path calculation
	ship_node.set_meta("travel_from", from_ship_pos)
	ship_node.set_meta("travel_to", to_ship_pos)
	ship_node.set_meta("travel_arc_height", travel_distance * 0.2)
	
	# Complete travel animation
	travel_tween.finished.connect(_on_ship_travel_complete.bind(to_system))
	
	travel_tween.set_ease(Tween.EASE_IN_OUT)
	travel_tween.set_trans(Tween.TRANS_CUBIC)
	
	print("Galaxy3DController: Animating ship travel from ", from_system, " to ", to_system)

func _update_ship_travel_position(progress: float):
	"""Update ship position during travel animation"""
	if not ship_node:
		return
	
	var from_pos = ship_node.get_meta("travel_from", Vector3.ZERO)
	var to_pos = ship_node.get_meta("travel_to", Vector3.ZERO)
	var arc_height = ship_node.get_meta("travel_arc_height", 0.0)
	
	# Calculate position along curved path
	var linear_pos = from_pos.lerp(to_pos, progress)
	
	# Add arc (parabolic curve)
	var arc_offset = sin(progress * PI) * arc_height
	var arc_direction = Vector3.UP
	
	ship_node.position = linear_pos + arc_direction * arc_offset
	ship_node.travel_progress = progress
	
	# Orient ship along travel direction
	if progress < 0.95:  # Don't reorient at the very end
		var next_progress = min(progress + 0.05, 1.0)
		var next_linear_pos = from_pos.lerp(to_pos, next_progress)
		var next_arc_offset = sin(next_progress * PI) * arc_height
		var next_pos = next_linear_pos + arc_direction * next_arc_offset
		
		if next_pos != ship_node.position:
			ship_node.orient_towards(next_pos)

func _on_ship_travel_complete(to_system: String):
	"""Handle ship travel completion"""
	if not ship_node:
		return
	
	# Set ship to stationary state
	ship_node.set_traveling_state(false)
	ship_node.add_arrival_effect()
	ship_node.set_system_location(to_system)
	
	# Clean up travel metadata
	ship_node.remove_meta("travel_from")
	ship_node.remove_meta("travel_to")
	ship_node.remove_meta("travel_arc_height")
	
	# Update current location
	current_location = to_system
	_update_planet_states()
	
	print("Galaxy3DController: Ship travel completed to ", to_system)

func refresh_galaxy():
	"""Refresh the entire galaxy display"""
	_initialize_galaxy()

@warning_ignore("unused_parameter")
func update_camera_controls(delta: float):
	"""Update camera controls - called from _process if needed"""
	# Camera controller handles its own input and updates
	# This method is available for any additional camera logic if needed
	pass

func focus_camera_on_planet(system_id: String):
	"""Focus camera on a specific planet"""
	if planet_nodes.has(system_id) and camera_3d:
		var planet_position = planet_nodes[system_id].position
		camera_3d.focus_on_planet(planet_position)

func reset_camera_view():
	"""Reset camera to default galaxy view"""
	if camera_3d:
		camera_3d.focus_on_galaxy_center()

func organize_planet_container():
	"""Organize planets in the container for better scene management"""
	if not planet_container:
		return
	
	# Sort planets by type for better organization
	var planet_groups = {
		"hub": [],
		"agricultural": [],
		"industrial": [],
		"luxury": [],
		"frontier": []
	}
	
	# Group planets by type
	for system_id in planet_nodes.keys():
		var planet_node = planet_nodes[system_id]
		var system_data = planet_node.get_meta("system_data", {})
		var planet_type = system_data.get("type", "unknown")
		
		if planet_groups.has(planet_type):
			planet_groups[planet_type].append(planet_node)
		else:
			# Add unknown types to frontier group
			planet_groups["frontier"].append(planet_node)
	
	# Reorganize nodes in container (optional - mainly for scene tree organization)
	# This doesn't affect visual positioning but helps with debugging and scene management
	var index = 0
	for group_type in planet_groups.keys():
		for planet_node in planet_groups[group_type]:
			planet_container.move_child(planet_node, index)
			index += 1

func get_planet_container_stats() -> Dictionary:
	"""Get statistics about the planet container organization"""
	var stats = {
		"total_planets": planet_nodes.size(),
		"types": {},
		"size_distribution": {
			"small": 0,
			"medium": 0,
			"large": 0
		}
	}
	
	for system_id in planet_nodes.keys():
		var planet_node = planet_nodes[system_id]
		var system_data = planet_node.get_meta("system_data", {})
		var planet_type = system_data.get("type", "unknown")
		var planet_size = planet_node.get_meta("planet_size", 0.5)
		
		# Count by type
		if not stats.types.has(planet_type):
			stats.types[planet_type] = 0
		stats.types[planet_type] += 1
		
		# Count by size
		if planet_size < 0.4:
			stats.size_distribution.small += 1
		elif planet_size < 0.7:
			stats.size_distribution.medium += 1
		else:
			stats.size_distribution.large += 1
	
	return stats

# Visual effects and animation methods
@warning_ignore("unused_parameter")
func _add_planet_rotation(planet_node: Node3D, system_id: String):
	"""Add subtle rotation animation to planet"""
	var system_data = planet_node.get_meta("system_data", {})
	var planet_type = system_data.get("type", "unknown")
	
	# Different rotation speeds based on planet type
	var rotation_speed: float
	match planet_type:
		"agricultural":
			rotation_speed = 0.3  # Slow, peaceful rotation
		"industrial":
			rotation_speed = 0.5  # Moderate rotation
		"luxury":
			rotation_speed = 0.2  # Very slow, elegant rotation
		"frontier":
			rotation_speed = 0.8  # Fast, chaotic rotation
		"hub":
			rotation_speed = 0.4  # Steady rotation
		_:
			rotation_speed = 0.3
	
	# Create rotation tween
	var rotation_tween = create_tween()
	rotation_tween.set_loops()
	
	# Rotate around Y-axis
	rotation_tween.tween_property(planet_node, "rotation_degrees:y", 360.0, 1.0 / rotation_speed)
	rotation_tween.set_ease(Tween.EASE_IN)
	
	# Store tween for cleanup
	planet_node.set_meta("rotation_tween", rotation_tween)

func _add_planet_ambient_effects():
	"""Add ambient visual effects to all planets"""
	for system_id in planet_nodes.keys():
		var planet_node = planet_nodes[system_id]
		var system_data = planet_node.get_meta("system_data", {})
		
		# Add special effects for certain planet types
		if system_data.get("type") == "luxury":
			_add_luxury_planet_effects(planet_node)
		elif system_data.get("type") == "hub":
			_add_hub_planet_effects(planet_node)

func _add_luxury_planet_effects(planet_node: Node3D):
	"""Add special effects for luxury planets"""
	var mesh_instance = planet_node.get_child(0) as MeshInstance3D
	var material = mesh_instance.material_override as StandardMaterial3D
	
	# Add pulsing glow effect
	var pulse_tween = create_tween()
	pulse_tween.set_loops()
	
	var base_emission = material.emission
	pulse_tween.tween_property(material, "emission", base_emission * 1.3, 2.0)
	pulse_tween.tween_property(material, "emission", base_emission * 0.8, 2.0)
	pulse_tween.set_ease(Tween.EASE_IN_OUT)
	pulse_tween.set_trans(Tween.TRANS_SINE)
	
	planet_node.set_meta("luxury_pulse_tween", pulse_tween)

func _add_hub_planet_effects(planet_node: Node3D):
	"""Add special effects for hub planets"""
	var mesh_instance = planet_node.get_child(0) as MeshInstance3D
	var material = mesh_instance.material_override as StandardMaterial3D
	
	# Add rim lighting effect
	material.rim_enabled = true
	
	material.rim_tint = 0.3
	
	# Add rim pulsing
	var rim_tween = create_tween()
	rim_tween.set_loops()
	
	rim_tween.tween_property(material, "rim_tint", 0.6, 1.5)
	rim_tween.tween_property(material, "rim_tint", 0.2, 1.5)
	rim_tween.set_ease(Tween.EASE_IN_OUT)
	rim_tween.set_trans(Tween.TRANS_SINE)
	
	planet_node.set_meta("hub_rim_tween", rim_tween)

# Error handling and validation methods
func _validate_initialization_requirements() -> bool:
	"""Validate that all required components are available for initialization"""
	if not game_manager:
		push_error("Galaxy3DController: Cannot initialize - GameManager not available")
		return false
	
	if not game_manager.economy_system:
		push_error("Galaxy3DController: Cannot initialize - EconomySystem not available")
		return false
	
	if not planet_container:
		push_error("Galaxy3DController: Cannot initialize - PlanetContainer not available")
		return false
	
	if not ship_container:
		push_error("Galaxy3DController: Cannot initialize - ShipContainer not available")
		return false
	
	if not camera_3d:
		push_error("Galaxy3DController: Cannot initialize - Camera3D not available")
		return false
	
	return true

func _handle_planet_creation_error(system_id: String, error: String):
	"""Handle errors during planet creation"""
	push_error("Galaxy3DController: Failed to create planet for system " + system_id + " - " + error)
	
	# Remove any partially created planet node
	if planet_nodes.has(system_id):
		var planet_node = planet_nodes[system_id]
		if planet_node:
			planet_node.queue_free()
		planet_nodes.erase(system_id)

func _handle_ship_creation_error(error: String):
	"""Handle errors during ship creation"""
	push_error("Galaxy3DController: Failed to create ship - " + error)
	
	# Clean up any partially created ship
	if ship_node:
		ship_node.queue_free()
		ship_node = null

func get_system_health() -> Dictionary:
	"""Get system health information for debugging"""
	return {
		"game_manager_connected": game_manager != null,
		"economy_system_available": game_manager != null and game_manager.economy_system != null,
		"planet_count": planet_nodes.size(),
		"ship_available": ship_node != null,
		"camera_available": camera_3d != null,
		"containers_available": planet_container != null and ship_container != null
	}

# Performance optimization methods
func optimize_for_performance():
	"""Optimize 3D scene for better performance"""
	_optimize_planet_lod()
	_optimize_materials()
	_cleanup_unused_tweens()

func _optimize_planet_lod():
	"""Implement basic LOD system for planets"""
	if not camera_3d:
		return
	
	var camera_pos = camera_3d.position
	
	for system_id in planet_nodes.keys():
		var planet_node = planet_nodes[system_id]
		var distance = camera_pos.distance_to(planet_node.position)
		
		var mesh_instance = planet_node.get_child(0) as MeshInstance3D
		var sphere_mesh = mesh_instance.mesh as SphereMesh
		
		# Adjust mesh detail based on distance
		if distance > 20.0:
			# Far - low detail
			sphere_mesh.radial_segments = 8
			sphere_mesh.rings = 6
		elif distance > 10.0:
			# Medium - medium detail
			sphere_mesh.radial_segments = 12
			sphere_mesh.rings = 8
		else:
			# Close - high detail
			var planet_size = planet_node.get_meta("planet_size", 0.5)
			sphere_mesh.radial_segments = max(8, int(planet_size * 20))
			sphere_mesh.rings = max(6, int(planet_size * 12))

func _optimize_materials():
	"""Optimize material settings for performance"""
	for system_id in planet_nodes.keys():
		var planet_node = planet_nodes[system_id]
		var mesh_instance = planet_node.get_child(0) as MeshInstance3D
		var material = mesh_instance.material_override as StandardMaterial3D
		
		# Optimize material flags
		material.flags_do_not_receive_shadows = true
		material.flags_disable_ambient_light = false
		material.flags_use_point_size = false

func _cleanup_unused_tweens():
	"""Clean up any unused or completed tweens"""
	for system_id in planet_nodes.keys():
		var planet_node = planet_nodes[system_id]
		
		# Check for completed tweens and remove them
		var rotation_tween = planet_node.get_meta("rotation_tween", null)
		if rotation_tween and not rotation_tween.is_valid():
			planet_node.remove_meta("rotation_tween")
		
		var pulse_tween = planet_node.get_meta("pulse_tween", null)
		if pulse_tween and not pulse_tween.is_valid():
			planet_node.remove_meta("pulse_tween")

func get_performance_metrics() -> Dictionary:
	"""Get performance metrics"""
	var metrics = {
		"planet_count": planet_nodes.size(),
		"active_tweens": 0,
		"total_nodes": get_child_count(true),
		"memory_usage": 0  # Would need engine access for real memory usage
	}
	
	# Count active tweens
	for system_id in planet_nodes.keys():
		var planet_node = planet_nodes[system_id]
		if planet_node.has_meta("rotation_tween"):
			metrics.active_tweens += 1
		if planet_node.has_meta("pulse_tween"):
			metrics.active_tweens += 1
	
	return metrics

# Enhanced visual feedback methods
func _animate_planet_hover(system_id: String, is_hovering: bool):
	"""Animate planet hover effects"""
	if not planet_nodes.has(system_id):
		return
	
	var planet_node = planet_nodes[system_id]
	var mesh_instance = planet_node.get_child(0) as MeshInstance3D
	var material = mesh_instance.material_override as StandardMaterial3D
	var base_size = planet_node.get_meta("planet_size", 0.5)
	var visited_systems = game_manager.player_data.get("systems_visited", []) if game_manager else []
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if is_hovering:
		# Enhance glow and scale on hover
		var target_emission = material.emission * 1.5
		var target_scale = planet_node.scale * (1.0 + base_size * 0.15)
		
		tween.tween_property(material, "emission", target_emission, 0.2)
		tween.tween_property(planet_node, "scale", target_scale, 0.2)
	else:
		# Reset to appropriate state
		var target_emission: Color
		var target_scale: Vector3
		
		if system_id == current_location:
			target_emission = material.albedo_color * 0.8
			target_scale = Vector3.ONE * (1.0 + base_size * 0.2)
		elif system_id in visited_systems:
			target_emission = material.albedo_color * 0.4
			target_scale = Vector3.ONE
		else:
			target_emission = material.albedo_color * 0.1
			target_scale = Vector3.ONE * 0.8
		
		tween.tween_property(material, "emission", target_emission, 0.3)
		tween.tween_property(planet_node, "scale", target_scale, 0.3)
	
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

func _animate_planet_selection(system_id: String, is_selected: bool):
	"""Animate planet selection effects"""
	if not planet_nodes.has(system_id):
		return
	
	var planet_node = planet_nodes[system_id]
	var mesh_instance = planet_node.get_child(0) as MeshInstance3D
	var material = mesh_instance.material_override as StandardMaterial3D
	var base_size = planet_node.get_meta("planet_size", 0.5)
	var visited_systems = game_manager.player_data.get("systems_visited", []) if game_manager else []
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if is_selected:
		# Add selection highlight with enhanced glow
		material.rim_enabled = true
		material.rim = Color.WHITE
		material.rim_tint = 0.5
		
		var target_emission = Color.WHITE * 0.5
		var target_scale = Vector3.ONE * (1.0 + base_size * 0.4)
		
		tween.tween_property(material, "emission", target_emission, 0.3)
		tween.tween_property(planet_node, "scale", target_scale, 0.3)
		
		# Add pulsing effect for selection
		var pulse_tween = create_tween()
		pulse_tween.set_loops()
		pulse_tween.tween_property(material, "rim_tint", 0.8, 1.0)
		pulse_tween.tween_property(material, "rim_tint", 0.3, 1.0)
		pulse_tween.set_ease(Tween.EASE_IN_OUT)
		pulse_tween.set_trans(Tween.TRANS_SINE)
		
		# Store pulse tween for cleanup
		planet_node.set_meta("pulse_tween", pulse_tween)
	else:
		# Remove selection highlight and restore normal state
		material.rim_enabled = false
		
		# Stop pulsing effect
		var pulse_tween = planet_node.get_meta("pulse_tween", null)
		if pulse_tween:
			pulse_tween.kill()
			planet_node.remove_meta("pulse_tween")
		
		# Reset to appropriate state based on visit status
		var target_emission_color: Color
		var target_scale: Vector3
		
		if system_id == current_location:
			target_emission_color = material.albedo_color * 0.8
			target_scale = Vector3.ONE * (1.0 + base_size * 0.2)
		elif system_id in visited_systems:
			target_emission_color = material.albedo_color * 0.4
			target_scale = Vector3.ONE
		else:
			target_emission_color = material.albedo_color * 0.1
			target_scale = Vector3.ONE * 0.8
		
		tween.tween_property(material, "emission", target_emission_color, 0.4)
		tween.tween_property(planet_node, "scale", target_scale, 0.4)
	
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

# Ship management methods
func _create_ship():
	"""Create and initialize the player ship"""
	if ship_node:
		ship_node.queue_free()
	
	# Create ship instance
	ship_node = preload("res://scripts/Ship3D.gd").new()
	ship_node.name = "PlayerShip"
	
	# Add to ship container
	ship_container.add_child(ship_node)
	
	# Position ship at current location
	_position_ship_at_current_location()
	
	print("Galaxy3DController: Ship created and positioned")

func _position_ship_at_current_location():
	"""Position ship at current player location"""
	if not ship_node or not planet_nodes.has(current_location):
		return
	
	var planet_position = planet_nodes[current_location].position
	var planet_size = planet_nodes[current_location].get_meta("planet_size", 0.5)
	
	# Position ship slightly above and offset from planet
	var ship_offset = Vector3(0, planet_size + 0.5, planet_size + 0.3)
	ship_node.position = planet_position + ship_offset
	ship_node.set_system_location(current_location)
	
	print("Galaxy3DController: Ship positioned at ", current_location)

func get_ship_position() -> Vector3:
	"""Get current ship position"""
	if ship_node:
		return ship_node.position
	return Vector3.ZERO

func get_ship_info() -> Dictionary:
	"""Get ship information"""
	if ship_node:
		return ship_node.get_ship_info()
	return {}
