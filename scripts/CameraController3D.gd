extends Camera3D
class_name CameraController3D

# Camera control settings
const ORBIT_SENSITIVITY: float = 0.005
const ZOOM_SENSITIVITY: float = 0.5
const PAN_SENSITIVITY: float = 0.01
const SMOOTH_FACTOR: float = 10.0

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

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _process(delta: float):
	# Smooth camera movement
	_smooth_camera_movement(delta)
	
	# Update camera position based on orbit parameters
	_update_camera_position()

func _handle_mouse_button(event: InputEventMouseButton):
	"""Handle mouse button events for camera controls"""
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_orbiting = true
				last_mouse_position = event.position
			else:
				is_orbiting = false
		
		MOUSE_BUTTON_MIDDLE:
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
func focus_on_planet(planet_position: Vector3, distance: float = 8.0):
	"""Focus camera on a specific planet"""
	orbit_center = planet_position
	target_distance = clamp(distance, MIN_DISTANCE, MAX_DISTANCE)

func focus_on_galaxy_center():
	"""Reset camera to focus on galaxy center"""
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