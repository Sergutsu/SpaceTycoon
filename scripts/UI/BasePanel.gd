extends Control
class_name BasePanel

# Base class for all UI panels following MVC architecture
# Provides common functionality and interface

# Panel properties
@export var panel_title: String = "Panel"
@export var can_minimize: bool = true
@export var can_close: bool = true
@export var is_modal: bool = false

# References
var game_manager: GameManager
var ui_manager: UIManager

# Panel state
var is_initialized: bool = false
var is_minimized: bool = false

# Common UI elements (optional - panels can override)
@onready var title_bar: Control = get_node_or_null("TitleBar")
@onready var content_area: Control = get_node_or_null("ContentArea")
@onready var minimize_button: Button = get_node_or_null("TitleBar/MinimizeButton")
@onready var close_button: Button = get_node_or_null("TitleBar/CloseButton")

func _ready():
	# Connect common UI elements if they exist
	if minimize_button:
		minimize_button.pressed.connect(_on_minimize_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func initialize(gm: GameManager):
	"""Initialize panel with game manager reference"""
	game_manager = gm
	ui_manager = get_parent() as UIManager
	
	# Call panel-specific initialization
	_on_panel_initialize()
	
	is_initialized = true
	print("BasePanel: ", panel_title, " initialized")

func _on_panel_initialize():
	"""Override in derived classes for specific initialization"""
	pass

func minimize():
	"""Minimize the panel (show only title bar)"""
	if not can_minimize:
		return
	
	is_minimized = true
	if content_area:
		content_area.visible = false
	
	_on_panel_minimized()

func restore():
	"""Restore panel from minimized state"""
	is_minimized = false
	if content_area:
		content_area.visible = true
	
	_on_panel_restored()

func close():
	"""Close the panel"""
	if not can_close:
		return
	
	if ui_manager:
		ui_manager.hide_panel(self)
	
	_on_panel_closed()

# Virtual methods for derived classes to override
func _on_panel_initialize():
	"""Called when panel is initialized"""
	pass

func _on_panel_minimized():
	"""Called when panel is minimized"""
	pass

func _on_panel_restored():
	"""Called when panel is restored"""
	pass

func _on_panel_closed():
	"""Called when panel is closed"""
	pass

func _on_panel_shown():
	"""Called when panel becomes visible"""
	pass

func _on_panel_hidden():
	"""Called when panel becomes hidden"""
	pass

# Common signal handlers
func _on_minimize_pressed():
	if is_minimized:
		restore()
	else:
		minimize()

func _on_close_pressed():
	close()

# Utility methods
func is_panel_initialized() -> bool:
	return is_initialized

func get_panel_title() -> String:
	return panel_title

func set_panel_title(title: String):
	panel_title = title
	if title_bar and title_bar.has_method("set_title"):
		title_bar.set_title(title)

# Data update methods (to be overridden by specific panels)
func update_credits(credits: int):
	"""Override to handle credits updates"""
	pass

func update_fuel(fuel: int):
	"""Override to handle fuel updates"""
	pass

func update_cargo(cargo: Dictionary):
	"""Override to handle cargo updates"""
	pass

func update_location(system_id: String):
	"""Override to handle location updates"""
	pass

func update_ship_stats(stats: Dictionary):
	"""Override to handle ship stats updates"""
	pass