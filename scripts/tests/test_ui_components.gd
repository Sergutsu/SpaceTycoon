extends RefCounted
class_name TestUIComponents

# Test script for UI component templates
# This validates that all UI components can be instantiated and configured properly

static func test_alert_item_creation() -> bool:
	"""Test AlertItem creation and configuration"""
	print("Testing AlertItem creation...")
	
	var alert_item = UITemplates.create_alert_item()
	if not alert_item:
		print("FAIL: Could not create AlertItem")
		return false
	
	# Test setup with different alert types
	var test_data = {
		"type": "warning",
		"message": "Test warning message",
		"timestamp": "12:34",
		"duration": 0  # Don't auto-remove during test
	}
	
	alert_item.setup_alert(test_data)
	
	# Verify the alert was configured correctly
	if alert_item.get_alert_type() != "warning":
		print("FAIL: Alert type not set correctly")
		alert_item.queue_free()
		return false
	
	if alert_item.get_alert_message() != "Test warning message":
		print("FAIL: Alert message not set correctly")
		alert_item.queue_free()
		return false
	
	alert_item.queue_free()
	print("PASS: AlertItem creation and setup")
	return true

static func test_quick_nav_button_creation() -> bool:
	"""Test QuickNavButton creation and configuration"""
	print("Testing QuickNavButton creation...")
	
	var nav_button = UITemplates.create_quick_nav_button()
	if not nav_button:
		print("FAIL: Could not create QuickNavButton")
		return false
	
	# Test setup
	nav_button.setup_button("TAB", "Status", "MainStatusPanel")
	
	# Verify configuration
	if nav_button.get_panel_name() != "MainStatusPanel":
		print("FAIL: Panel name not set correctly")
		nav_button.queue_free()
		return false
	
	if nav_button.get_shortcut_key() != "TAB":
		print("FAIL: Shortcut key not set correctly")
		nav_button.queue_free()
		return false
	
	nav_button.queue_free()
	print("PASS: QuickNavButton creation and setup")
	return true

static func test_template_validation() -> bool:
	"""Test template validation system"""
	print("Testing template validation...")
	
	var results = UITemplates.validate_all_templates()
	
	for template_name in results.keys():
		if not results[template_name]:
			print("FAIL: Template validation failed for " + template_name)
			return false
		else:
			print("PASS: Template validation succeeded for " + template_name)
	
	return true

static func run_all_tests() -> bool:
	"""Run all UI component tests"""
	print("=== Running UI Component Tests ===")
	
	var all_passed = true
	
	all_passed = test_alert_item_creation() and all_passed
	all_passed = test_quick_nav_button_creation() and all_passed
	all_passed = test_template_validation() and all_passed
	
	if all_passed:
		print("=== ALL TESTS PASSED ===")
	else:
		print("=== SOME TESTS FAILED ===")
	
	return all_passed