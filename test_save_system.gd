extends SceneTree

# Simple test script to verify save system functionality
func _init():
	print("Testing Save System...")
	
	# Test save data compilation
	var save_system = SaveSystem.new()
	print("SaveSystem created successfully")
	
	# Test save data validation
	var test_save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"game_data": {
			"player_data": {
				"credits": 10000,
				"current_system": "terra_prime",
				"ship": {
					"cargo_capacity": 50,
					"fuel_capacity": 100,
					"current_fuel": 100,
					"upgrades": {
						"cargo_hold": 0,
						"engine": 0,
						"scanner": 0,
						"ai_core": 0
					}
				},
				"inventory": {},
				"statistics": {
					"total_credits_earned": 0,
					"systems_explored": 1,
					"artifacts_found": 0,
					"trades_completed": 0
				}
			}
		}
	}
	
	var validation_result = save_system._validate_save_data(test_save_data)
	if validation_result.success:
		print("✓ Save data validation passed")
	else:
		print("✗ Save data validation failed: " + str(validation_result.errors))
	
	print("Save system test complete")
	quit()