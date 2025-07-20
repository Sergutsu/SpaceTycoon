class_name GalaxyController
extends Node3D

# Camera settings
@export var camera_distance: float = 50.0
@export var min_camera_distance: float = 10.0
@export var max_camera_distance: float = 200.0
@export var camera_rotation_speed: float = 1.0
@export var camera_pan_speed: float = 0.5
@export var camera_zoom_speed: float = 5.0

# References
@onready var camera: Camera3D = $Camera3D
@onready var galaxy_generator = $GalaxyGenerator

# State
var _target_position: Vector3 = Vector3.ZERO
var _camera_rotation: Vector2 = Vector2(-PI/4, PI/4)  # x = rotation around Y, y = up/down tilt
var _current_distance: float = camera_distance
var _target_distance: float = camera_distance
var _is_rotating: bool = false
var _is_panning: bool = false
var _last_mouse_pos: Vector2
var _selected_system: Node3D = null

func _ready() -> void:
	_update_camera_position()
	
	# Connect to galaxy generator signals if any
	if galaxy_generator.has_signal("system_selected"):
		galaxy_generator.connect("system_selected", Callable(self, "_on_system_selected"))

func _unhandled_input(event: InputEvent) -> void:
	# Camera rotation
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_is_rotating = event.pressed
		if _is_rotating:
			_last_mouse_pos = get_viewport().get_mouse_position()
		get_viewport().set_input_as_handled()
	
	# Camera panning
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		_is_panning = event.pressed
		if _is_panning:
			_last_mouse_pos = get_viewport().get_mouse_position()
		get_viewport().set_input_as_handled()
	
	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_distance = clamp(_target_distance - camera_zoom_speed, min_camera_distance, max_camera_distance)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_distance = clamp(_target_distance + camera_zoom_speed, min_camera_distance, max_camera_distance)
			get_viewport().set_input_as_handled()
	
	# Handle mouse motion for rotation and panning
	if event is InputEventMouseMotion:
		var mouse_pos = get_viewport().get_mouse_position()
		var delta = mouse_pos - _last_mouse_pos
		
		if _is_rotating:
			# Rotate camera around target
			_camera_rotation.x -= delta.x * 0.01 * camera_rotation_speed
			_camera_rotation.y = clamp(_camera_rotation.y - delta.y * 0.01 * camera_rotation_speed, -PI/2 + 0.1, PI/2 - 0.1)
			_update_camera_position()
		elif _is_panning:
			# Pan camera
			var right = -camera.global_transform.basis.x
			var up = camera.global_transform.basis.y
			_target_position += (right * delta.x + up * -delta.y) * camera_pan_speed * 0.1
			_update_camera_position()
		
		_last_mouse_pos = mouse_pos
	
	# System selection
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_system_selection()

func _process(delta: float) -> void:
	# Smooth camera distance interpolation
	if not is_equal_approx(_current_distance, _target_distance):
		_current_distance = lerp(_current_distance, _target_distance, delta * 5.0)
		_update_camera_position()
	
	# Smooth camera position interpolation
	var current_pos = camera.global_position
	var target_pos = _target_position - camera.global_transform.basis.z * _current_distance
	
	if not current_pos.is_equal_approx(target_pos):
		camera.global_position = current_pos.lerp(target_pos, delta * 5.0)

func _update_camera_position() -> void:
	if not camera:
		return
	
	# Calculate camera position based on rotation and distance
	var direction = Vector3.FORWARD.rotated(Vector3.UP, _camera_rotation.x)
	direction = direction.rotated(Vector3.RIGHT, _camera_rotation.y)
	
	var target_pos = _target_position
	var camera_pos = target_pos - direction * _current_distance
	
	camera.look_at_from_position(camera_pos, target_pos, Vector3.UP)

func _handle_system_selection() -> void:
	# Cast ray from mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 1000.0
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	
	# Create query parameters for 3D raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var result = space_state.intersect_ray(query)
	
	if not result.is_empty():
		var collider = result["collider"]
		var system = _find_system_from_collider(collider)
		if system:
			select_system(system)
	else:
		# If no system was clicked, clear selection
		select_system(null)

func _find_system_from_collider(collider: Node) -> Node3D:
	# Traverse up the scene tree to find the StarSystem node
	var node = collider
	while node:
		if node is Node3D and node.has_method("get_system_info"):
			return node
		node = node.get_parent()
	return null

func select_system(system: Node3D) -> void:
	if _selected_system == system:
		return
	
	if _selected_system and _selected_system.has_method("set_selected"):
		_selected_system.set_selected(false)
	
	_selected_system = system
	
	if _selected_system and _selected_system.has_method("set_selected"):
		_selected_system.set_selected(true)
		emit_signal("system_selected", _selected_system)
	else:
		emit_signal("system_deselected")

func focus_on_system(system: Node3D, duration: float = 1.0) -> void:
	if not system:
		return
	
	# Create tween for smooth camera movement
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	# Calculate target camera distance based on star size
	var star_size = system.star_radius if system.has_method("get_star_radius") else 1.0
	var target_distance = max(star_size * 10.0, min_camera_distance)
	
	# Animate camera position and target
	tween.parallel().tween_property(self, "_target_position", system.global_position, duration)
	tween.parallel().tween_property(self, "_target_distance", target_distance, duration)
	
	# If the system is far away, also adjust the camera angle
	if system.global_position.distance_to(_target_position) > target_distance * 2.0:
		var dir = (system.global_position - _target_position).normalized()
		var target_rotation = Vector2(atan2(-dir.x, -dir.z), asin(dir.y))
		tween.parallel().tween_method(
			Callable(self, "_interpolate_camera_rotation"), 
			_camera_rotation, 
			target_rotation, 
			duration
		)

func _interpolate_camera_rotation(value: Vector2) -> void:
	_camera_rotation = value
	_update_camera_position()

func get_selected_system() -> Node3D:
	return _selected_system

signal system_selected(system: Node3D)
signal system_deselected()
