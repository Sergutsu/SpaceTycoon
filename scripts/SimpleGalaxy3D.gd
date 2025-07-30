extends Node3D
class_name SimpleGalaxy3D

# Simple 3D galaxy with visible planets
var planet_nodes: Dictionary = {}
var camera_controller: CameraController3D

# Debug variables
var debug_enabled: bool = true
var debug_labels: Array[Label3D] = []

# Planet data - hardcoded for now to ensure visibility
var planet_data = {
	"terra_prime": {
		"name": "Terra Prime",
		"position": Vector3(0, 0, 0),
		"color": Color.GREEN,
		"size": 2.0
	},
	"minerva_station": {
		"name": "Minerva Station",
		"position": Vector3(8, 2, 5),
		"color": Color.ORANGE,
		"size": 1.8
	},
	"luxuria_resort": {
		"name": "Luxuria Resort",
		"position": Vector3(-6, -2, 8),
		"color": Color.PURPLE,
		"size": 2.2
	},
	"frontier_outpost": {
		"name": "Frontier Outpost",
		"position": Vector3(12, 3, -4),
		"color": Color.RED,
		"size": 1.6
	},
	"nexus_station": {
		"name": "Nexus Station",
		"position": Vector3(-10, 1, -6),
		"color": Color.CYAN,
		"size": 2.5
	}
}

func _ready():
	print("SimpleGalaxy3D: Starting initialization...")
	
	# Get camera controller
	var camera_node = get_node("Camera3D")
	if not camera_node:
		print("SimpleGalaxy3D: Camera not found!")
	else:
		print("SimpleGalaxy3D: Camera found at position: ", camera_node.position)
		
		# Set up simple camera position for testing
		camera_node.position = Vector3(0, 5, 15)
		camera_node.look_at(Vector3.ZERO, Vector3.UP)
		print("SimpleGalaxy3D: Set camera to look at origin from ", camera_node.position)
		
		# Try to get camera controller
		camera_controller = camera_node as CameraController3D
	
	# Create planets
	_create_planets()
	
	# Add debug visuals
	if debug_enabled:
		_create_debug_visuals()
	
	print("SimpleGalaxy3D: Initialization complete!")
	print("SimpleGalaxy3D: Scene tree structure:")
	_print_scene_tree(self, 0)

func _create_planets():
	print("SimpleGalaxy3D: Creating planets...")
	
	# First create a simple test cube to make sure 3D rendering works
	_create_test_cube()
	
	for planet_id in planet_data.keys():
		var data = planet_data[planet_id]
		var planet_node = _create_planet_node(planet_id, data)
		
		if planet_node:
			add_child(planet_node)
			planet_nodes[planet_id] = planet_node
			print("SimpleGalaxy3D: Created planet ", data.name, " at ", data.position)
	
	print("SimpleGalaxy3D: Created ", planet_nodes.size(), " planets")

func _create_test_cube():
	# Create a simple bright cube at origin to test visibility
	var test_cube = MeshInstance3D.new()
	test_cube.name = "TestCube"
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(3, 3, 3)
	test_cube.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.emission_enabled = true
	material.emission = Color.WHITE * 3.0
	material.flags_unshaded = true
	test_cube.material_override = material
	
	test_cube.position = Vector3(0, 0, 0)
	add_child(test_cube)
	
	print("SimpleGalaxy3D: Created test cube at origin")

func _create_planet_node(planet_id: String, data: Dictionary) -> Node3D:
	# Create planet container
	var planet_node = Node3D.new()
	planet_node.name = "Planet_" + planet_id
	planet_node.position = data.position
	
	# Create visual mesh
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = data.size
	sphere_mesh.height = data.size * 2.0
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8
	mesh_instance.mesh = sphere_mesh
	
	# Create bright material
	var material = StandardMaterial3D.new()
	material.albedo_color = data.color
	material.emission_enabled = true
	material.emission = data.color * 2.0 # Make it very bright
	material.flags_unshaded = true # Make it always visible
	material.no_depth_test = false
	mesh_instance.material_override = material
	
	# Add mesh to planet
	planet_node.add_child(mesh_instance)
	
	# Create collision for interaction
	var area_3d = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = data.size * 1.2
	collision_shape.shape = sphere_shape
	area_3d.add_child(collision_shape)
	
	# Connect interaction signals
	area_3d.input_event.connect(_on_planet_clicked.bind(planet_id))
	area_3d.mouse_entered.connect(_on_planet_hovered.bind(planet_id))
	area_3d.mouse_exited.connect(_on_planet_unhovered.bind(planet_id))
	
	planet_node.add_child(area_3d)
	
	return planet_node

func _create_debug_visuals():
	print("SimpleGalaxy3D: Creating debug visuals...")
	
	# Create debug labels for each planet
	for planet_id in planet_nodes.keys():
		var planet_node = planet_nodes[planet_id]
		var data = planet_data[planet_id]
		
		# Create 3D label
		var label_3d = Label3D.new()
		label_3d.text = data.name + "\n" + str(data.position)
		label_3d.position = data.position + Vector3(0, data.size + 1, 0)
		label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label_3d.modulate = Color.WHITE
		label_3d.outline_modulate = Color.BLACK
		label_3d.outline_size = 2
		
		add_child(label_3d)
		debug_labels.append(label_3d)
		
		print("SimpleGalaxy3D: Created debug label for ", data.name, " at ", label_3d.position)
	
	# Create coordinate system indicators
	_create_coordinate_indicators()
	
	# Create camera raycast debug
	_setup_raycast_debug()

func _create_coordinate_indicators():
	# X axis (red)
	var x_indicator = _create_debug_line(Vector3.ZERO, Vector3(5, 0, 0), Color.RED)
	add_child(x_indicator)
	
	# Y axis (green) 
	var y_indicator = _create_debug_line(Vector3.ZERO, Vector3(0, 5, 0), Color.GREEN)
	add_child(y_indicator)
	
	# Z axis (blue)
	var z_indicator = _create_debug_line(Vector3.ZERO, Vector3(0, 0, 5), Color.BLUE)
	add_child(z_indicator)
	
	print("SimpleGalaxy3D: Created coordinate indicators")

func _create_debug_line(from: Vector3, to: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	
	# Create line mesh
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	vertices.push_back(from)
	vertices.push_back(to)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	mesh_instance.mesh = array_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.flags_unshaded = true
	material.vertex_color_use_as_albedo = true
	mesh_instance.material_override = material
	
	return mesh_instance

func _setup_raycast_debug():
	# Add input handling for raycast debugging
	set_process_input(true)
	print("SimpleGalaxy3D: Raycast debug enabled - click to raycast")

func _input(event):
	if not debug_enabled:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_perform_debug_raycast(event.position)

func _perform_debug_raycast(screen_pos: Vector2):
	if not camera_controller:
		return
	
	print("SimpleGalaxy3D: Performing raycast from screen position: ", screen_pos)
	
	# Get camera
	var camera = camera_controller as Camera3D
	var from = camera.project_ray_origin(screen_pos)
	var to = from + camera.project_ray_normal(screen_pos) * 1000
	
	print("SimpleGalaxy3D: Ray from ", from, " to direction ", camera.project_ray_normal(screen_pos))
	
	# Perform raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result:
		print("SimpleGalaxy3D: Raycast hit at ", result.position, " with object ", result.collider)
		_create_debug_hit_indicator(result.position)
	else:
		print("SimpleGalaxy3D: Raycast missed")
		
	# Also check what's visible in camera frustum
	_debug_camera_frustum()

func _create_debug_hit_indicator(pos: Vector3):
	# Create a small sphere at hit position
	var indicator = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.2
	sphere_mesh.height = 0.4
	indicator.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.emission_enabled = true
	material.emission = Color.YELLOW
	indicator.material_override = material
	
	indicator.position = pos
	add_child(indicator)
	
	# Remove after 3 seconds
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(func(): indicator.queue_free(); timer.queue_free())
	add_child(timer)
	timer.start()

func _debug_camera_frustum():
	if not camera_controller:
		return
		
	var camera = camera_controller as Camera3D
	print("SimpleGalaxy3D: Camera debug info:")
	print("  Position: ", camera.global_position)
	print("  Rotation: ", camera.rotation_degrees)
	print("  FOV: ", camera.fov)
	print("  Near: ", camera.near)
	print("  Far: ", camera.far)
	
	# Check if planets are in view
	for planet_id in planet_nodes.keys():
		var planet_node = planet_nodes[planet_id]
		var planet_pos = planet_node.global_position
		var screen_pos = camera.unproject_position(planet_pos)
		var is_behind = camera.is_position_behind(planet_pos)
		
		print("  Planet ", planet_id, ":")
		print("    World pos: ", planet_pos)
		print("    Screen pos: ", screen_pos)
		print("    Behind camera: ", is_behind)
		print("    Distance: ", camera.global_position.distance_to(planet_pos))

func _print_scene_tree(node: Node, depth: int):
	var indent = ""
	for i in depth:
		indent += "  "
	
	var node_info = indent + node.name + " (" + node.get_class() + ")"
	if node is Node3D:
		node_info += " at " + str(node.position)
	print(node_info)
	
	for child in node.get_children():
		_print_scene_tree(child, depth + 1)

func _on_planet_clicked(planet_id: String, _camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("SimpleGalaxy3D: Clicked planet ", planet_id)
		
		# Focus camera on planet
		if camera_controller and planet_nodes.has(planet_id):
			var planet_pos = planet_nodes[planet_id].position
			camera_controller.focus_on_planet(planet_pos, 8.0)

func _on_planet_hovered(planet_id: String):
	print("SimpleGalaxy3D: Hovered planet ", planet_id)
	
	# Make planet brighter on hover
	if planet_nodes.has(planet_id):
		var planet_node = planet_nodes[planet_id]
		var mesh_instance = planet_node.get_child(0) as MeshInstance3D
		var material = mesh_instance.material_override as StandardMaterial3D
		material.emission = material.albedo_color * 0.8

func _on_planet_unhovered(planet_id: String):
	print("SimpleGalaxy3D: Unhovered planet ", planet_id)
	
	# Reset planet brightness
	if planet_nodes.has(planet_id):
		var planet_node = planet_nodes[planet_id]
		var mesh_instance = planet_node.get_child(0) as MeshInstance3D
		var material = mesh_instance.material_override as StandardMaterial3D
		material.emission = material.albedo_color * 0.5
