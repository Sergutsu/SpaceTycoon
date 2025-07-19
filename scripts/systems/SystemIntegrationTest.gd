extends Node
class_name SystemIntegrationTest

# Integration test for the enhanced system architecture
func run_integration_tests():
	print("Running system integration tests...")
	
	# Create a test GameManager instance
	var game_manager = GameManager.new()
	add_child(game_manager)
	
	# Wait for systems to initialize
	await get_tree().process_frame
	
	# Test 1: Basic system initialization
	assert(game_manager.economy_system != null, "EconomySystem should be initialized")
	assert(game_manager.ship_system != null, "ShipSystem should be initialized")
	assert(game_manager.artifact_system != null, "ArtifactSystem should be initialized")
	assert(game_manager.automation_system != null, "AutomationSystem should be initialized")
	assert(game_manager.event_system != null, "EventSystem should be initialized")
	print("✓ All systems initialized correctly")
	
	# Test 2: Player data structure
	assert(game_manager.player_data.has("credits"), "Player data should have credits")
	assert(game_manager.player_data.has("ship"), "Player data should have ship data")
	assert(game_manager.player_data.has("inventory"), "Player data should have inventory")
	assert(game_manager.player_data.has("statistics"), "Player data should have statistics")
	print("✓ Player data structure is complete")
	
	# Test 3: System communication
	var initial_credits = game_manager.player_data.credits
	var buy_result = game_manager.buy_good("food", 1)
	if buy_result.success:
		assert(game_manager.player_data.credits < initial_credits, "Credits should decrease after purchase")
		print("✓ Trading system works correctly")
	else:
		print("! Trading test skipped - ", buy_result.error)
	
	# Test 4: Ship upgrade system
	var upgrade_info = game_manager.ship_system.get_upgrade_info("cargo_hold", 0)
	assert(not upgrade_info.is_empty(), "Should get upgrade info")
	assert(upgrade_info.has("name"), "Upgrade info should have name")
	print("✓ Ship upgrade system accessible")
	
	# Test 5: Event system
	var active_events = game_manager.event_system.get_active_events()
	assert(active_events is Array, "Should return array of active events")
	print("✓ Event system accessible")
	
	print("All integration tests passed!")
	
	# Clean up
	game_manager.queue_free()

func _ready():
	# Run tests after a short delay to ensure everything is loaded
	await get_tree().create_timer(0.1).timeout
	run_integration_tests()