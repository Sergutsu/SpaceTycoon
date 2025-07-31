extends SceneTree

# Test runner for UI components
# This script can be run with: godot --headless --script scripts/tests/run_ui_tests.gd --quit

func _init():
	print("Starting UI Component Tests...")
	
	# Run the tests
	var success = TestUIComponents.run_all_tests()
	
	if success:
		print("All UI component tests passed!")
		quit(0)
	else:
		print("Some UI component tests failed!")
		quit(1)