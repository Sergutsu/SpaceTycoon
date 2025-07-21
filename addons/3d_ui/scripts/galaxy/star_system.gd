class_name StarSystem
extends Node3D

# Star properties
var star_name: String = "Unnamed Star"
var star_radius: float = 1.0
var star_temperature: float = 5800.0  # Kelvin (Sun-like)
var star_mass: float = 1.0  # Solar masses
var star_color: Color = Color.WHITE

# System properties
var planets: Array = []
var has_asteroids: bool = false
var has_station: bool = false
var is_selected: bool = false

# Visual components
var star_mesh: MeshInstance3D
var selection_indicator: MeshInstance3D

func _ready() -> void:
	_create_star_visual()
	_create_selection_indicator()

func _create_star_visual() -> void:
	# Create star mesh
	star_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = star_radius
	sphere.height = star_radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	star_mesh.mesh = sphere
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = star_color
	material.emission_enabled = true
	material.emission = star_color
	material.flags_unshaded = true
	star_mesh.material_override = material
	
	add_child(star_mesh)

func _create_selection_indicator() -> void:
	# Create selection indicator (ring around star)
	selection_indicator = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = star_radius * 1.2
	torus.outer_radius = star_radius * 1.3
	torus.rings = 16
	torus.ring_segments = 8
	selection_indicator.mesh = torus
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.flags_unshaded = true
	selection_indicator.material_override = material
	
	# Initially hidden
	selection_indicator.visible = false
	
	add_child(selection_indicator)

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selection_indicator:
		selection_indicator.visible = is_selected

func get_system_info() -> Dictionary:
	return {
		"name": star_name,
		"radius": star_radius,
		"temperature": star_temperature,
		"mass": star_mass,
		"color": star_color,
		"position": global_position,
		"planets": planets.size(),
		"has_asteroids": has_asteroids,
		"has_station": has_station
	}

func add_planet(planet_data: Dictionary) -> void:
	planets.append(planet_data)
	
	# Visual representation of planet could be added here
	# For now, just storing the data

func _process(delta: float) -> void:
	# Optional: Add subtle rotation or pulsing effect for visual interest
	if star_mesh:
		star_mesh.rotate_y(delta * 0.1)
	
	if is_selected and selection_indicator:
		selection_indicator.rotate_y(delta * -0.2)