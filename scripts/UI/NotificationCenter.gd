extends Control
class_name NotificationCenter

# Notification Center - Event notifications and alert prioritization
# Based on views.md: "Event notification feed, achievement system, alert prioritization"

# References
var game_manager: GameManager

# UI References
var notification_list: VBoxContainer
var filter_controls: HBoxContainer
var notification_scroll: ScrollContainer

# Notification data
var notifications: Array[Dictionary] = []
var max_notifications: int = 100
var current_filter: String = "all"  # "all", "trade", "travel", "discovery", "system"

# Notification types with priorities
var notification_priorities = {
	"critical": 5,
	"warning": 4,
	"trade": 3,
	"travel": 2,
	"info": 1,
	"discovery": 4,
	"system": 3
}

func _ready():
	print("NotificationCenter: Initializing...")
	_create_ui_elements()

func initialize(gm: GameManager):
	"""Initialize notification center with game manager reference"""
	game_manager = gm
	
	# Connect to various game signals for notifications
	if game_manager:
		game_manager.credits_changed.connect(_on_credits_changed)
		game_manager.location_changed.connect(_on_location_changed)
		game_manager.travel_started.connect(_on_travel_started)
		
		# Connect to system signals
		if game_manager.economy_system:
			game_manager.economy_system.trade_executed.connect(_on_trade_executed)
		if game_manager.artifact_system:
			game_manager.artifact_system.artifact_discovered.connect(_on_artifact_discovered)
		if game_manager.event_system:
			game_manager.event_system.event_triggered.connect(_on_event_triggered)
	
	# Add welcome notification
	add_notification("info", "Notification Center", "Welcome to Space Transport Tycoon! All game events will appear here.")
	
	print("NotificationCenter: Initialized with GameManager")

func _create_ui_elements():
	"""Create the notification center UI"""
	# Main container
	var main_container = VBoxContainer.new()
	main_container.anchors_preset = Control.PRESET_FULL_RECT
	main_container.offset_left = 10
	main_container.offset_right = -10
	main_container.offset_top = 10
	main_container.offset_bottom = -10
	add_child(main_container)
	
	# Title and controls
	var header_container = HBoxContainer.new()
	main_container.add_child(header_container)
	
	var title_label = Label.new()
	title_label.text = "Notification Center"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color.CYAN)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(title_label)
	
	# Clear button
	var clear_button = Button.new()
	clear_button.text = "Clear All"
	clear_button.custom_minimum_size = Vector2(80, 25)
	clear_button.pressed.connect(_clear_all_notifications)
	header_container.add_child(clear_button)
	
	# Filter controls
	filter_controls = HBoxContainer.new()
	main_container.add_child(filter_controls)
	
	var filter_label = Label.new()
	filter_label.text = "Filter: "
	filter_controls.add_child(filter_label)
	
	var filter_options = ["All", "Trade", "Travel", "Discovery", "System", "Critical"]
	for option in filter_options:
		var filter_button = Button.new()
		filter_button.text = option
		filter_button.toggle_mode = true
		filter_button.custom_minimum_size = Vector2(60, 25)
		if option == "All":
			filter_button.button_pressed = true
		filter_button.pressed.connect(_set_filter.bind(option.to_lower()))
		filter_controls.add_child(filter_button)
	
	# Notification list
	notification_scroll = ScrollContainer.new()
	notification_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(notification_scroll)
	
	notification_list = VBoxContainer.new()
	notification_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notification_scroll.add_child(notification_list)

func add_notification(type: String, title: String, message: String, data: Dictionary = {}):
	"""Add a new notification"""
	var notification = {
		"type": type,
		"title": title,
		"message": message,
		"timestamp": Time.get_time_string_from_system(),
		"data": data,
		"priority": notification_priorities.get(type, 1),
		"read": false
	}
	
	# Insert notification in priority order
	var inserted = false
	for i in range(notifications.size()):
		if notification.priority > notifications[i].priority:
			notifications.insert(i, notification)
			inserted = true
			break
	
	if not inserted:
		notifications.append(notification)
	
	# Remove old notifications if we exceed max
	while notifications.size() > max_notifications:
		notifications.remove_at(-1)
	
	_update_notification_display()
	
	# Auto-scroll to top for new notifications
	if notification_scroll:
		notification_scroll.scroll_vertical = 0

func _update_notification_display():
	"""Update the notification display"""
	if not notification_list:
		return
	
	# Clear existing notifications
	for child in notification_list.get_children():
		child.queue_free()
	
	# Filter notifications
	var filtered_notifications = []
	for notification in notifications:
		if current_filter == "all" or notification.type == current_filter:
			filtered_notifications.append(notification)
	
	# Display filtered notifications
	for notification in filtered_notifications:
		var notification_widget = _create_notification_widget(notification)
		notification_list.add_child(notification_widget)

func _create_notification_widget(notification: Dictionary) -> Control:
	"""Create a visual widget for a notification"""
	var widget = Panel.new()
	widget.custom_minimum_size = Vector2(0, 60)
	
	# Style based on type and priority
	var style_box = StyleBoxFlat.new()
	var base_color = _get_notification_color(notification.type)
	
	if not notification.read:
		style_box.bg_color = base_color
		style_box.bg_color.a = 0.3
	else:
		style_box.bg_color = base_color
		style_box.bg_color.a = 0.1
	
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	style_box.border_width_left = 3
	style_box.border_color = base_color
	
	widget.add_theme_stylebox_override("panel", style_box)
	
	# Content container
	var content_container = VBoxContainer.new()
	content_container.anchors_preset = Control.PRESET_FULL_RECT
	content_container.offset_left = 10
	content_container.offset_right = -10
	content_container.offset_top = 5
	content_container.offset_bottom = -5
	widget.add_child(content_container)
	
	# Header with title and timestamp
	var header_container = HBoxContainer.new()
	content_container.add_child(header_container)
	
	var icon = _get_notification_icon(notification.type)
	var title_label = Label.new()
	title_label.text = icon + " " + notification.title
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 12)
	if not notification.read:
		title_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		title_label.add_theme_color_override("font_color", Color.GRAY)
	header_container.add_child(title_label)
	
	var timestamp_label = Label.new()
	timestamp_label.text = notification.timestamp
	timestamp_label.add_theme_font_size_override("font_size", 10)
	timestamp_label.add_theme_color_override("font_color", Color.GRAY)
	timestamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_container.add_child(timestamp_label)
	
	# Message
	var message_label = Label.new()
	message_label.text = notification.message
	message_label.add_theme_font_size_override("font_size", 10)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not notification.read:
		message_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		message_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	content_container.add_child(message_label)
	
	# Mark as read when clicked
	var button = Button.new()
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.flat = true
	button.pressed.connect(_mark_notification_read.bind(notification))
	widget.add_child(button)
	
	return widget

func _get_notification_color(type: String) -> Color:
	"""Get color for notification type"""
	match type:
		"critical":
			return Color.RED
		"warning":
			return Color.ORANGE
		"trade":
			return Color.GOLD
		"travel":
			return Color.PURPLE
		"discovery":
			return Color.MAGENTA
		"system":
			return Color.BLUE
		"info":
			return Color.CYAN
		_:
			return Color.GRAY

func _get_notification_icon(type: String) -> String:
	"""Get icon for notification type"""
	match type:
		"critical":
			return "🚨"
		"warning":
			return "⚠"
		"trade":
			return "💰"
		"travel":
			return "🚀"
		"discovery":
			return "🔍"
		"system":
			return "🌟"
		"info":
			return "ℹ"
		_:
			return "•"

func _mark_notification_read(notification: Dictionary):
	"""Mark a notification as read"""
	notification.read = true
	_update_notification_display()

func _set_filter(filter_type: String):
	"""Set notification filter"""
	current_filter = filter_type
	
	# Update filter button states
	for child in filter_controls.get_children():
		if child is Button and child.toggle_mode:
			child.button_pressed = (child.text.to_lower() == filter_type)
	
	_update_notification_display()

func _clear_all_notifications():
	"""Clear all notifications"""
	notifications.clear()
	_update_notification_display()

# Game event handlers
func _on_credits_changed(new_credits: int):
	"""Handle credits change"""
	# Only notify on significant changes
	pass

func _on_location_changed(system_id: String):
	"""Handle location change"""
	if game_manager:
		var system_data = game_manager.economy_system.get_system_data(system_id)
		add_notification("travel", "Location Changed", "Arrived at " + system_data.get("name", system_id))

func _on_travel_started(from_system: String, to_system: String):
	"""Handle travel start"""
	add_notification("travel", "Travel Started", "Departing " + from_system + " for " + to_system)

func _on_trade_executed(system_id: String, good_type: String, quantity: int, is_buying: bool, profit: int):
	"""Handle trade execution"""
	var action = "Bought" if is_buying else "Sold"
	var message = action + " " + str(quantity) + " " + good_type + " for $" + str(abs(profit))
	add_notification("trade", "Trade Executed", message)

func _on_artifact_discovered(artifact_id: String, system_id: String, lore_fragment: String):
	"""Handle artifact discovery"""
	add_notification("discovery", "Artifact Discovered", "Found " + artifact_id.replace("_", " ") + " in " + system_id)

func _on_event_triggered(event_type: String, duration: float, effects: Dictionary):
	"""Handle dynamic event"""
	var message = "Galactic event active for " + str(int(duration)) + " seconds"
	add_notification("system", event_type.replace("_", " ").capitalize(), message)

# Public API
func get_unread_count() -> int:
	"""Get count of unread notifications"""
	var count = 0
	for notification in notifications:
		if not notification.read:
			count += 1
	return count

func get_notifications_by_type(type: String) -> Array:
	"""Get notifications of a specific type"""
	var filtered = []
	for notification in notifications:
		if notification.type == type:
			filtered.append(notification)
	return filtered

func mark_all_read():
	"""Mark all notifications as read"""
	for notification in notifications:
		notification.read = true
	_update_notification_display()