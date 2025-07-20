extends Node3D
class_name Galaxy3DController

# Signals for 3D galaxy events
signal planet_selected(system_id: String)
signal planet_hovered(system_id: String)
signal planet_unhovered(system_id: String)

# Node references
@onready var camera_3d: Camera3D = $Camera3D
@onready var planet_container: Node3D = $PlanetContainer
@onready var ship_container: Node3D = $ShipContainer
@onready var effects_container: Node3D = $EffectsContainer

# Game manager reference
var game_manager: GameManager

# Planet management
var planet_nodes: Dictionary = {}  # system_id -> Planet3D node
var ship_node: Node3D

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
		game_manager.player_data_updated.connect(_on_player_data_updated)

func _initialize_galaxy():
	"""Initialize 3D galaxy with planets from GameManager data"""
	if not game_manager:
		push_error("Galaxy3DController: Cannot initialize - GameManager not available")
		return
	
	if not game_manager.economy_system:
		push_error("Galaxy3DController: Cannot initialize - EconomySystem not available")
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
	
	print("Galaxy3DController: Initialized with ", systems_data.size(), " planets")
	print("Galaxy3DController: Current location set to ", current_location)

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
	
	# Create mesh instance for visual representation
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	mesh_instance.mesh = sphere_mesh
	
	# Create material based on planet type
	var material = StandardMaterial3D.new()
	var planet_color = _get_planet_color(system_data.get("type", "unknown"))
	material.albedo_color = planet_color
	material.emission_enabled = true
	material.emission = planet_color * 0.3  # Subtle glow
	mesh_instance.material_override = material
	
	# Create collision area for mouse interaction
	var area_3d = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.6  # Slightly larger than visual for easier clicking
	collision_shape.shape = sphere_shape
	area_3d.add_child(collision_shape)
	
	# Connect area signals for interaction
	area_3d.input_event.connect(_on_planet_input_event.bind(system_id))
	area_3d.mouse_entered.connect(_on_planet_mouse_entered.bind(system_id))
	area_3d.mouse_exited.connect(_on_planet_mouse_exited.bind(system_id))
	
	# Add components to planet node
	planet_node.add_child(mesh_instance)
	planet_node.add_child(area_3d)
	
	# Position planet in 3D space
	var position_3d = _convert_2d_to_3d_position(system_data.get("position", Vector2.ZERO))
	planet_node.position = position_3d
	
	# Store references
	planet_nodes[system_id] = planet_node
	
	# Add to scene
	planet_container.add_child(planet_node)
	
	# Store system data in the node for easy access
	planet_node.set_meta("system_id", system_id)
	planet_node.set_meta("system_data", system_data)

func _convert_2d_to_3d_position(pos_2d: Vector2) -> Vector3:
	"""Convert 2D galaxy position to 3D space coordinates"""
	# Calculate center point from all system positions for better centering
	var center_x = 275.0  # Approximate center of current system positions
	var center_y = 240.0
	
	# Normalize 2D position to center around origin
	var normalized_x = (pos_2d.x - center_x) / 100.0
	var normalized_z = (pos_2d.y - center_y) / 100.0
	
	# Scale for 3D space
	var x = normalized_x * GALAXY_SCALE
	var z = normalized_z * GALAXY_SCALE
	
	# Add some vertical variation for visual interest
	var y = sin(normalized_x + normalized_z) * Y_SPREAD * 0.5
	
	return Vector3(x, y, z)

func _get_planet_color(planet_type: String) -> Color:
	"""Get color for planet based on its type"""
	match planet_type:
		"agricultural":
			return Color.GREEN  # Terra Prime
		"industrial":
			return Color.ORANGE  # Minerva Station
		"luxury":
			return Color.PURPLE  # Luxuria Resort
		"frontier":
			return Color.RED  # Frontier Outpost
		"hub":
			return Color.CYAN  # Nexus Station
		_:
			return Color.WHITE  # Default

func _update_planet_states():
	"""Update visual states of all planets based on game state"""
	var visited_systems = game_manager.player_data.get("systems_visited", [])
	
	for system_id in planet_nodes.keys():
		var planet_node = planet_nodes[system_id]
		var mesh_instance = planet_node.get_child(0) as MeshInstance3D
		var material = mesh_instance.material_override as StandardMaterial3D
		
		if system_id == current_location:
			# Current location - bright glow
			material.emission_energy = 1.0
			planet_node.scale = Vector3.ONE * 1.1
		elif system_id in visited_systems:
			# Visited - normal glow
			material.emission_energy = 0.5
			planet_node.scale = Vector3.ONE
		else:
			# Unexplored - reduced opacity and glow
			material.emission_energy = 0.2
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color.a = 0.7
			planet_node.scale = Vector3.ONE * 0.9

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
		planet_selected.emit(system_id)

func _set_planet_selection_state(system_id: String, is_selected: bool):
	"""Set visual selection state for a planet"""
	if not planet_nodes.has(system_id):
		return
	
	var planet_node = planet_nodes[system_id]
	var mesh_instance = planet_node.get_child(0) as MeshInstance3D
	var material = mesh_instance.material_override as StandardMaterial3D
	
	if is_selected:
		# Add selection highlight
		material.rim_enabled = true
		material.rim = Color.WHITE
		material.rim_tint = 0.5
		planet_node.scale = Vector3.ONE * 1.2
	else:
		# Remove selection highlight
		material.rim_enabled = false
		# Reset scale based on current state
		if system_id == current_location:
			planet_node.scale = Vector3.ONE * 1.1
		else:
			planet_node.scale = Vector3.ONE

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
func _on_location_changed(system_id: String):
	"""Handle player location change"""
	current_location = system_id
	_update_planet_states()

func _on_player_data_updated(data: Dictionary):
	"""Handle player data updates"""
	# Update planet states when player data changes
	_update_planet_states()

# Planet interaction handlers
func _on_planet_input_event(system_id: String, camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int):
	"""Handle planet click events"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			select_planet(system_id)

func _on_planet_mouse_entered(system_id: String):
	"""Handle planet hover start"""
	if planet_nodes.has(system_id) and system_id != selected_planet:
		var planet_node = planet_nodes[system_id]
		planet_node.scale = planet_node.scale * 1.05  # Subtle scale increase
	planet_hovered.emit(system_id)

func _on_planet_mouse_exited(system_id: String):
	"""Handle planet hover end"""
	if planet_nodes.has(system_id) and system_id != selected_planet:
		var planet_node = planet_nodes[system_id]
		planet_node.scale = planet_node.scale / 1.05  # Reset scale
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

func animate_ship_travel(from_system: String, to_system: String):
	"""Animate ship travel between systems (placeholder for future implementation)"""
	# This will be implemented in a later task
	# For now, just update the current location immediately
	current_location = to_system
	_update_planet_states()

func refresh_galaxy():
	"""Refresh the entire galaxy display"""
	_initialize_galaxy()