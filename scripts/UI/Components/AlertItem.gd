extends Panel
class_name AlertItem

# AlertItem - Individual alert component for the HUD
# Replaces programmatic alert creation with scene-based approach

@onready var alert_label: Label = $ContentContainer/AlertLabel
@onready var time_label: Label = $ContentContainer/TimeLabel

var alert_data: Dictionary = {}
var auto_remove_timer: Timer

func setup_alert(data: Dictionary):
	"""Configure alert with data"""
	alert_data = data
	
	var alert_type = data.get("type", "info")
	var message = data.get("message", "")
	var timestamp = data.get("timestamp", "")
	var duration = data.get("duration", 5.0)
	
	# Set up content
	var icon_text = _get_icon_for_type(alert_type)
	alert_label.text = icon_text + message
	time_label.text = timestamp.substr(0, 5) if timestamp.length() > 5 else timestamp
	
	# Apply styling based on type
	_apply_alert_styling(alert_type)
	
	# Set up auto-removal if duration > 0
	if duration > 0:
		_setup_auto_removal(duration)

func _get_icon_for_type(alert_type: String) -> String:
	"""Get icon text for alert type"""
	match alert_type:
		"warning":
			return "⚠ "
		"error":
			return "❌ "
		"info":
			return "ℹ "
		"success":
			return "✓ "
		"trade":
			return "💰 "
		"travel":
			return "🚀 "
		"discovery":
			return "🔍 "
		_:
			return "• "

func _apply_alert_styling(alert_type: String):
	"""Apply visual styling based on alert type"""
	var style_box = StyleBoxFlat.new()
	
	# Set colors based on alert type
	match alert_type:
		"warning":
			style_box.bg_color = Color(1.0, 0.6, 0.0, 0.9)  # Orange
		"error":
			style_box.bg_color = Color(0.8, 0.2, 0.2, 0.9)  # Red
		"info":
			style_box.bg_color = Color(0.2, 0.6, 1.0, 0.9)  # Blue
		"success":
			style_box.bg_color = Color(0.2, 0.8, 0.2, 0.9)  # Green
		"trade":
			style_box.bg_color = Color(0.8, 0.6, 0.2, 0.9)  # Gold
		"travel":
			style_box.bg_color = Color(0.4, 0.2, 0.8, 0.9)  # Purple
		"discovery":
			style_box.bg_color = Color(0.8, 0.4, 0.8, 0.9)  # Magenta
		_:
			style_box.bg_color = Color(0.5, 0.5, 0.5, 0.9)  # Gray
	
	# Enhanced styling
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.WHITE
	
	add_theme_stylebox_override("panel", style_box)
	
	# Set text colors
	alert_label.add_theme_color_override("font_color", Color.WHITE)
	time_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	
	# Set font sizes
	alert_label.add_theme_font_size_override("font_size", 11)
	time_label.add_theme_font_size_override("font_size", 9)

func _setup_auto_removal(duration: float):
	"""Set up automatic removal after duration"""
	auto_remove_timer = Timer.new()
	auto_remove_timer.wait_time = duration
	auto_remove_timer.one_shot = true
	auto_remove_timer.timeout.connect(_on_auto_remove_timeout)
	add_child(auto_remove_timer)
	auto_remove_timer.start()

func _on_auto_remove_timeout():
	"""Handle automatic removal"""
	queue_free()

func remove_alert():
	"""Manually remove the alert"""
	if auto_remove_timer:
		auto_remove_timer.stop()
	queue_free()

func get_alert_type() -> String:
	"""Get the alert type"""
	return alert_data.get("type", "info")

func get_alert_message() -> String:
	"""Get the alert message"""
	return alert_data.get("message", "")

func update_message(new_message: String):
	"""Update the alert message"""
	alert_data["message"] = new_message
	var icon_text = _get_icon_for_type(alert_data.get("type", "info"))
	alert_label.text = icon_text + new_message