extends Button
class_name QuickNavButton

# QuickNavButton - Individual navigation button component
# Replaces programmatic button creation with scene-based approach

signal panel_requested(panel_name: String)

var panel_name: String = ""
var shortcut_key: String = ""

func setup_button(key: String, label: String, target_panel: String):
	"""Configure the navigation button"""
	shortcut_key = key
	panel_name = target_panel
	
	# Set button text with key and label
	text = key + "\n" + label
	
	# Configure button appearance
	add_theme_font_size_override("font_size", 8)
	custom_minimum_size = Vector2(50, 30)
	
	# Connect the pressed signal
	if not pressed.is_connected(_on_button_pressed):
		pressed.connect(_on_button_pressed)

func _on_button_pressed():
	"""Handle button press"""
	if panel_name != "":
		panel_requested.emit(panel_name)

func get_panel_name() -> String:
	"""Get the target panel name"""
	return panel_name

func get_shortcut_key() -> String:
	"""Get the shortcut key"""
	return shortcut_key

func highlight_button(highlighted: bool):
	"""Highlight the button when its panel is active"""
	if highlighted:
		modulate = Color.YELLOW
	else:
		modulate = Color.WHITE