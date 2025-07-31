extends Control

# Test showcase for AlertItem component
# Demonstrates all alert types and their styling

@onready var alert_container: VBoxContainer = $VBoxContainer/AlertContainer

func _ready():
	"""Create showcase of all alert types"""
	_create_alert_samples()

func _create_alert_samples():
	"""Create sample alerts of each type"""
	var alert_types = [
		{"type": "info", "message": "Information alert - System status normal"},
		{"type": "warning", "message": "Warning alert - Low fuel detected"},
		{"type": "error", "message": "Error alert - Navigation system offline"},
		{"type": "success", "message": "Success alert - Trade completed successfully"},
		{"type": "trade", "message": "Trade alert - New market opportunity available"},
		{"type": "travel", "message": "Travel alert - Arrived at destination"},
		{"type": "discovery", "message": "Discovery alert - New planet discovered"}
	]
	
	for alert_data in alert_types:
		var alert_item = UITemplates.create_alert_item()
		if alert_item:
			alert_data["timestamp"] = "12:34"
			alert_data["duration"] = 0  # Don't auto-remove
			alert_item.setup_alert(alert_data)
			alert_container.add_child(alert_item)
			
			# Add some spacing
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 5)
			alert_container.add_child(spacer)