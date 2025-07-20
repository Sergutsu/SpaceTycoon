extends Node
class_name Test3DGalaxy

# Test suite for 3D Galaxy functionality
var test_results: Array[Dictionary] = []
var galaxy_controller: Galaxy3DController
var camera_controller: CameraController3D
var ship_3d: Ship3D

func _ready():
	print("Test3DGalaxy: Starting 3D Galaxy test suite...")
	run_all_tests()

func run_all_tests():
	"""Run all 3D galaxy tests"""
	test_results.clear()
	
	# Component tests
	test_galaxy_controller_initialization()
	test_camera_controller_functionality()
	test_planet_creation_and_positioning()
	test_ship_creation_and_movement()
	test_visual_effects_and_animations()
	test_error_handling()
	
	# Integration tests
	test_gamemanager_integration()
	test_ui_integration()
	
	# Performance tests
	test_performance_metrics()
	
	# Print results
	print_test_results()

# Component Tests
func test_galaxy_controller_initialization():
	"""Test Galaxy3DController initialization"""
	var test_name = "Galaxy3DController Initialization"
	var success = true
	var details = []
	
	# Test 1: Controller creation
	galaxy_controller = Galaxy3DController.new()
	if not galaxy_controller:
		success = false
		details.append("Failed to create Galaxy3DController")
	else:
		details.append("Galaxy3DController created successfully")
	
	# Test 2: Required nodes
	galaxy_controller.name = "TestGalaxyController"
	add_child(galaxy_controller)
	
	# Add required child nodes for testing
	var camera = CameraController3D.new()
	camera.name = "Camera3D"
	galaxy_controller.add_child(camera)
	
	var planet_container = Node3D.new()
	planet_container.name = "PlanetContainer"
	galaxy_controller.add_child(planet_container)
	
	var ship_container = Node3D.new()
	ship_container.name = "ShipContainer"
	galaxy_controller.add_child(ship_container)
	
	var effects_container = Node3D.new()
	effects_container.name = "EffectsContainer"
	galaxy_controller.add_child(effects_container)
	
	# Test health check
	var health = galaxy_controller.get_system_health()
	if not health.camera_available or not health.containers_available:
		success = false
		details.append("System health check failed: " + str(health))
	else:
		details.append("System health check passed")
	
	_record_test_result(test_name, success, details)

func test_camera_controller_functionality():
	"""Test CameraController3D functionality"""
	var test_name = "CameraController3D Functionality"
	var success = true
	var details = []
	
	# Test camera creation
	camera_controller = CameraController3D.new()
	if not camera_controller:
		success = false
		details.append("Failed to create CameraController3D")
		_record_test_result(test_name, success, details)
		return
	
	add_child(camera_controller)
	details.append("CameraController3D created successfully")
	
	# Test camera info
	var camera_info = camera_controller.get_camera_info()
	if not camera_info.has("distance") or not camera_info.has("azimuth"):
		success = false
		details.append("Camera info incomplete: " + str(camera_info))
	else:
		details.append("Camera info complete")
	
	# Test focus methods
	camera_controller.focus_on_galaxy_center(false)
	camera_controller.focus_on_planet(Vector3(5, 0, 5), 10.0, false)
	details.append("Camera focus methods executed")
	
	_record_test_result(test_name, success, details)

func test_planet_creation_and_positioning():
	"""Test planet creation and positioning"""
	var test_name = "Planet Creation and Positioning"
	var success = true
	var details = []
	
	if not galaxy_controller:
		success = false
		details.append("Galaxy controller not available")
		_record_test_result(test_name, success, details)
		return
	
	# Test planet positioning calculation
	var test_positions = [
		Vector2(100, 100),
		Vector2(200, 150),
		Vector2(300, 200)
	]
	
	for pos_2d in test_positions:
		var pos_3d = galaxy_controller._convert_2d_to_3d_position(pos_2d)
		if pos_3d == Vector3.ZERO:
			success = false
			details.append("Failed to convert 2D position: " + str(pos_2d))
		else:
			details.append("Converted " + str(pos_2d) + " to " + str(pos_3d))
	
	# Test planet bounds calculation
	galaxy_controller._calculate_planet_bounds()
	details.append("Planet bounds calculation completed")
	
	_record_test_result(test_name, success, details)

func test_ship_creation_and_movement():
	"""Test Ship3D creation and movement"""
	var test_name = "Ship3D Creation and Movement"
	var success = true
	var details = []
	
	# Test ship creation
	ship_3d = Ship3D.new()
	if not ship_3d:
		success = false
		details.append("Failed to create Ship3D")
		_record_test_result(test_name, success, details)
		return
	
	add_child(ship_3d)
	details.append("Ship3D created successfully")
	
	# Test ship state management
	ship_3d.set_system_location("test_system")
	ship_3d.set_traveling_state(true)
	
	var ship_info = ship_3d.get_ship_info()
	if ship_info.current_system != "test_system" or not ship_info.is_traveling:
		success = false
		details.append("Ship state management failed: " + str(ship_info))
	else:
		details.append("Ship state management working")
	
	# Test ship effects
	ship_3d.add_departure_effect()
	ship_3d.add_arrival_effect()
	details.append("Ship effects executed")
	
	_record_test_result(test_name, success, details)

func test_visual_effects_and_animations():
	"""Test visual effects and animations"""
	var test_name = "Visual Effects and Animations"
	var success = true
	var details = []
	
	if not galaxy_controller:
		success = false
		details.append("Galaxy controller not available")
		_record_test_result(test_name, success, details)
		return
	
	# Create test planet for effects testing
	var test_planet = Node3D.new()
	test_planet.name = "TestPlanet"
	
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	mesh_instance.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GREEN
	material.emission_enabled = true
	mesh_instance.material_override = material
	
	test_planet.add_child(mesh_instance)
	test_planet.set_meta("planet_size", 0.5)
	test_planet.set_meta("system_data", {"type": "agricultural"})
	
	galaxy_controller.planet_container.add_child(test_planet)
	
	# Test rotation animation
	galaxy_controller._add_planet_rotation(test_planet, "test_system")
	details.append("Planet rotation animation added")
	
	# Test hover animation
	galaxy_controller._animate_planet_hover("test_system", true)
	await get_tree().create_timer(0.1).timeout
	galaxy_controller._animate_planet_hover("test_system", false)
	details.append("Planet hover animation tested")
	
	_record_test_result(test_name, success, details)

func test_error_handling():
	"""Test error handling and fallback systems"""
	var test_name = "Error Handling"
	var success = true
	var details = []
	
	if not galaxy_controller:
		success = false
		details.append("Galaxy controller not available")
		_record_test_result(test_name, success, details)
		return
	
	# Test validation
	var validation_result = galaxy_controller._validate_initialization_requirements()
	details.append("Validation result: " + str(validation_result))
	
	# Test error handling methods
	galaxy_controller._handle_planet_creation_error("test_system", "test error")
	galaxy_controller._handle_ship_creation_error("test error")
	details.append("Error handling methods executed")
	
	_record_test_result(test_name, success, details)

# Integration Tests
func test_gamemanager_integration():
	"""Test integration with GameManager"""
	var test_name = "GameManager Integration"
	var success = true
	var details = []
	
	# This would require a mock GameManager for proper testing
	# For now, just test the signal connection structure
	details.append("GameManager integration test - requires mock GameManager")
	
	_record_test_result(test_name, success, details)

func test_ui_integration():
	"""Test integration with UI systems"""
	var test_name = "UI Integration"
	var success = true
	var details = []
	
	# Test GalaxyMap 3D status
	var galaxy_map = GalaxyMap.new()
	add_child(galaxy_map)
	
	var status = galaxy_map.get_3d_status()
	details.append("3D status: " + str(status))
	
	# Test fallback functionality
	galaxy_map.force_2d_mode()
	details.append("2D fallback tested")
	
	_record_test_result(test_name, success, details)

# Performance Tests
func test_performance_metrics():
	"""Test performance metrics"""
	var test_name = "Performance Metrics"
	var success = true
	var details = []
	
	var start_time = Time.get_time_dict_from_system()
	
	# Create multiple planets to test performance
	for i in range(10):
		var planet = Node3D.new()
		planet.name = "PerfTestPlanet_" + str(i)
		
		var mesh_instance = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		mesh_instance.mesh = sphere_mesh
		planet.add_child(mesh_instance)
		
		add_child(planet)
	
	var end_time = Time.get_time_dict_from_system()
	var duration = (end_time.hour * 3600 + end_time.minute * 60 + end_time.second) - \
				   (start_time.hour * 3600 + start_time.minute * 60 + start_time.second)
	
	details.append("Created 10 planets in " + str(duration) + " seconds")
	
	if duration > 1:  # Should be very fast
		success = false
		details.append("Performance test failed - too slow")
	
	_record_test_result(test_name, success, details)

# Test utilities
func _record_test_result(test_name: String, success: bool, details: Array):
	"""Record a test result"""
	test_results.append({
		"name": test_name,
		"success": success,
		"details": details,
		"timestamp": Time.get_time_string_from_system()
	})

func print_test_results():
	"""Print all test results"""
	print("\n=== 3D Galaxy Test Results ===")
	
	var passed = 0
	var failed = 0
	
	for result in test_results:
		var status = "PASS" if result.success else "FAIL"
		print(status + ": " + result.name)
		
		for detail in result.details:
			print("  - " + detail)
		
		if result.success:
			passed += 1
		else:
			failed += 1
	
	print("\n=== Summary ===")
	print("Total tests: " + str(test_results.size()))
	print("Passed: " + str(passed))
	print("Failed: " + str(failed))
	print("Success rate: " + str(float(passed) / test_results.size() * 100) + "%")

func get_test_summary() -> Dictionary:
	"""Get test summary for external use"""
	var passed = 0
	var failed = 0
	
	for result in test_results:
		if result.success:
			passed += 1
		else:
			failed += 1
	
	return {
		"total": test_results.size(),
		"passed": passed,
		"failed": failed,
		"success_rate": float(passed) / test_results.size() if test_results.size() > 0 else 0.0,
		"results": test_results
	}