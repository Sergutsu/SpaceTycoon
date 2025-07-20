extends Camera3D
class_name CameraController3D

# Camera control settings
const ORBIT_SENSITIVITY: float = 0.005
const ZOOM_SENSITIVITY: float = 0.5
const PAN_SENSITIVITY: float = 0.01
const SMOOTH_FACTOR: float = 10.0
const TWEEN_DURATION: float = 0.8

# Camera bounds
const MIN_DISTANCE: float = 5.0
const MAX_DISTANCE: float = 25.0
const MIN_ELEVATION: float = -80.0  # Degrees
const MAX_ELEVATION: float = 80.0   # Degrees

# Camera state
var orbit_center: Vector3 = Vector3.ZERO
var current_distance: float = 15.0
var target_distance: float = 15.0
var current_azimuth: float = 0.0    # Horizontal rotation (Y-axis)
var current_elevation: float = 30.0  # Vertical rotation (degrees)
var target_azimuth: float = 0.0
var target_elevation: float = 30.0

# Input state
var is_orbiting: bool = false
var is_panning: bool = false
var last_mouse_position: Vector2
var mouse_delta: Vector2

# Smooth transition system
var camera_tween: Tween
var is_tweening: bool = false

# Performance optimization
var _frame_count: int = 0

# Planet bounds for camera limiting
var planet_bounds: AABB
var galaxy_controller: Galaxy3DController

func _ready():
	# Find the Galaxy3DController parent
	galaxy_controller = get_parent() as Galaxy3DController
	if not galaxy_controller:
		push_error("CameraController3D: Parent must be Galaxy3DController")
		return
	
	# Initialize camera position
	_update_camera_position()
	
	# Calculate initial planet bounds
	call_deferred("_calculate_planet_bounds")
	
	# Create tween for smooth transitions
	camera_tween = create_tween()
	camera_tween.set_loops(0)
	camera_tween.finished.connect(_on_tween_finished)

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _process(delta: float):
	# Only apply manual smoothing if not tweening
	if not is_tweening:
		# Smooth camera movement
		_smooth_camera_movement(delta)
	
	# Update camera position based on orbit parameters
	_update_camera_position()
	
	# Periodic performance optimization
	_frame_count += 1
	if _frame_count % 60 == 0:  # Every 60 frames (1 second at 60fps)
		_optimize_camera_performance()

func _optimize_camera_performance():
	"""Optimize camera performance periodically"""
	if galaxy_controller:
		galaxy_controller.optimize_for_performance()

func _handle_mouse_button(event: InputEventMouseButton):
	"""Handle mouse button events for camera controls"""
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Check for modifier keys for panning
				if Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_CTRL):
					is_panning = true
				else:
					is_orbiting = true
				last_mouse_position = event.position
			else:
				is_orbiting = false
				is_panning = false
		
		MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				last_mouse_position = event.position
			else:
				is_panning = false
		
		MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_panning = true
				last_mouse_position = event.position
			else:
				is_panning = false
		
		MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(-ZOOM_SENSITIVITY)
		
		MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(ZOOM_SENSITIVITY)

func _handle_mouse_motion(event: InputEventMouseMotion):
	"""Handle mouse motion for orbit and pan controls"""
	if is_orbiting:
		mouse_delta = event.position - last_mouse_position
		
		# Update target orbit angles
		target_azimuth -= mouse_delta.x * ORBIT_SENSITIVITY
		target_elevation = clamp(
			target_elevation - mouse_delta.y * ORBIT_SENSITIVITY * 57.2958,  # Convert to degrees
			MIN_ELEVATION,
			MAX_ELEVATION
		)
		
		last_mouse_position = event.position
	
	elif is_panning:
		mouse_delta = event.position - last_mouse_position
		
		# Calculate pan direction based on camera orientation
		var right = transform.basis.x
		var up = transform.basis.y
		
		# Pan the orbit center
		var pan_offset = (-right * mouse_delta.x + up * mouse_delta.y) * PAN_SENSITIVITY * current_distance * 0.1
		orbit_center += pan_offset
		
		# Keep orbit center within reasonable bounds
		_clamp_orbit_center()
		
		last_mouse_position = event.position

func _zoom_camera(zoom_delta: float):
	"""Handle camera zoom with bounds checking"""
	target_distance = clamp(
		target_distance + zoom_delta,
		MIN_DISTANCE,
		MAX_DISTANCE
	)

func _smooth_camera_movement(delta: float):
	"""Apply smooth interpolation to camera movement"""
	# Smooth distance
	current_distance = lerp(current_distance, target_distance, SMOOTH_FACTOR * delta)
	
	# Smooth rotation angles
	current_azimuth = lerp_angle(current_azimuth, target_azimuth, SMOOTH_FACTOR * delta)
	current_elevation = lerp(current_elevation, target_elevation, SMOOTH_FACTOR * delta)

func _update_camera_position():
	"""Update camera position based on orbit parameters"""
	# Convert spherical coordinates to Cartesian
	var elevation_rad = deg_to_rad(current_elevation)
	var azimuth_rad = current_azimuth
	
	# Calculate position relative to orbit center
	var x = current_distance * cos(elevation_rad) * cos(azimuth_rad)
	var y = current_distance * sin(elevation_rad)
	var z = current_distance * cos(elevation_rad) * sin(azimuth_rad)
	
	# Set camera position
	position = orbit_center + Vector3(x, y, z)
	
	# Look at the orbit center
	look_at(orbit_center, Vector3.UP)

func _calculate_planet_bounds():
	"""Calculate bounds of all planets for camera limiting"""
	if not galaxy_controller:
		return
	
	var planet_positions = galaxy_controller.get_all_planet_positions()
	if planet_positions.is_empty():
		# Default bounds if no planets
		planet_bounds = AABB(Vector3(-10, -5, -10), Vector3(20, 10, 20))
		return
	
	# Calculate AABB from all planet positions
	var min_pos = Vector3(INF, INF, INF)
	var max_pos = Vector3(-INF, -INF, -INF)
	
	for pos in planet_positions.values():
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		min_pos.z = min(min_pos.z, pos.z)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)
		max_pos.z = max(max_pos.z, pos.z)
	
	# Add padding around planets
	var padding = Vector3(3, 2, 3)
	planet_bounds = AABB(min_pos - padding, max_pos - min_pos + padding * 2)
	
	print("CameraController3D: Planet bounds calculated - ", planet_bounds)

func _clamp_orbit_center():
	"""Keep orbit center within planet bounds"""
	if planet_bounds.size.length() > 0:
		# Clamp orbit center to stay within planet bounds
		orbit_center.x = clamp(orbit_center.x, planet_bounds.position.x, planet_bounds.end.x)
		orbit_center.y = clamp(orbit_center.y, planet_bounds.position.y, planet_bounds.end.y)
		orbit_center.z = clamp(orbit_center.z, planet_bounds.position.z, planet_bounds.end.z)

# Public API methods
func focus_on_planet(planet_position: Vector3, distance: float = 8.0, use_smooth_transition: bool = true):
	"""Focus camera on a specific planet"""
	var new_distance = clamp(distance, MIN_DISTANCE, MAX_DISTANCE)
	
	if use_smooth_transition:
		_smooth_transition_to(planet_position, new_distance, 0.0, 30.0)
	else:
		orbit_center = planet_position
		target_distance = new_distance

func focus_on_galaxy_center(use_smooth_transition: bool = true):
	"""Reset camera to focus on galaxy center"""
	if use_smooth_transition:
		_smooth_transition_to(Vector3.ZERO, 15.0, 0.0, 30.0)
	else:
		orbit_center = Vector3.ZERO
		target_distance = 15.0
		target_azimuth = 0.0
		target_elevation = 30.0

func set_orbit_sensitivity(sensitivity: float):
	"""Set orbit sensitivity (for settings/preferences)"""
	# This would modify ORBIT_SENSITIVITY if it wasn't const
	# Could be implemented with a variable instead of const for user preferences
	pass

func get_camera_info() -> Dictionary:
	"""Get current camera state information"""
	return {
		"distance": current_distance,
		"azimuth": current_azimuth,
		"elevation": current_elevation,
		"orbit_center": orbit_center,
		"bounds": planet_bounds
	}

func refresh_bounds():
	"""Refresh planet bounds calculation"""
	_calculate_planet_bounds()

# Smooth transition methods
func _smooth_transition_to(new_center: Vector3, new_distance: float, new_azimuth: float, new_elevation: float):
	"""Create smooth transition to new camera position"""
	if camera_tween:
		camera_tween.kill()
	
	camera_tween = create_tween()
	camera_tween.set_parallel(true)
	is_tweening = true
	
	# Tween orbit center
	camera_tween.tween_method(_set_orbit_center, orbit_center, new_center, TWEEN_DURATION)
	
	# Tween distance
	camera_tween.tween_method(_set_target_distance, current_distance, new_distance, TWEEN_DURATION)
	
	# Tween azimuth (handle angle wrapping)
	var azimuth_diff = _angle_difference(current_azimuth, new_azimuth)
	var target_azimuth_unwrapped = current_azimuth + azimuth_diff
	camera_tween.tween_method(_set_target_azimuth, current_azimuth, target_azimuth_unwrapped, TWEEN_DURATION)
	
	# Tween elevation
	camera_tween.tween_method(_set_target_elevation, current_elevation, new_elevation, TWEEN_DURATION)
	
	# Set easing for smooth feel
	camera_tween.set_ease(Tween.EASE_OUT)
	camera_tween.set_trans(Tween.TRANS_CUBIC)

func _set_orbit_center(center: Vector3):
	"""Tween callback for orbit center"""
	orbit_center = center

func _set_target_distance(distance: float):
	"""Tween callback for distance"""
	current_distance = distance
	target_distance = distance

func _set_target_azimuth(azimuth: float):
	"""Tween callback for azimuth"""
	current_azimuth = azimuth
	target_azimuth = azimuth

func _set_target_elevation(elevation: float):
	"""Tween callback for elevation"""
	current_elevation = elevation
	target_elevation = elevation

func _angle_difference(from_angle: float, to_angle: float) -> float:
	"""Calculate shortest angle difference"""
	var diff = fmod(to_angle - from_angle, TAU)
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	return diff

func _on_tween_finished():
	"""Called when tween animation completes"""
	is_tweening = false

# Enhanced camera control methods
func smooth_zoom_to(new_distance: float):
	"""Smoothly zoom to specific distance"""
	var clamped_distance = clamp(new_distance, MIN_DISTANCE, MAX_DISTANCE)
	if camera_tween:
		camera_tween.kill()
	
	camera_tween = create_tween()
	is_tweening = true
	camera_tween.tween_method(_set_target_distance, current_distance, clamped_distance, TWEEN_DURATION * 0.5)
	camera_tween.set_ease(Tween.EASE_OUT)
	camera_tween.set_trans(Tween.TRANS_QUAD)

func smooth_orbit_to(new_azimuth: float, new_elevation: float):
	"""Smoothly orbit to specific angles"""
	var clamped_elevation = clamp(new_elevation, MIN_ELEVATION, MAX_ELEVATION)
	
	if camera_tween:
		camera_tween.kill()
	
	camera_tween = create_tween()
	camera_tween.set_parallel(true)
	is_tweening = true
	
	# Handle azimuth wrapping
	var azimuth_diff = _angle_difference(current_azimuth, new_azimuth)
	var target_azimuth_unwrapped = current_azimuth + azimuth_diff
	
	camera_tween.tween_method(_set_target_azimuth, current_azimuth, target_azimuth_unwrapped, TWEEN_DURATION * 0.7)
	camera_tween.tween_method(_set_target_elevation, current_elevation, clamped_elevation, TWEEN_DURATION * 0.7)
	
	camera_tween.set_ease(Tween.EASE_OUT)
	camera_tween.set_trans(Tween.TRANS_CUBIC)