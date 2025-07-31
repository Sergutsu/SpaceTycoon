extends Control
class_name UIManager

# UI Manager - Central controller for all UI panels following MVC architecture
# Based on views.md specification

# Panel References - only reference existing panels
@onready var hud: Control = get_node_or_null("HUD")
@onready var main_status_panel: Control = get_node_or_null("MainStatusPanel")
@onready var galaxy_map_panel: Control = get_node_or_null("Galaxy3DScene")  # Reference to 3D scene
@onready var market_screen: Control = get_node_or_null("MarketScreen")
@onready var asset_management_panel: Control = get_node_or_null("AssetManagementPanel")
@onready var mission_log: Control = get_node_or_null("MissionLog")
@onready var notification_center: Control = get_node_or_null("NotificationCenter")

# Game Manager reference
var game_manager: GameManager

# Navigation system
var active_panel: Control
var panel_stack: Array[Control] = []
var panel_history: Array[String] = []
var max_history_length: int = 10

# Panel visibility states
enum PanelState {
	HIDDEN,
	VISIBLE,
	MINIMIZED,
	MODAL
}

var panel_states: Dictionary = {}

# Panel registry for easy access
var panel_registry: Dictionary = {}

# Navigation shortcuts
var navigation_shortcuts: Dictionary = {
	KEY_TAB: "main_status_panel",
	KEY_M: "market_screen", 
	KEY_F: "asset_management_panel",
	KEY_N: "notification_center",
	KEY_G: "galaxy_map_panel",
	KEY_L: "mission_log",
	KEY_H: "help_overlay"
}

# Animation and visual settings
var panel_transition_duration: float = 0.3
var panel_fade_duration: float = 0.2
var use_animations: bool = true

func _ready():
	print("UIManager: Initializing UI system...")
	
	# Get game manager reference
	game_manager = get_node("../GameManager")
	if not game_manager:
		push_error("UIManager: GameManager not found!")
		return
	
	# Build panel registry
	_build_panel_registry()
	
	# Initialize all panels
	_initialize_panels()
	
	# Connect to game manager signals
	_connect_game_signals()
	
	# Set initial panel states
	_setup_initial_layout()
	
	print("UIManager: UI system initialized")

func _build_panel_registry():
	"""Build registry of all available panels"""
	panel_registry = {
		"hud": hud,
		"main_status_panel": main_status_panel,
		"galaxy_map_panel": get_node("../Galaxy3DScene"),  # 3D scene is sibling
		"market_screen": market_screen,
		"asset_management_panel": asset_management_panel,
		"mission_log": mission_log,
		"notification_center": notification_center
	}
	
	# Remove null entries
	var keys_to_remove = []
	for panel_key in panel_registry.keys():
		if not panel_registry[panel_key]:
			keys_to_remove.append(panel_key)
	
	for panel_key in keys_to_remove:
		panel_registry.erase(panel_key)

func _initialize_panels():
	"""Initialize all UI panels with game manager reference"""
	for panel_name in panel_registry.keys():
		var panel = panel_registry[panel_name]
		if panel and panel.has_method("initialize"):
			panel.initialize(game_manager)
			panel_states[panel] = PanelState.HIDDEN
		elif panel:
			# For panels that don't have initialize method yet
			panel_states[panel] = PanelState.HIDDEN

func _connect_game_signals():
	"""Connect to GameManager signals for UI updates"""
	game_manager.credits_changed.connect(_on_credits_changed)
	game_manager.fuel_changed.connect(_on_fuel_changed)
	game_manager.cargo_changed.connect(_on_cargo_changed)
	game_manager.location_changed.connect(_on_location_changed)
	game_manager.ship_stats_updated.connect(_on_ship_stats_updated)

func _setup_initial_layout():
	"""Set up the initial UI layout"""
	# Apply themes to all panels
	for panel_name in panel_registry.keys():
		var panel = panel_registry[panel_name]
		if panel:
			apply_panel_theme(panel, "default")
	
	# Show essential panels that exist (without animation for initial setup)
	if hud:
		show_panel(hud, false)
	if main_status_panel:
		show_panel(main_status_panel, false)
	if galaxy_map_panel:
		show_panel(galaxy_map_panel, false)
	
	# Hide secondary panels initially
	if market_screen:
		hide_panel(market_screen, false)
	if asset_management_panel:
		hide_panel(asset_management_panel, false)
	if mission_log:
		hide_panel(mission_log, false)
	
	# Notification center always visible but minimized
	if notification_center:
		minimize_panel(notification_center)
	
	# Set initial active panel
	active_panel = main_status_panel if main_status_panel else hud
	
	# Initial performance optimization
	_optimize_panel_performance()
	
	print("UIManager: Initial layout configured with themes applied")

# Panel Management Methods
func show_panel(panel: Control, animate: bool = true):
	"""Show a panel and update its state"""
	if not panel:
		return
	
	panel.visible = true
	panel_states[panel] = PanelState.VISIBLE
	
	# Bring to front if modal
	if panel_states[panel] == PanelState.MODAL:
		move_child(panel, get_child_count() - 1)
	
	# Animate panel appearance
	if animate and use_animations:
		_animate_panel_show(panel)

func hide_panel(panel: Control, animate: bool = true):
	"""Hide a panel and update its state"""
	if not panel:
		return
	
	if animate and use_animations:
		_animate_panel_hide(panel)
	else:
		panel.visible = false
		panel_states[panel] = PanelState.HIDDEN

func minimize_panel(panel: Control):
	"""Minimize a panel (show only header/title bar)"""
	if not panel:
		return
	
	panel.visible = true
	panel_states[panel] = PanelState.MINIMIZED
	
	# Call panel's minimize method if it exists
	if panel.has_method("minimize"):
		panel.minimize()

func toggle_panel(panel: Control):
	"""Toggle panel visibility"""
	if not panel:
		return
	
	if panel_states[panel] == PanelState.VISIBLE:
		hide_panel(panel)
	else:
		show_panel(panel)

func show_modal_panel(panel: Control):
	"""Show panel as modal (blocks other interactions)"""
	if not panel:
		return
	
	panel.visible = true
	panel_states[panel] = PanelState.MODAL
	move_child(panel, get_child_count() - 1)

# Panel Navigation
func switch_to_panel(panel: Control, add_to_history: bool = true, animate: bool = true):
	"""Switch focus to a specific panel"""
	if not panel:
		return
	
	# Add current panel to history if switching to different panel
	if active_panel and active_panel != panel and add_to_history:
		_add_to_panel_history(active_panel)
		panel_stack.push_back(active_panel)
	
	var previous_panel = active_panel
	
	# Use smooth transition if both panels exist and animations are enabled
	if previous_panel and previous_panel != hud and previous_panel != panel and animate and use_animations:
		_animate_panel_transition(previous_panel, panel)
	else:
		# Hide current active panel if it's not the HUD
		if previous_panel and previous_panel != hud and previous_panel != panel:
			hide_panel(previous_panel, animate)
		
		show_panel(panel, animate)
	
	active_panel = panel
	
	# Update HUD navigation status
	_update_hud_navigation_status()
	
	# Optimize performance
	_optimize_panel_performance()
	_update_panel_visibility_optimization()
	
	print("UIManager: Switched to panel: ", panel.name)

func switch_to_panel_by_name(panel_name: String):
	"""Switch to panel by name"""
	var panel = panel_registry.get(panel_name)
	if panel:
		switch_to_panel(panel)
	else:
		print("UIManager: Panel not found: ", panel_name)

func go_back():
	"""Return to previous panel"""
	if panel_stack.is_empty():
		print("UIManager: No previous panel to return to")
		return
	
	var previous_panel = panel_stack.pop_back()
	if active_panel and active_panel != hud:
		hide_panel(active_panel)
	
	active_panel = previous_panel
	show_panel(previous_panel)
	
	# Update HUD navigation status
	_update_hud_navigation_status()
	
	print("UIManager: Returned to previous panel: ", previous_panel.name)

func _add_to_panel_history(panel: Control):
	"""Add panel to navigation history"""
	if not panel:
		return
	
	var panel_name = _get_panel_name(panel)
	if panel_name == "":
		return
	
	# Remove if already in history to avoid duplicates
	panel_history.erase(panel_name)
	
	# Add to front of history
	panel_history.push_front(panel_name)
	
	# Limit history size
	if panel_history.size() > max_history_length:
		panel_history.resize(max_history_length)

func _get_panel_name(panel: Control) -> String:
	"""Get panel name from registry"""
	for name in panel_registry.keys():
		if panel_registry[name] == panel:
			return name
	return ""

func get_panel_history() -> Array[String]:
	"""Get panel navigation history"""
	return panel_history.duplicate()

func clear_panel_history():
	"""Clear panel navigation history"""
	panel_history.clear()
	panel_stack.clear()

# Enhanced keyboard navigation
func _input(event):
	if event is InputEventKey and event.pressed:
		# Handle Ctrl combinations first
		if event.ctrl_pressed:
			match event.keycode:
				KEY_W:
					_close_current_panel()
					return
				KEY_TAB:
					if event.shift_pressed:
						_switch_to_previous_panel()
					else:
						_switch_to_next_panel()
					return
		
		# Handle navigation shortcuts
		if navigation_shortcuts.has(event.keycode):
			var panel_name = navigation_shortcuts[event.keycode]
			if panel_name == "help_overlay":
				_toggle_help_overlay()
			else:
				toggle_panel_by_name(panel_name)
			return
		
		# Handle special keys
		match event.keycode:
			KEY_ESCAPE:
				_handle_escape_key()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
				_handle_number_key(event.keycode)
			KEY_QUOTELEFT:  # Backtick key for console/debug
				_toggle_debug_panel()

func _handle_escape_key():
	"""Handle escape key - close modals or go back"""
	# First, try to close any modal panels
	for panel in panel_states.keys():
		if panel_states[panel] == PanelState.MODAL:
			hide_panel(panel)
			return
	
	# If no modals, go back in navigation
	go_back()

func _handle_number_key(keycode: int):
	"""Handle number keys for quick panel access"""
	var panel_index = keycode - KEY_1  # Convert to 0-based index
	var panel_names = panel_registry.keys()
	
	if panel_index < panel_names.size():
		var panel_name = panel_names[panel_index]
		switch_to_panel_by_name(panel_name)

func toggle_panel_by_name(panel_name: String):
	"""Toggle panel visibility by name"""
	var panel = panel_registry.get(panel_name)
	if panel:
		toggle_panel(panel)
	else:
		print("UIManager: Panel not found: ", panel_name)

func _close_current_panel():
	"""Close the currently active panel (Ctrl+W)"""
	if active_panel and active_panel != hud:
		hide_panel(active_panel)
		go_back()

func _switch_to_next_panel():
	"""Switch to next panel in registry (Ctrl+Tab)"""
	var panel_names = panel_registry.keys()
	if panel_names.size() <= 1:
		return
	
	var current_name = _get_panel_name(active_panel) if active_panel else ""
	var current_index = panel_names.find(current_name)
	
	var next_index = (current_index + 1) % panel_names.size()
	var next_panel_name = panel_names[next_index]
	
	switch_to_panel_by_name(next_panel_name)

func _switch_to_previous_panel():
	"""Switch to previous panel in registry (Ctrl+Shift+Tab)"""
	var panel_names = panel_registry.keys()
	if panel_names.size() <= 1:
		return
	
	var current_name = _get_panel_name(active_panel) if active_panel else ""
	var current_index = panel_names.find(current_name)
	
	var prev_index = (current_index - 1 + panel_names.size()) % panel_names.size()
	var prev_panel_name = panel_names[prev_index]
	
	switch_to_panel_by_name(prev_panel_name)

# Game Event Handlers
func _on_credits_changed(new_credits: int):
	"""Handle credits change - update relevant panels"""
	if hud and hud.has_method("update_credits"):
		hud.update_credits(new_credits)
	if main_status_panel and main_status_panel.has_method("update_credits"):
		main_status_panel.update_credits(new_credits)

func _on_fuel_changed(new_fuel: int):
	"""Handle fuel change - update relevant panels"""
	if hud and hud.has_method("update_fuel"):
		hud.update_fuel(new_fuel)
	if main_status_panel and main_status_panel.has_method("update_fuel"):
		main_status_panel.update_fuel(new_fuel)

func _on_cargo_changed(cargo_dict: Dictionary):
	"""Handle cargo change - update relevant panels"""
	if hud and hud.has_method("update_cargo"):
		hud.update_cargo(cargo_dict)
	if asset_management_panel and asset_management_panel.has_method("update_cargo"):
		asset_management_panel.update_cargo(cargo_dict)

func _on_location_changed(system_id: String):
	"""Handle location change - update relevant panels"""
	if galaxy_map_panel and galaxy_map_panel.has_method("update_location"):
		galaxy_map_panel.update_location(system_id)
	if market_screen and market_screen.has_method("update_location"):
		market_screen.update_location(system_id)

func _on_ship_stats_updated(stats: Dictionary):
	"""Handle ship stats update - update relevant panels"""
	if asset_management_panel and asset_management_panel.has_method("update_ship_stats"):
		asset_management_panel.update_ship_stats(stats)

# Utility Methods
func get_panel_state(panel: Control) -> PanelState:
	"""Get current state of a panel"""
	return panel_states.get(panel, PanelState.HIDDEN)

func is_panel_visible(panel: Control) -> bool:
	"""Check if panel is currently visible"""
	return panel_states.get(panel, PanelState.HIDDEN) == PanelState.VISIBLE

func get_active_panel() -> Control:
	"""Get currently active panel"""
	return active_panel

func get_panel_by_name(panel_name: String) -> Control:
	"""Get panel by name"""
	return panel_registry.get(panel_name)

func get_all_panel_names() -> Array[String]:
	"""Get all available panel names"""
	return panel_registry.keys()

func close_all_panels():
	"""Close all panels except HUD"""
	var closed_count = 0
	for panel in panel_states.keys():
		if panel != hud and panel_states[panel] == PanelState.VISIBLE:
			hide_panel(panel)
			closed_count += 1
	
	# Clear navigation state
	active_panel = hud
	panel_stack.clear()
	
	print("UIManager: Closed ", closed_count, " panels")
	return closed_count

func focus_panel(panel: Control):
	"""Focus a panel (bring to front without changing visibility)"""
	if not panel or not panel.visible:
		return
	
	# Move to front in z-order
	move_child(panel, get_child_count() - 1)
	active_panel = panel

# Navigation breadcrumbs
func get_navigation_breadcrumbs() -> Array[String]:
	"""Get navigation breadcrumbs for UI display"""
	var breadcrumbs: Array[String] = []
	
	# Add current panel
	if active_panel:
		var current_name = _get_panel_name(active_panel)
		if current_name != "":
			breadcrumbs.append(current_name.replace("_", " ").capitalize())
	
	# Add previous panels from stack (limited)
	var stack_limit = min(3, panel_stack.size())
	for i in range(stack_limit):
		var panel = panel_stack[panel_stack.size() - 1 - i]
		var panel_name = _get_panel_name(panel)
		if panel_name != "":
			breadcrumbs.append(panel_name.replace("_", " ").capitalize())
	
	return breadcrumbs

# Panel state management
func save_panel_states() -> Dictionary:
	"""Save current panel states for restoration"""
	var saved_states = {}
	for panel in panel_states.keys():
		var panel_name = _get_panel_name(panel)
		if panel_name != "":
			saved_states[panel_name] = {
				"state": panel_states[panel],
				"visible": panel.visible,
				"position": panel.position,
				"size": panel.size
			}
	
	saved_states["active_panel"] = _get_panel_name(active_panel) if active_panel else ""
	saved_states["panel_history"] = panel_history.duplicate()
	
	return saved_states

func restore_panel_states(saved_states: Dictionary):
	"""Restore panel states from saved data"""
	for panel_name in saved_states.keys():
		if panel_name in ["active_panel", "panel_history"]:
			continue
		
		var panel = panel_registry.get(panel_name)
		if not panel:
			continue
		
		var state_data = saved_states[panel_name]
		panel_states[panel] = state_data.get("state", PanelState.HIDDEN)
		panel.visible = state_data.get("visible", false)
		
		if state_data.has("position"):
			panel.position = state_data["position"]
		if state_data.has("size"):
			panel.size = state_data["size"]
	
	# Restore active panel
	var active_panel_name = saved_states.get("active_panel", "")
	if active_panel_name != "":
		active_panel = panel_registry.get(active_panel_name)
	
	# Restore history
	if saved_states.has("panel_history"):
		panel_history = saved_states["panel_history"]
	
	print("UIManager: Panel states restored")

# Auto-save panel states
func auto_save_panel_states():
	"""Automatically save panel states to user preferences"""
	var saved_states = save_panel_states()
	
	# In a real implementation, this would save to a file or user preferences
	# For now, we'll just store it in a class variable
	if not has_meta("auto_saved_states"):
		set_meta("auto_saved_states", saved_states)
	
	print("UIManager: Panel states auto-saved")

func auto_restore_panel_states():
	"""Automatically restore panel states from user preferences"""
	if has_meta("auto_saved_states"):
		var saved_states = get_meta("auto_saved_states")
		restore_panel_states(saved_states)
		print("UIManager: Panel states auto-restored")

# Panel layout presets
func save_layout_preset(preset_name: String):
	"""Save current layout as a named preset"""
	var preset_data = save_panel_states()
	
	if not has_meta("layout_presets"):
		set_meta("layout_presets", {})
	
	var presets = get_meta("layout_presets")
	presets[preset_name] = preset_data
	set_meta("layout_presets", presets)
	
	print("UIManager: Layout preset '%s' saved" % preset_name)

func load_layout_preset(preset_name: String) -> bool:
	"""Load a named layout preset"""
	if not has_meta("layout_presets"):
		print("UIManager: No layout presets found")
		return false
	
	var presets = get_meta("layout_presets")
	if not presets.has(preset_name):
		print("UIManager: Layout preset '%s' not found" % preset_name)
		return false
	
	var preset_data = presets[preset_name]
	restore_panel_states(preset_data)
	
	print("UIManager: Layout preset '%s' loaded" % preset_name)
	return true

func get_available_presets() -> Array[String]:
	"""Get list of available layout presets"""
	if not has_meta("layout_presets"):
		return []
	
	var presets = get_meta("layout_presets")
	return presets.keys()

func delete_layout_preset(preset_name: String) -> bool:
	"""Delete a layout preset"""
	if not has_meta("layout_presets"):
		return false
	
	var presets = get_meta("layout_presets")
	if not presets.has(preset_name):
		return false
	
	presets.erase(preset_name)
	set_meta("layout_presets", presets)
	
	print("UIManager: Layout preset '%s' deleted" % preset_name)
	return true

# Additional helper methods
func _toggle_help_overlay():
	"""Toggle help overlay with navigation shortcuts"""
	var help_overlay = get_node_or_null("HelpOverlay")
	
	if not help_overlay:
		_create_help_overlay()
		help_overlay = get_node("HelpOverlay")
	
	if help_overlay.visible:
		hide_panel(help_overlay)
	else:
		show_modal_panel(help_overlay)

func _create_help_overlay():
	"""Create help overlay with navigation shortcuts"""
	var help_overlay = Panel.new()
	help_overlay.name = "HelpOverlay"
	help_overlay.anchors_preset = Control.PRESET_CENTER
	help_overlay.offset_left = -300
	help_overlay.offset_top = -200
	help_overlay.offset_right = 300
	help_overlay.offset_bottom = 200
	help_overlay.visible = false
	add_child(help_overlay)
	
	# Style the help overlay
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.CYAN
	help_overlay.add_theme_stylebox_override("panel", style_box)
	
	var help_container = VBoxContainer.new()
	help_container.anchors_preset = Control.PRESET_FULL_RECT
	help_container.offset_left = 20
	help_container.offset_right = -20
	help_container.offset_top = 20
	help_container.offset_bottom = -20
	help_overlay.add_child(help_container)
	
	# Title
	var title_label = Label.new()
	title_label.text = "Navigation & Keyboard Shortcuts"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color.CYAN)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_container.add_child(title_label)
	
	# Shortcuts
	var shortcuts = [
		["TAB", "Main Status Panel"],
		["M", "Market Screen"],
		["F", "Asset Management"],
		["N", "Notification Center"],
		["G", "Galaxy Map"],
		["L", "Mission Log"],
		["H", "This Help"],
		["ESC", "Go Back / Close"],
		["1-9", "Quick Panel Access"],
		["`", "Debug Panel"],
		["", ""],
		["Navigation:", ""],
		["ESC", "Close modals or go back"],
		["Numbers", "Quick access to panels"],
		["Ctrl+W", "Close current panel"],
		["Ctrl+Tab", "Next panel"],
		["Ctrl+Shift+Tab", "Previous panel"],
		["", ""],
		["Panel Controls:", ""],
		["Click title", "Focus panel"],
		["Drag title", "Move panel"],
		["Double-click", "Minimize/restore"],
		["Right-click", "Panel context menu"]
	]
	
	for shortcut in shortcuts:
		var shortcut_container = HBoxContainer.new()
		help_container.add_child(shortcut_container)
		
		var key_label = Label.new()
		key_label.text = shortcut[0]
		key_label.custom_minimum_size = Vector2(80, 0)
		key_label.add_theme_color_override("font_color", Color.YELLOW)
		key_label.add_theme_font_size_override("font_size", 12)
		shortcut_container.add_child(key_label)
		
		var desc_label = Label.new()
		desc_label.text = shortcut[1]
		desc_label.add_theme_font_size_override("font_size", 12)
		if shortcut[1].ends_with(":"):
			desc_label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			desc_label.add_theme_color_override("font_color", Color.WHITE)
		shortcut_container.add_child(desc_label)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "Close (ESC)"
	close_button.custom_minimum_size = Vector2(0, 30)
	close_button.pressed.connect(func(): hide_panel(help_overlay))
	help_container.add_child(close_button)

func _toggle_debug_panel():
	"""Toggle debug panel for development"""
	var debug_panel = get_node_or_null("DebugPanel")
	
	if not debug_panel:
		_create_debug_panel()
		debug_panel = get_node("DebugPanel")
	
	toggle_panel(debug_panel)

func _create_debug_panel():
	"""Create debug panel for development"""
	var debug_panel = Panel.new()
	debug_panel.name = "DebugPanel"
	debug_panel.anchors_preset = Control.PRESET_TOP_LEFT
	debug_panel.offset_left = 10
	debug_panel.offset_top = 100
	debug_panel.offset_right = 300
	debug_panel.offset_bottom = 400
	debug_panel.visible = false
	add_child(debug_panel)
	
	var debug_container = VBoxContainer.new()
	debug_container.anchors_preset = Control.PRESET_FULL_RECT
	debug_container.offset_left = 10
	debug_container.offset_right = -10
	debug_container.offset_top = 10
	debug_container.offset_bottom = -10
	debug_panel.add_child(debug_container)
	
	var title_label = Label.new()
	title_label.text = "Debug Panel"
	title_label.add_theme_color_override("font_color", Color.RED)
	debug_container.add_child(title_label)
	
	var state_button = Button.new()
	state_button.text = "Print Panel States"
	state_button.pressed.connect(print_panel_states)
	debug_container.add_child(state_button)
	
	var history_button = Button.new()
	history_button.text = "Print Navigation History"
	history_button.pressed.connect(func(): print("Navigation History: ", panel_history))
	debug_container.add_child(history_button)

func _update_hud_navigation_status():
	"""Update HUD with current navigation status"""
	if hud and hud.has_method("update_navigation_status"):
		var panel_name = _get_panel_name(active_panel) if active_panel else ""
		hud.update_navigation_status(panel_name)

# Animation Methods
func _animate_panel_show(panel: Control):
	"""Animate panel showing with fade in"""
	panel.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, panel_fade_duration)
	tween.tween_callback(func(): print("Panel shown: ", panel.name))

func _animate_panel_hide(panel: Control):
	"""Animate panel hiding with fade out"""
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, panel_fade_duration)
	tween.tween_callback(func(): 
		panel.visible = false
		panel_states[panel] = PanelState.HIDDEN
		panel.modulate.a = 1.0  # Reset for next show
	)

func _animate_panel_transition(from_panel: Control, to_panel: Control):
	"""Animate smooth transition between panels"""
	if not from_panel or not to_panel:
		return
	
	# Slide out current panel
	var from_tween = create_tween()
	from_tween.parallel().tween_property(from_panel, "position:x", -from_panel.size.x, panel_transition_duration)
	from_tween.parallel().tween_property(from_panel, "modulate:a", 0.0, panel_transition_duration)
	
	# Slide in new panel
	to_panel.position.x = to_panel.size.x
	to_panel.modulate.a = 0.0
	to_panel.visible = true
	
	var to_tween = create_tween()
	to_tween.parallel().tween_property(to_panel, "position:x", 0.0, panel_transition_duration)
	to_tween.parallel().tween_property(to_panel, "modulate:a", 1.0, panel_transition_duration)
	
	# Cleanup after animation
	from_tween.tween_callback(func():
		from_panel.visible = false
		from_panel.position.x = 0  # Reset position
		from_panel.modulate.a = 1.0  # Reset alpha
		panel_states[from_panel] = PanelState.HIDDEN
	)

# Performance Optimization Methods
func _optimize_panel_performance():
	"""Optimize panel performance by managing visibility and updates"""
	for panel in panel_states.keys():
		if panel_states[panel] == PanelState.HIDDEN:
			# Disable processing for hidden panels
			if panel.has_method("set_process_mode"):
				panel.set_process_mode(Node.PROCESS_MODE_DISABLED)
		else:
			# Enable processing for visible panels
			if panel.has_method("set_process_mode"):
				panel.set_process_mode(Node.PROCESS_MODE_INHERIT)

func _update_panel_visibility_optimization():
	"""Update panel visibility optimization based on current state"""
	var visible_panel_count = 0
	
	for panel in panel_states.keys():
		if panel_states[panel] == PanelState.VISIBLE:
			visible_panel_count += 1
	
	# If too many panels are visible, suggest closing some
	if visible_panel_count > 4:
		print("UIManager: Performance warning - %d panels visible" % visible_panel_count)
		_suggest_panel_cleanup()

func _suggest_panel_cleanup():
	"""Suggest closing less important panels for performance"""
	var suggestion_text = "Consider closing some panels for better performance:\n"
	var closable_panels = []
	
	for panel in panel_states.keys():
		if panel_states[panel] == PanelState.VISIBLE and panel != hud and panel != active_panel:
			var panel_name = _get_panel_name(panel)
			if panel_name != "":
				closable_panels.append(panel_name)
	
	if closable_panels.size() > 0:
		suggestion_text += "• " + "\n• ".join(closable_panels)
		print("UIManager: ", suggestion_text)

# Theme and Visual Polish Methods
func apply_panel_theme(panel: Control, theme_name: String = "default"):
	"""Apply visual theme to a panel"""
	if not panel:
		return
	
	match theme_name:
		"default":
			_apply_default_theme(panel)
		"dark":
			_apply_dark_theme(panel)
		"minimal":
			_apply_minimal_theme(panel)

func _apply_default_theme(panel: Control):
	"""Apply default theme to panel"""
	if panel is Panel:
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.1, 0.1, 0.2, 0.9)
		style_box.corner_radius_top_left = 8
		style_box.corner_radius_top_right = 8
		style_box.corner_radius_bottom_left = 8
		style_box.corner_radius_bottom_right = 8
		style_box.border_width_left = 1
		style_box.border_width_right = 1
		style_box.border_width_top = 1
		style_box.border_width_bottom = 1
		style_box.border_color = Color.CYAN
		panel.add_theme_stylebox_override("panel", style_box)

func _apply_dark_theme(panel: Control):
	"""Apply dark theme to panel"""
	if panel is Panel:
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.05, 0.05, 0.1, 0.95)
		style_box.corner_radius_top_left = 4
		style_box.corner_radius_top_right = 4
		style_box.corner_radius_bottom_left = 4
		style_box.corner_radius_bottom_right = 4
		style_box.border_width_left = 2
		style_box.border_width_right = 2
		style_box.border_width_top = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color.GRAY
		panel.add_theme_stylebox_override("panel", style_box)

func _apply_minimal_theme(panel: Control):
	"""Apply minimal theme to panel"""
	if panel is Panel:
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.0, 0.0, 0.0, 0.7)
		style_box.corner_radius_top_left = 0
		style_box.corner_radius_top_right = 0
		style_box.corner_radius_bottom_left = 0
		style_box.corner_radius_bottom_right = 0
		style_box.border_width_left = 0
		style_box.border_width_right = 0
		style_box.border_width_top = 1
		style_box.border_width_bottom = 0
		style_box.border_color = Color.WHITE
		panel.add_theme_stylebox_override("panel", style_box)

# Debug Methods
func print_panel_states():
	"""Debug method to print all panel states"""
	print("UIManager: Panel States:")
	for panel in panel_states.keys():
		var panel_name = _get_panel_name(panel)
		print("  ", panel_name, " (", panel.name, "): ", PanelState.keys()[panel_states[panel]])
	
	print("Active Panel: ", _get_panel_name(active_panel) if active_panel else "None")
	print("Panel Stack: ", panel_stack.size(), " panels")
	print("Navigation History: ", panel_history)

func print_performance_stats():
	"""Print performance statistics"""
	var visible_count = 0
	var hidden_count = 0
	var minimized_count = 0
	
	for panel in panel_states.keys():
		match panel_states[panel]:
			PanelState.VISIBLE:
				visible_count += 1
			PanelState.HIDDEN:
				hidden_count += 1
			PanelState.MINIMIZED:
				minimized_count += 1
	
	print("UIManager Performance Stats:")
	print("  Visible panels: ", visible_count)
	print("  Hidden panels: ", hidden_count)
	print("  Minimized panels: ", minimized_count)
	print("  Total panels: ", panel_states.size())
	print("  Navigation stack depth: ", panel_stack.size())