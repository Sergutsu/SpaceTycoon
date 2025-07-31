extends Control
class_name UIManager

# UI Manager - Central controller for all UI panels following MVC architecture
# Based on views.md specification

# Panel References - only reference existing panels
@onready var hud: HUD = get_node_or_null("HUD")
@onready var main_status_panel: MainStatusPanel = get_node_or_null("MainStatusPanel")
@onready var galaxy_map_panel: Control = get_node_or_null("GalaxyMapPanel")
@onready var market_screen: Control = get_node_or_null("MarketScreen")
@onready var asset_management_panel: Control = get_node_or_null("AssetManagementPanel")
@onready var mission_log: Control = get_node_or_null("MissionLog")
@onready var notification_center: Control = get_node_or_null("NotificationCenter")

# Game Manager reference
var game_manager: GameManager

# Current active panel
var active_panel: Control
var panel_stack: Array[Control] = []

# Panel visibility states
enum PanelState {
	HIDDEN,
	VISIBLE,
	MINIMIZED,
	MODAL
}

var panel_states: Dictionary = {}

func _ready():
	print("UIManager: Initializing UI system...")
	
	# Get game manager reference
	game_manager = get_node("../GameManager")
	if not game_manager:
		push_error("UIManager: GameManager not found!")
		return
	
	# Initialize all panels
	_initialize_panels()
	
	# Connect to game manager signals
	_connect_game_signals()
	
	# Set initial panel states
	_setup_initial_layout()
	
	print("UIManager: UI system initialized")

func _initialize_panels():
	"""Initialize all UI panels with game manager reference"""
	var panels = [hud, main_status_panel, galaxy_map_panel, market_screen, 
				  asset_management_panel, mission_log, notification_center]
	
	for panel in panels:
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
	# Show essential panels that exist
	if hud:
		show_panel(hud)
	if main_status_panel:
		show_panel(main_status_panel)
	if galaxy_map_panel:
		show_panel(galaxy_map_panel)
	
	# Hide secondary panels initially
	if market_screen:
		hide_panel(market_screen)
	if asset_management_panel:
		hide_panel(asset_management_panel)
	if mission_log:
		hide_panel(mission_log)
	
	# Notification center always visible but minimized
	if notification_center:
		minimize_panel(notification_center)

# Panel Management Methods
func show_panel(panel: Control):
	"""Show a panel and update its state"""
	if not panel:
		return
	
	panel.visible = true
	panel_states[panel] = PanelState.VISIBLE
	
	# Bring to front if modal
	if panel_states[panel] == PanelState.MODAL:
		move_child(panel, get_child_count() - 1)

func hide_panel(panel: Control):
	"""Hide a panel and update its state"""
	if not panel:
		return
	
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
func switch_to_panel(panel: Control):
	"""Switch focus to a specific panel"""
	if active_panel:
		# Store current panel in stack
		panel_stack.push_back(active_panel)
	
	active_panel = panel
	show_panel(panel)

func go_back():
	"""Return to previous panel"""
	if panel_stack.is_empty():
		return
	
	var previous_panel = panel_stack.pop_back()
	if active_panel:
		hide_panel(active_panel)
	
	active_panel = previous_panel
	show_panel(previous_panel)

# Keyboard shortcuts
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_M:
				toggle_panel(market_screen)
			KEY_F:
				toggle_panel(asset_management_panel)
			KEY_J:
				toggle_panel(mission_log)
			KEY_N:
				toggle_panel(notification_center)
			KEY_ESCAPE:
				go_back()

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

# Debug Methods
func print_panel_states():
	"""Debug method to print all panel states"""
	print("UIManager: Panel States:")
	for panel in panel_states.keys():
		print("  ", panel.name, ": ", PanelState.keys()[panel_states[panel]])