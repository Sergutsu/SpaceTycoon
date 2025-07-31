extends RefCounted
class_name UITemplates

# UITemplates - Centralized template loading and instantiation
# Provides factory methods for creating UI components from scene templates

# Template paths
const ALERT_ITEM = preload("res://scenes/UI/HUD/AlertItem.tscn")
const QUICK_NAV_BUTTON = preload("res://scenes/UI/HUD/QuickNavButton.tscn")

# Factory methods for common UI components
static func create_alert_item() -> AlertItem:
	"""Create a new AlertItem instance"""
	var instance = ALERT_ITEM.instantiate()
	if not instance is AlertItem:
		push_error("UITemplates: AlertItem template did not create AlertItem instance")
		return null
	return instance

static func create_quick_nav_button() -> QuickNavButton:
	"""Create a new QuickNavButton instance"""
	var instance = QUICK_NAV_BUTTON.instantiate()
	if not instance is QuickNavButton:
		push_error("UITemplates: QuickNavButton template did not create QuickNavButton instance")
		return null
	return instance

# Generic template instantiation with validation
static func instantiate_template(template_path: String) -> Node:
	"""Safely instantiate a template from path"""
	var template = load(template_path)
	if not template:
		push_error("UITemplates: Failed to load template: " + template_path)
		return null
	
	var instance = template.instantiate()
	if not instance:
		push_error("UITemplates: Failed to instantiate template: " + template_path)
		return null
	
	return instance

# Template validation
static func validate_template(template_path: String) -> bool:
	"""Validate that a template can be loaded and instantiated"""
	var template = load(template_path)
	if not template:
		return false
	
	# Try to instantiate and immediately free to test validity
	var test_instance = template.instantiate()
	if test_instance:
		test_instance.queue_free()
		return true
	
	return false

# Batch template validation for debugging
static func validate_all_templates() -> Dictionary:
	"""Validate all known templates and return results"""
	var results = {}
	
	var templates = {
		"AlertItem": "res://scenes/UI/HUD/AlertItem.tscn",
		"QuickNavButton": "res://scenes/UI/HUD/QuickNavButton.tscn"
	}
	
	for template_name in templates.keys():
		var template_path = templates[template_name]
		results[template_name] = validate_template(template_path)
		
		if not results[template_name]:
			push_error("UITemplates: Template validation failed: " + template_name + " at " + template_path)
	
	return results