class_name GalaxyGenerator
extends Node3D

# Galaxy properties
@export var galaxy_radius: float = 100.0
@export var star_count: int = 50
@export var min_star_distance: float = 5.0
@export var arm_count: int = 4
@export var arm_angle: float = 0.3
@export var arm_tightness: float = 0.7

# Star system properties
@export var min_star_size: float = 0.5
@export var max_star_size: float = 2.5
@export var min_temperature: float = 3000.0  # Kelvin
@export var max_temperature: float = 30000.0  # Kelvin

# References
@onready var _star_system_scene = preload("res://addons/3d_ui/scripts/galaxy/star_system.gd")

var _star_systems: Array[Node3D] = []
var _selected_system: Node3D = null

func _ready() -> void:
	generate_galaxy()

func generate_galaxy() -> void:
	# Clear existing systems
	for system in _star_systems:
		system.queue_free()
	_star_systems.clear()
	
	# Generate star systems
	for i in range(star_count):
		var system = _create_star_system(i)
		if system:
			add_child(system)
			_star_systems.append(system)
	
	print("Generated ", _star_systems.size(), " star systems")

func _create_star_system(index: int) -> Node3D:
	var system = Node3D.new()
	system.set_script(_star_system_scene)
	
	# Generate position in spiral pattern
	var angle = randf() * TAU
	var distance = randf() * galaxy_radius
	var arm_offset = (randf() * 2.0 - 1.0) * 0.5
	
	# Spiral arm calculation
	var arm_angle = angle + (arm_offset * arm_angle)
	var arm_distance = distance * arm_tightness
	
	var x = cos(arm_angle) * arm_distance
	var z = sin(arm_angle) * arm_distance
	
	# Set position with some vertical variation
	var y = (randf() - 0.5) * (galaxy_radius * 0.1)
	system.position = Vector3(x, y, z)
	
	# Set star properties
	system.star_name = "Star-%03d" % (index + 1)
	system.star_radius = randf_range(min_star_size, max_star_size)
	system.star_temperature = randf_range(min_temperature, max_temperature)
	system.star_mass = system.star_radius * 0.8  # Rough estimate
	
	# Set star color based on temperature (blackbody radiation)
	system.star_color = _temperature_to_color(system.star_temperature)
	
	# Ensure minimum distance between stars
	if _is_too_close_to_other_systems(system):
		system.queue_free()
		return null
	
	return system

func _is_too_close_to_other_systems(new_system: Node3D) -> bool:
	for system in _star_systems:
		var distance = system.position.distance_to(new_system.position)
		if distance < min_star_distance:
			return true
	return false

func _temperature_to_color(temperature: float) -> Color:
	# Convert temperature to RGB color (blackbody radiation approximation)
	temperature = clamp(temperature, 1000.0, 40000.0) / 100.0
	
	var r: float = 0.0
	var g: float = 0.0
	var b: float = 0.0
	
	if temperature <= 66.0:
		r = 255.0
		g = clamp(99.4708025861 * log(temperature) - 161.1195681661, 0.0, 255.0)
	else:
		r = clamp(329.698727466 * pow(temperature - 60.0, -0.1332047592), 0.0, 255.0)
		g = clamp(288.1221695283 * pow(temperature - 60.0, -0.0755148492), 0.0, 255.0)
	
	if temperature >= 66.0:
		b = 255.0
	elif temperature <= 19.0:
		b = 0.0
	else:
		b = clamp(138.5177312231 * log(temperature - 10.0) - 305.0447927307, 0.0, 255.0)
	
	return Color(r / 255.0, g / 255.0, b / 255.0)

func select_system(system: Node3D) -> void:
	if _selected_system:
		_selected_system.set_selected(false)
	
	_selected_system = system
	
	if _selected_system:
		_selected_system.set_selected(true)
		print("Selected system: ", _selected_system.get_system_info())

func get_system_at_position(pos: Vector3, max_distance: float = 5.0) -> Node3D:
	var closest_system: Node3D = null
	var closest_distance: float = max_distance
	
	for system in _star_systems:
		var distance = system.global_position.distance_to(pos)
		if distance < closest_distance:
			closest_distance = distance
			closest_system = system
	
	return closest_system

func get_all_systems() -> Array[Node3D]:
	return _star_systems.duplicate()

func get_system_by_name(name: String) -> Node3D:
	for system in _star_systems:
		if system.star_name == name:
			return system
	return null
