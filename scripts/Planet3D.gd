extends Node3D
class_name Planet3D

# Signals for planet interaction
signal planet_selected(system_id: String)
signal planet_hovered(system_id: String)
signal planet_unhovered(system_id: String)

# Planet properties
var system_id: String = ""
var planet_data: Dictionary = {}
var planet_type: String = ""

# Visual components
var mesh_instance: MeshInstance3D
var collision_area: Area3D
var collision_shape: CollisionShape3D

# Visual states
var is_selected: bool = false
var is_hovered: bool = false
var is_visited: bool = false
var is_current_location: bool = false

# Visual properties
var base_color: Color = Color.WHITE
var base_scale: float = 1.0
var hover_scale: float = 1.1

# Planet type colors based on design document
var planet_colors: Dictionary = {
	"terra_prime": Color.GREEN,
	"minerva_station": Color.ORANGE, 
	"luxuria_resort": Color.PURPLE,
	"frontier_outpost": Color.RED,
	"nexus_station": Color.CYAN,
	"default": Color.WHITE
}

func _ready():
	setup_planet_visual()
	setup_collision_detection()

func setup_planet_visual():
	# Create MeshInstance3D for the planet sphere
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create sphere mesh
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8
	mesh_instance.mesh = sphere_mesh
	
	# Create basic material with solid color
	var material = StandardMaterial3D.new()
	material.albedo_color = base_color
	material.flags_unshaded = true  # Simple flat shading
	material.flags_do_not_receive_shadows = true
	material.flags_disable_ambient_light = true
	mesh_instance.material_override = material

func setup_collision_detection():
	# Create Area3D for mouse interaction
	collision_area = Area3D.new()
	add_child(collision_area)
	
	# Create collision shape
	collision_shape = CollisionShape3D.new()
	collision_area.add_child(collision_shape)
	
	# Create sphere collision shape matching the visual mesh
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.5
	collision_shape.shape = sphere_shape
	
	# Connect signals for mouse interaction
	collision_area.mouse_entered.connect(_on_mouse_entered)
	collision_area.mouse_exited.connect(_on_mouse_exited)
	collision_area.input_event.connect(_on_input_event)

func initialize_planet(id: String, data: Dictionary):
	"""Initialize planet with game data"""
	system_id = id
	planet_data = data
	
	# Set planet type and determine color
	if data.has("type"):
		planet_type = data.type
	
	# Set base color based on planet type
	base_color = get_planet_color(planet_type)
	
	# Set scale based on planet characteristics
	if data.has("size"):
		base_scale = data.size
	else:
		base_scale = 1.0
	
	# Apply initial visual state
	update_visual_state()

func get_planet_color(type: String) -> Color:
	"""Get color for planet type"""
	var type_key = type.to_lower().replace(" ", "_")
	if planet_colors.has(type_key):
		return planet_colors[type_key]
	return planet_colors["default"]

func set_visited(visited: bool):
	"""Set planet visited state"""
	is_visited = visited
	update_visual_state()

func set_current_location(current: bool):
	"""Set planet as current location"""
	is_current_location = current
	update_visual_state()

func set_selected(selected: bool):
	"""Set planet selection state"""
	is_selected = selected
	update_visual_state()

func update_visual_state():
	"""Update visual appearance based on current state"""
	if not mesh_instance or not mesh_instance.material_override:
		return
	
	var material = mesh_instance.material_override as StandardMaterial3D
	var target_color = base_color
	var target_scale = base_scale
	var target_opacity = 1.0
	
	# Apply state-based visual modifications
	if not is_visited:
		# Unexplored planets have reduced opacity
		target_opacity = 0.5
	
	if is_current_location:
		# Current location has bright glow effect
		material.flags_unshaded = false
		material.emission_enabled = true
		material.emission = target_color * 0.3
	else:
		material.flags_unshaded = true
		material.emission_enabled = false
	
	if is_selected:
		# Selected planets have enhanced glow
		material.emission_enabled = true
		material.emission = target_color * 0.5
	
	if is_hovered:
		# Hovered planets scale up slightly
		target_scale *= hover_scale
	
	# Apply visual changes
	material.albedo_color = Color(target_color.r, target_color.g, target_color.b, target_opacity)
	scale = Vector3.ONE * target_scale

func _on_mouse_entered():
	"""Handle mouse hover start"""
	is_hovered = true
	update_visual_state()
	planet_hovered.emit(system_id)

func _on_mouse_exited():
	"""Handle mouse hover end"""
	is_hovered = false
	update_visual_state()
	planet_unhovered.emit(system_id)

func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int):
	"""Handle mouse click events"""
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			planet_selected.emit(system_id)