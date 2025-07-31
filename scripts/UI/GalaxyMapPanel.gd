extends Control
class_name GalaxyMapPanel

# Galaxy Map Panel - Enhanced 3D galaxy interface with overlays and controls
# Integrates with existing Galaxy3DScene

# References
var game_manager: GameManager
var galaxy_3d_scene: Node3D
var info_overlay: Panel
var travel_controls: Panel
var system_info_label: Label

# State
var selected_system: String = ""
var is_travel_mode: bool = false

func _ready():
	print("GalaxyMapPanel: Initializing...")
	
	# Get game manager reference
	game_manager = get_node("../../GameManager")
	
	# Find the Galaxy3DScene
	galaxy_3d_scene = get_node("../../Galaxy3DScene")
	
	if galaxy_3d_scene:
		print("GalaxyMapPanel: Connected to Galaxy3DScene")
		_setup_ui_overlays()
		_connect_galaxy_signals()
	else:
		print("GalaxyMapPanel: Galaxy3DScene not found")

func _setup_ui_overlays():
	"""Create UI overlays for the 3D galaxy"""
	# System information overlay (top left)
	info_overlay = Panel.new()
	info_overlay.anchors_preset = Control.PRESET_TOP_LEFT
	info_overlay.offset_right = 300
	info_overlay.offset_bottom = 150
	info_overlay.offset_left = 10
	info_overlay.offset_top = 10
	info_overlay.visible = false
	add_child(info_overlay)
	
	# System info content
	var info_container = VBoxContainer.new()
	info_container.anchors_preset = Control.PRESET_FULL_RECT
	info_container.offset_left = 10
	info_container.offset_right = -10
	info_container.offset_top = 10
	info_container.offset_bottom = -10
	info_overlay.add_child(info_container)
	
	system_info_label = Label.new()
	system_info_label.text = "System Information"
	system_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(system_info_label)
	
	# Travel controls (bottom center)
	travel_controls = Panel.new()
	travel_controls.anchors_preset = Control.PRESET_BOTTOM_WIDE
	travel_controls.offset_left = 200
	travel_controls.offset_right = -200
	travel_controls.offset_top = -60
	travel_controls.offset_bottom = -10
	travel_controls.visible = false
	add_child(travel_controls)
	
	# Travel controls content
	var travel_container = HBoxContainer.new()
	travel_container.anchors_preset = Control.PRESET_FULL_RECT
	travel_container.offset_left = 10
	travel_container.offset_right = -10
	travel_container.offset_top = 10
	travel_container.offset_bottom = -10
	travel_container.alignment = BoxContainer.ALIGNMENT_CENTER
	travel_controls.add_child(travel_container)
	
	# Travel button
	var travel_button = Button.new()
	travel_button.text = "Travel Here"
	travel_button.custom_minimum_size = Vector2(100, 30)
	travel_button.pressed.connect(_on_travel_button_pressed)
	travel_container.add_child(travel_button)
	
	# Cancel button
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(80, 30)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	travel_container.add_child(cancel_button)
	
	# Instructions overlay (bottom left)
	var instructions_label = Label.new()
	instructions_label.anchors_preset = Control.PRESET_BOTTOM_LEFT
	instructions_label.offset_left = 10
	instructions_label.offset_top = -80
	instructions_label.offset_right = 250
	instructions_label.offset_bottom = -50
	instructions_label.text = "Left-drag: Orbit | Wheel: Zoom | Right-click: Info"
	instructions_label.add_theme_font_size_override("font_size", 10)
	instructions_label.modulate = Color(0.8, 0.8, 0.8)
	add_child(instructions_label)

func _connect_galaxy_signals():
	"""Connect to Galaxy3D signals if available"""
	if galaxy_3d_scene and galaxy_3d_scene.has_signal("planet_selected"):
		galaxy_3d_scene.planet_selected.connect(_on_planet_selected)
	if galaxy_3d_scene and galaxy_3d_scene.has_signal("planet_hovered"):
		galaxy_3d_scene.planet_hovered.connect(_on_planet_hovered)

func _input(event):
	"""Handle input events for galaxy interaction"""
	if not visible:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_handle_right_click(event.position)

func _handle_right_click(screen_pos: Vector2):
	"""Handle right-click for system information"""
	# This would need integration with the 3D scene's raycast system
	# For now, show info for currently selected system
	if selected_system != "":
		_show_system_info(selected_system)

func _on_planet_selected(system_id: String):
	"""Handle planet selection from 3D galaxy"""
	selected_system = system_id
	_show_system_info(system_id)
	_show_travel_controls(system_id)
	
	# Add HUD alert
	var hud = get_node("../SimpleHUD")
	if hud and hud.has_method("add_alert"):
		hud.add_alert("info", "Selected system: " + system_id, 2.0)

func _on_planet_hovered(system_id: String):
	"""Handle planet hover from 3D galaxy"""
	# Could show quick info tooltip here
	pass

func _show_system_info(system_id: String):
	"""Display detailed system information"""
	if not game_manager or not system_info_label:
		return
	
	var system_data = game_manager.economy_system.get_system_data(system_id)
	var info_text = ""
	
	info_text += "System: " + system_data.get("name", system_id) + "\n"
	info_text += "Type: " + system_data.get("type", "Unknown").capitalize() + "\n"
	info_text += "Risk Level: " + system_data.get("risk_level", "Unknown").capitalize() + "\n"
	
	# Add special features
	var features = system_data.get("special_features", [])
	if features.size() > 0:
		info_text += "Features: " + ", ".join(features).replace("_", " ") + "\n"
	
	# Add travel information
	if system_id != game_manager.player_data.current_system:
		var destinations = game_manager.get_available_destinations()
		for dest in destinations:
			if dest["id"] == system_id:
				info_text += "\nTravel Cost: " + str(dest["fuel_cost"]) + " fuel"
				info_text += "\nCan Travel: " + ("Yes" if dest["can_travel"] else "No")
				break
	else:
		info_text += "\nCurrent Location"
	
	system_info_label.text = info_text
	info_overlay.visible = true

func _show_travel_controls(system_id: String):
	"""Show travel controls for selected system"""
	if system_id == game_manager.player_data.current_system:
		travel_controls.visible = false
		return
	
	# Check if travel is possible
	var destinations = game_manager.get_available_destinations()
	var can_travel = false
	
	for dest in destinations:
		if dest["id"] == system_id:
			can_travel = dest["can_travel"]
			break
	
	if can_travel:
		travel_controls.visible = true
		is_travel_mode = true
	else:
		travel_controls.visible = false

func _on_travel_button_pressed():
	"""Handle travel button press"""
	if selected_system != "" and game_manager:
		var result = game_manager.travel_to_system(selected_system)
		
		var hud = get_node("../SimpleHUD")
		if hud and hud.has_method("add_alert"):
			if result.success:
				hud.add_alert("success", "Traveling to " + selected_system, 3.0)
			else:
				hud.add_alert("error", "Travel failed: " + result.error, 4.0)
		
		_hide_travel_controls()

func _on_cancel_button_pressed():
	"""Handle cancel button press"""
	_hide_travel_controls()
	_hide_system_info()

func _hide_travel_controls():
	"""Hide travel controls"""
	travel_controls.visible = false
	is_travel_mode = false

func _hide_system_info():
	"""Hide system information"""
	info_overlay.visible = false
	selected_system = ""

# Public API
func focus_on_system(system_id: String):
	"""Focus the 3D view on a specific system"""
	if galaxy_3d_scene and galaxy_3d_scene.has_method("focus_camera_on_planet"):
		galaxy_3d_scene.focus_camera_on_planet(system_id)

func reset_view():
	"""Reset the 3D view to default position"""
	if galaxy_3d_scene and galaxy_3d_scene.has_method("reset_camera_view"):
		galaxy_3d_scene.reset_camera_view()

func get_selected_system() -> String:
	"""Get currently selected system"""
	return selected_system

# Keyboard shortcuts
func handle_shortcut(key: int):
	"""Handle keyboard shortcuts"""
	match key:
		KEY_ESCAPE:
			_hide_travel_controls()
			_hide_system_info()
		KEY_R:
			reset_view()
		KEY_SPACE:
			if selected_system != "":
				focus_on_system(selected_system)