extends Node
class_name PanelStateManager

# Panel State Manager - Save and restore panel states
# Handles panel visibility, positions, and user preferences

# State data
var panel_states: Dictionary = {}
var save_file_path: String = "user://panel_states.save"

# Default panel states
var default_states = {
	"SimpleHUD": {"visible": true, "position": Vector2.ZERO},
	"MainStatusPanel": {"visible": false, "position": Vector2.ZERO},
	"MarketScreen": {"visible": false, "position": Vector2.ZERO},
	"AssetManagementPanel": {"visible": false, "position": Vector2.ZERO},
	"NotificationCenter": {"visible": false, "position": Vector2.ZERO},
	"GalaxyMapPanel": {"visible": true, "position": Vector2.ZERO}
}

func _ready():
	load_panel_states()

func save_panel_states():
	"""Save current panel states to file"""
	var save_file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(panel_states))
		save_file.close()
		print("PanelStateManager: Saved panel states")
	else:
		print("PanelStateManager: Failed to save panel states")

func load_panel_states():
	"""Load panel states from file"""
	if FileAccess.file_exists(save_file_path):
		var save_file = FileAccess.open(save_file_path, FileAccess.READ)
		if save_file:
			var json_string = save_file.get_as_text()
			save_file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				panel_states = json.data
				print("PanelStateManager: Loaded panel states")
			else:
				print("PanelStateManager: Failed to parse saved states, using defaults")
				panel_states = default_states.duplicate()
		else:
			print("PanelStateManager: Failed to open save file, using defaults")
			panel_states = default_states.duplicate()
	else:
		print("PanelStateManager: No save file found, using defaults")
		panel_states = default_states.duplicate()

func get_panel_state(panel_name: String) -> Dictionary:
	"""Get state for a specific panel"""
	return panel_states.get(panel_name, default_states.get(panel_name, {"visible": false, "position": Vector2.ZERO}))

func set_panel_state(panel_name: String, visible: bool, position: Vector2 = Vector2.ZERO):
	"""Set state for a specific panel"""
	if not panel_states.has(panel_name):
		panel_states[panel_name] = {}
	
	panel_states[panel_name]["visible"] = visible
	panel_states[panel_name]["position"] = position

func apply_states_to_panels(parent_node: Node):
	"""Apply saved states to all panels"""
	for panel_name in panel_states.keys():
		var panel = parent_node.get_node_or_null(panel_name)
		if panel:
			var state = panel_states[panel_name]
			panel.visible = state.get("visible", false)
			
			# Apply position if the panel supports it
			var position = state.get("position", Vector2.ZERO)
			if position != Vector2.ZERO and panel.has_method("set_position"):
				panel.position = position

func collect_current_states(parent_node: Node):
	"""Collect current states from all panels"""
	for panel_name in default_states.keys():
		var panel = parent_node.get_node_or_null(panel_name)
		if panel:
			var position = Vector2.ZERO
			if panel.has_method("get_position"):
				position = panel.position
			
			set_panel_state(panel_name, panel.visible, position)

func reset_to_defaults():
	"""Reset all panel states to defaults"""
	panel_states = default_states.duplicate()
	save_panel_states()

# Auto-save functionality
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Save states when the game is closing
		save_panel_states()