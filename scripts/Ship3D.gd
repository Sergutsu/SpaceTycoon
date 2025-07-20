extends Node3D
class_name Ship3D

# Ship visual components
var ship_body: MeshInstance3D
var ship_engine: MeshInstance3D
var ship_glow: MeshInstance3D

# Ship properties
var current_system_id: String = ""
var is_traveling: bool = false
var travel_progress: float = 0.0

# Visual settings
const SHIP_SCALE: float = 0.3
const ENGINE_GLOW_INTENSITY: float = 0.8
const TRAVEL_GLOW_INTENSITY: float = 1.2

func _ready():
	_create_ship_visual()

func _create_ship_visual():
	"""Create ship visual using primitive shapes"""
	# Main ship body (elongated box/cylinder)
	ship_body = MeshInstance3D.new()
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(0.8, 0.3, 1.5) * SHIP_SCALE
	ship_body.mesh = body_mesh
	
	# Ship body material
	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.8, 0.8, 0.9)  # Light gray/silver
	body_material.metallic = 0.7
	body_material.roughness = 0.3
	body_material.emission_enabled = true
	body_material.emission = Color(0.2, 0.3, 0.8) * 0.2  # Subtle blue glow
	ship_body.material_override = body_material
	
	# Engine section (smaller cylinder at back)
	ship_engine = MeshInstance3D.new()
	var engine_mesh = CylinderMesh.new()
	engine_mesh.height = 0.4 * SHIP_SCALE
	engine_mesh.top_radius = 0.15 * SHIP_SCALE
	engine_mesh.bottom_radius = 0.2 * SHIP_SCALE
	ship_engine.mesh = engine_mesh
	ship_engine.position = Vector3(0, 0, -0.6 * SHIP_SCALE)
	
	# Engine material with glow
	var engine_material = StandardMaterial3D.new()
	engine_material.albedo_color = Color(0.3, 0.3, 0.4)  # Dark gray
	engine_material.emission_enabled = true
	engine_material.emission = Color(0.0, 0.5, 1.0) * ENGINE_GLOW_INTENSITY  # Blue engine glow
	# Optimize material for performance
	engine_material.flags_do_not_receive_shadows = true
	engine_material.flags_disable_ambient_light = false
	ship_engine.material_override = engine_material
	
	# Engine glow effect (larger transparent sphere)
	ship_glow = MeshInstance3D.new()
	var glow_mesh = SphereMesh.new()
	glow_mesh.radius = 0.4 * SHIP_SCALE
	glow_mesh.height = 0.8 * SHIP_SCALE
	ship_glow.mesh = glow_mesh
	ship_glow.position = Vector3(0, 0, -0.5 * SHIP_SCALE)
	
	# Glow material
	var glow_material = StandardMaterial3D.new()
	glow_material.flags_transparent = true
	glow_material.albedo_color = Color(0.0, 0.5, 1.0, 0.3)  # Transparent blue
	glow_material.emission_enabled = true
	glow_material.emission = Color(0.0, 0.5, 1.0) * 0.5
	glow_material.flags_do_not_receive_shadows = true
	glow_material.flags_disable_ambient_light = true
	# Optimize for transparency
	glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_material.no_depth_test = false
	ship_glow.material_override = glow_material
	
	# Add components to ship
	add_child(ship_body)
	add_child(ship_engine)
	add_child(ship_glow)
	
	# Set initial rotation (point forward)
	rotation_degrees = Vector3(0, 0, 0)

func set_system_location(system_id: String):
	"""Set current system location"""
	current_system_id = system_id

func set_traveling_state(traveling: bool):
	"""Set ship traveling state with visual feedback"""
	is_traveling = traveling
	
	var engine_material = ship_engine.material_override as StandardMaterial3D
	var glow_material = ship_glow.material_override as StandardMaterial3D
	
	if traveling:
		# Enhanced glow during travel
		engine_material.emission = Color(0.0, 0.5, 1.0) * TRAVEL_GLOW_INTENSITY
		glow_material.emission = Color(0.0, 0.5, 1.0) * (TRAVEL_GLOW_INTENSITY * 0.8)
		glow_material.albedo_color.a = 0.5
		
		# Add pulsing effect during travel
		_start_travel_pulse()
	else:
		# Normal glow when stationary
		engine_material.emission = Color(0.0, 0.5, 1.0) * ENGINE_GLOW_INTENSITY
		glow_material.emission = Color(0.0, 0.5, 1.0) * (ENGINE_GLOW_INTENSITY * 0.5)
		glow_material.albedo_color.a = 0.3
		
		# Stop pulsing effect
		_stop_travel_pulse()

func _start_travel_pulse():
	"""Start pulsing effect during travel"""
	var tween = create_tween()
	tween.set_loops()
	
	var engine_material = ship_engine.material_override as StandardMaterial3D
	var base_emission = Color(0.0, 0.5, 1.0) * TRAVEL_GLOW_INTENSITY
	
	tween.tween_property(engine_material, "emission", base_emission * 1.5, 0.8)
	tween.tween_property(engine_material, "emission", base_emission * 0.7, 0.8)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# Store tween for cleanup
	set_meta("travel_pulse_tween", tween)

func _stop_travel_pulse():
	"""Stop pulsing effect"""
	var tween = get_meta("travel_pulse_tween", null)
	if tween:
		tween.kill()
		remove_meta("travel_pulse_tween")

func orient_towards(target_position: Vector3):
	"""Orient ship to face target position"""
	if target_position != position:
		look_at(target_position, Vector3.UP)

func get_ship_info() -> Dictionary:
	"""Get current ship state information"""
	return {
		"current_system": current_system_id,
		"is_traveling": is_traveling,
		"travel_progress": travel_progress,
		"position": position
	}

# Visual effect methods
func add_arrival_effect():
	"""Add visual effect when arriving at destination"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Brief bright flash
	var engine_material = ship_engine.material_override as StandardMaterial3D
	var original_emission = engine_material.emission
	
	tween.tween_property(engine_material, "emission", original_emission * 2.0, 0.2)
	tween.tween_property(engine_material, "emission", original_emission, 0.5)
	
	# Scale pulse
	var original_scale = scale
	tween.tween_property(self, "scale", original_scale * 1.2, 0.2)
	tween.tween_property(self, "scale", original_scale, 0.3)
	
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

func add_departure_effect():
	"""Add visual effect when departing from system"""
	var tween = create_tween()
	
	# Engine flare effect
	var engine_material = ship_engine.material_override as StandardMaterial3D
	var original_emission = engine_material.emission
	
	tween.tween_property(engine_material, "emission", original_emission * 1.8, 0.3)
	tween.tween_callback(func(): engine_material.emission = original_emission)
	
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)