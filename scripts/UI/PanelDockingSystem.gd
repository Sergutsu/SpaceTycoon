extends Control
class_name PanelDockingSystem

# Panel Docking System - Advanced drag-and-drop panel management
# Allows users to customize panel layouts with docking zones

signal panel_docked(panel: Control, dock_zone: String)
signal panel_undocked(panel: Control)
signal layout_changed()

# Docking zones
enum DockZone {
	NONE,
	LEFT,
	RIGHT,
	TOP,
	BOTTOM,
	CENTER,
	TAB_GROUP
}

# Docking configuration
var dock_zones: Dictionary = {}
var docked_panels: Dictionary = {}
var dock_zone_highlights: Dictionary = {}
var drag_preview: Control
var is_dragging: bool = false
var dragged_panel: Control

# Docking settings
var dock_zone_size: int = 100
var dock_highlight_color: Color = Color.CYAN
var dock_preview_color: Color = Color(0.0, 1.0, 1.0, 0.3)
var snap_threshold: int = 20

# UI Manager reference
var ui_manager: UIManager

func initialize(manager: UIManager):
	"""Initialize the docking system"""
	ui_manager = manager
	_setup_dock_zones()
	_create_drag_preview()
	
	print("PanelDockingSystem: Initialized")

func _setup_dock_zones():
	"""Setup docking zones around the screen"""
	# Create invisible dock zones
	dock_zones[DockZone.LEFT] = _create_dock_zone(Rect2(0, 0, dock_zone_size, size.y))
	dock_zones[DockZone.RIGHT] = _create_dock_zone(Rect2(size.x - dock_zone_size, 0, dock_zone_size, size.y))
	dock_zones[DockZone.TOP] = _create_dock_zone(Rect2(0, 0, size.x, dock_zone_size))
	dock_zones[DockZone.BOTTOM] = _create_dock_zone(Rect2(0, size.y - dock_zone_size, size.x, dock_zone_size))
	dock_zones[DockZone.CENTER] = _create_dock_zone(Rect2(size.x * 0.25, size.y * 0.25, size.x * 0.5, size.y * 0.5))

func _create_dock_zone(rect: Rect2) -> Control:
	"""Create a dock zone control"""
	var zone = Control.new()
	zone.position = rect.position
	zone.size = rect.size
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(zone)
	
	# Create highlight overlay (initially hidden)
	var highlight = ColorRect.new()
	highlight.color = dock_preview_color
	highlight.anchors_preset = Control.PRESET_FULL_RECT
	highlight.visible = false
	zone.add_child(highlight)
	
	return zone

func _create_drag_preview():
	"""Create drag preview overlay"""
	drag_preview = Panel.new()
	drag_preview.visible = false
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drag_preview)
	
	# Style the preview
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = dock_preview_color
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = dock_highlight_color
	drag_preview.add_theme_stylebox_override("panel", style_box)

func start_panel_drag(panel: Control, start_position: Vector2):
	"""Start dragging a panel"""
	if not panel or is_dragging:
		return
	
	is_dragging = true
	dragged_panel = panel
	
	# Show drag preview
	drag_preview.visible = true
	drag_preview.size = panel.size
	drag_preview.position = start_position
	
	# Bring preview to front
	move_child(drag_preview, get_child_count() - 1)
	
	print("PanelDockingSystem: Started dragging panel: ", panel.name)

func update_panel_drag(mouse_position: Vector2):
	"""Update panel drag position"""
	if not is_dragging or not drag_preview:
		return
	
	# Update preview position
	drag_preview.position = mouse_position - drag_preview.size * 0.5
	
	# Check for dock zone highlights
	_update_dock_zone_highlights(mouse_position)

func end_panel_drag(mouse_position: Vector2):
	"""End panel dragging and dock if in zone"""
	if not is_dragging:
		return
	
	var dock_zone = _get_dock_zone_at_position(mouse_position)
	
	if dock_zone != DockZone.NONE:
		_dock_panel(dragged_panel, dock_zone)
	else:
		# Free positioning
		_position_panel_freely(dragged_panel, mouse_position)
	
	# Cleanup
	is_dragging = false
	dragged_panel = null
	drag_preview.visible = false
	_hide_all_dock_highlights()
	
	layout_changed.emit()

func _update_dock_zone_highlights(mouse_position: Vector2):
	"""Update dock zone highlights based on mouse position"""
	_hide_all_dock_highlights()
	
	var zone = _get_dock_zone_at_position(mouse_position)
	if zone != DockZone.NONE and dock_zones.has(zone):
		var zone_control = dock_zones[zone]
		var highlight = zone_control.get_child(0)  # First child is the highlight
		if highlight:
			highlight.visible = true

func _hide_all_dock_highlights():
	"""Hide all dock zone highlights"""
	for zone in dock_zones.values():
		var highlight = zone.get_child(0)
		if highlight:
			highlight.visible = false

func _get_dock_zone_at_position(position: Vector2) -> DockZone:
	"""Get dock zone at the given position"""
	for zone_type in dock_zones.keys():
		var zone_control = dock_zones[zone_type]
		var zone_rect = Rect2(zone_control.global_position, zone_control.size)
		
		if zone_rect.has_point(position):
			return zone_type
	
	return DockZone.NONE

func _dock_panel(panel: Control, zone: DockZone):
	"""Dock a panel to a specific zone"""
	if not panel:
		return
	
	# Remove from previous dock if any
	_undock_panel(panel)
	
	# Calculate new position and size based on zone
	var new_rect = _calculate_dock_rect(zone)
	
	# Animate to new position
	var tween = create_tween()
	tween.parallel().tween_property(panel, "position", new_rect.position, 0.3)
	tween.parallel().tween_property(panel, "size", new_rect.size, 0.3)
	
	# Store docking information
	docked_panels[panel] = zone
	
	panel_docked.emit(panel, DockZone.keys()[zone])
	print("PanelDockingSystem: Docked panel ", panel.name, " to zone ", DockZone.keys()[zone])

func _undock_panel(panel: Control):
	"""Undock a panel"""
	if not panel or not docked_panels.has(panel):
		return
	
	docked_panels.erase(panel)
	panel_undocked.emit(panel)
	print("PanelDockingSystem: Undocked panel ", panel.name)

func _calculate_dock_rect(zone: DockZone) -> Rect2:
	"""Calculate the rectangle for a docked panel"""
	var margin = 10
	
	match zone:
		DockZone.LEFT:
			return Rect2(margin, margin, size.x * 0.3, size.y - margin * 2)
		DockZone.RIGHT:
			return Rect2(size.x * 0.7, margin, size.x * 0.3 - margin, size.y - margin * 2)
		DockZone.TOP:
			return Rect2(margin, margin, size.x - margin * 2, size.y * 0.3)
		DockZone.BOTTOM:
			return Rect2(margin, size.y * 0.7, size.x - margin * 2, size.y * 0.3 - margin)
		DockZone.CENTER:
			return Rect2(size.x * 0.25, size.y * 0.25, size.x * 0.5, size.y * 0.5)
		_:
			return Rect2(100, 100, 400, 300)  # Default size

func _position_panel_freely(panel: Control, position: Vector2):
	"""Position panel freely at mouse position"""
	if not panel:
		return
	
	# Ensure panel stays within screen bounds
	var new_position = position - panel.size * 0.5
	new_position.x = clamp(new_position.x, 0, size.x - panel.size.x)
	new_position.y = clamp(new_position.y, 0, size.y - panel.size.y)
	
	# Animate to new position
	var tween = create_tween()
	tween.tween_property(panel, "position", new_position, 0.2)

# Layout management
func save_layout() -> Dictionary:
	"""Save current docking layout"""
	var layout_data = {}
	
	for panel in docked_panels.keys():
		var panel_name = _get_panel_name(panel)
		if panel_name != "":
			layout_data[panel_name] = {
				"dock_zone": docked_panels[panel],
				"position": panel.position,
				"size": panel.size
			}
	
	return layout_data

func load_layout(layout_data: Dictionary):
	"""Load a docking layout"""
	# Clear current docking
	docked_panels.clear()
	
	for panel_name in layout_data.keys():
		var panel = ui_manager.get_panel_by_name(panel_name)
		if not panel:
			continue
		
		var panel_data = layout_data[panel_name]
		var zone = panel_data.get("dock_zone", DockZone.NONE)
		
		if zone != DockZone.NONE:
			docked_panels[panel] = zone
			panel.position = panel_data.get("position", Vector2.ZERO)
			panel.size = panel_data.get("size", Vector2(400, 300))
	
	layout_changed.emit()
	print("PanelDockingSystem: Layout loaded")

func get_docked_panels() -> Dictionary:
	"""Get all currently docked panels"""
	return docked_panels.duplicate()

func is_panel_docked(panel: Control) -> bool:
	"""Check if a panel is currently docked"""
	return docked_panels.has(panel)

func get_panel_dock_zone(panel: Control) -> DockZone:
	"""Get the dock zone of a panel"""
	return docked_panels.get(panel, DockZone.NONE)

func _get_panel_name(panel: Control) -> String:
	"""Get panel name from UI manager"""
	if ui_manager:
		return ui_manager._get_panel_name(panel)
	return ""

# Snap-to-grid functionality
var grid_size: int = 20
var snap_to_grid: bool = false

func enable_snap_to_grid(enabled: bool, grid_size_px: int = 20):
	"""Enable or disable snap-to-grid"""
	snap_to_grid = enabled
	grid_size = grid_size_px
	
	print("PanelDockingSystem: Snap-to-grid ", "enabled" if enabled else "disabled")

func snap_position_to_grid(position: Vector2) -> Vector2:
	"""Snap position to grid if enabled"""
	if not snap_to_grid:
		return position
	
	return Vector2(
		round(position.x / grid_size) * grid_size,
		round(position.y / grid_size) * grid_size
	)

# Tab group functionality
var tab_groups: Dictionary = {}

func create_tab_group(group_name: String, position: Vector2, size: Vector2) -> Control:
	"""Create a new tab group for panels"""
	var tab_container = TabContainer.new()
	tab_container.name = "TabGroup_" + group_name
	tab_container.position = position
	tab_container.size = size
	add_child(tab_container)
	
	tab_groups[group_name] = tab_container
	
	print("PanelDockingSystem: Created tab group: ", group_name)
	return tab_container

func add_panel_to_tab_group(panel: Control, group_name: String):
	"""Add a panel to a tab group"""
	if not tab_groups.has(group_name):
		print("PanelDockingSystem: Tab group not found: ", group_name)
		return
	
	var tab_container = tab_groups[group_name]
	
	# Remove panel from its current parent
	if panel.get_parent():
		panel.get_parent().remove_child(panel)
	
	# Add to tab container
	tab_container.add_child(panel)
	
	print("PanelDockingSystem: Added panel ", panel.name, " to tab group ", group_name)

func remove_panel_from_tab_group(panel: Control):
	"""Remove a panel from its tab group"""
	var parent = panel.get_parent()
	if parent and parent is TabContainer:
		parent.remove_child(panel)
		# Add back to main UI
		ui_manager.add_child(panel)
		
		print("PanelDockingSystem: Removed panel ", panel.name, " from tab group")

# Resize handles for docked panels
func add_resize_handles(panel: Control):
	"""Add resize handles to a panel"""
	if panel.has_meta("has_resize_handles"):
		return  # Already has handles
	
	var handles = []
	
	# Create resize handles for each corner and edge
	var handle_positions = [
		{"name": "top_left", "pos": Vector2(0, 0), "cursor": Control.CURSOR_FDIAGSIZE},
		{"name": "top_right", "pos": Vector2(1, 0), "cursor": Control.CURSOR_BDIAGSIZE},
		{"name": "bottom_left", "pos": Vector2(0, 1), "cursor": Control.CURSOR_BDIAGSIZE},
		{"name": "bottom_right", "pos": Vector2(1, 1), "cursor": Control.CURSOR_FDIAGSIZE},
		{"name": "top", "pos": Vector2(0.5, 0), "cursor": Control.CURSOR_VSIZE},
		{"name": "bottom", "pos": Vector2(0.5, 1), "cursor": Control.CURSOR_VSIZE},
		{"name": "left", "pos": Vector2(0, 0.5), "cursor": Control.CURSOR_HSIZE},
		{"name": "right", "pos": Vector2(1, 0.5), "cursor": Control.CURSOR_HSIZE}
	]
	
	for handle_data in handle_positions:
		var handle = _create_resize_handle(handle_data)
		panel.add_child(handle)
		handles.append(handle)
	
	panel.set_meta("resize_handles", handles)
	panel.set_meta("has_resize_handles", true)

func _create_resize_handle(handle_data: Dictionary) -> Control:
	"""Create a single resize handle"""
	var handle = Control.new()
	handle.name = "ResizeHandle_" + handle_data["name"]
	handle.size = Vector2(8, 8)
	handle.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Position the handle
	var pos = handle_data["pos"]
	handle.anchor_left = pos.x
	handle.anchor_right = pos.x
	handle.anchor_top = pos.y
	handle.anchor_bottom = pos.y
	
	if pos.x == 0:
		handle.offset_left = -4
		handle.offset_right = 4
	elif pos.x == 1:
		handle.offset_left = -4
		handle.offset_right = 4
	else:  # 0.5
		handle.offset_left = -4
		handle.offset_right = 4
	
	if pos.y == 0:
		handle.offset_top = -4
		handle.offset_bottom = 4
	elif pos.y == 1:
		handle.offset_top = -4
		handle.offset_bottom = 4
	else:  # 0.5
		handle.offset_top = -4
		handle.offset_bottom = 4
	
	# Style the handle
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.WHITE
	style_box.corner_radius_top_left = 2
	style_box.corner_radius_top_right = 2
	style_box.corner_radius_bottom_left = 2
	style_box.corner_radius_bottom_right = 2
	
	var color_rect = ColorRect.new()
	color_rect.color = Color.WHITE
	color_rect.anchors_preset = Control.PRESET_FULL_RECT
	handle.add_child(color_rect)
	
	# Set cursor
	handle.mouse_default_cursor_shape = handle_data["cursor"]
	
	return handle

func remove_resize_handles(panel: Control):
	"""Remove resize handles from a panel"""
	if not panel.has_meta("has_resize_handles"):
		return
	
	var handles = panel.get_meta("resize_handles", [])
	for handle in handles:
		if handle and is_instance_valid(handle):
			handle.queue_free()
	
	panel.remove_meta("resize_handles")
	panel.remove_meta("has_resize_handles")

# Auto-layout functionality
func auto_arrange_panels():
	"""Automatically arrange all panels in a grid"""
	var visible_panels = []
	
	# Get all visible panels
	for panel_name in ui_manager.get_all_panel_names():
		var panel = ui_manager.get_panel_by_name(panel_name)
		if panel and ui_manager.is_panel_visible(panel) and panel != ui_manager.hud:
			visible_panels.append(panel)
	
	if visible_panels.is_empty():
		return
	
	# Calculate grid layout
	var panel_count = visible_panels.size()
	var cols = ceil(sqrt(panel_count))
	var rows = ceil(panel_count / cols)
	
	var panel_width = (size.x - 40) / cols
	var panel_height = (size.y - 40) / rows
	
	# Position panels
	for i in range(panel_count):
		var panel = visible_panels[i]
		var col = i % cols
		var row = i / cols
		
		var new_position = Vector2(
			20 + col * panel_width,
			20 + row * panel_height
		)
		var new_size = Vector2(panel_width - 10, panel_height - 10)
		
		# Animate to new position
		var tween = create_tween()
		tween.parallel().tween_property(panel, "position", new_position, 0.5)
		tween.parallel().tween_property(panel, "size", new_size, 0.5)
	
	print("PanelDockingSystem: Auto-arranged ", panel_count, " panels")

func cascade_panels():
	"""Arrange panels in a cascading layout"""
	var visible_panels = []
	
	# Get all visible panels
	for panel_name in ui_manager.get_all_panel_names():
		var panel = ui_manager.get_panel_by_name(panel_name)
		if panel and ui_manager.is_panel_visible(panel) and panel != ui_manager.hud:
			visible_panels.append(panel)
	
	if visible_panels.is_empty():
		return
	
	var cascade_offset = Vector2(30, 30)
	var start_position = Vector2(50, 50)
	
	for i in range(visible_panels.size()):
		var panel = visible_panels[i]
		var new_position = start_position + cascade_offset * i
		
		# Keep within screen bounds
		if new_position.x + panel.size.x > size.x:
			new_position.x = 50
		if new_position.y + panel.size.y > size.y:
			new_position.y = 50
		
		# Animate to new position
		var tween = create_tween()
		tween.tween_property(panel, "position", new_position, 0.3)
	
	print("PanelDockingSystem: Cascaded ", visible_panels.size(), " panels")