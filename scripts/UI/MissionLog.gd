extends Control
class_name MissionLog

# Mission Log Panel - Track active and completed missions
# Based on views.md specification

signal mission_selected(mission_id: String)
signal mission_accepted(mission_id: String)
signal mission_abandoned(mission_id: String)

# UI References
@onready var mission_list: ItemList = $VBoxContainer/MissionContainer/MissionList
@onready var mission_details: RichTextLabel = $VBoxContainer/MissionContainer/HSplitContainer/MissionDetails
@onready var active_missions_tab: Button = $VBoxContainer/TabContainer/ActiveMissions
@onready var completed_missions_tab: Button = $VBoxContainer/TabContainer/CompletedMissions
@onready var available_missions_tab: Button = $VBoxContainer/TabContainer/AvailableMissions

# Game Manager reference
var game_manager: GameManager

# Mission data
var active_missions: Array[Dictionary] = []
var completed_missions: Array[Dictionary] = []
var available_missions: Array[Dictionary] = []
var selected_mission: Dictionary = {}

# Current tab
enum MissionTab {
	ACTIVE,
	COMPLETED,
	AVAILABLE
}
var current_tab: MissionTab = MissionTab.ACTIVE

func initialize(gm: GameManager):
	"""Initialize the mission log with game manager reference"""
	game_manager = gm
	
	# Connect to game manager signals
	if game_manager.has_signal("mission_added"):
		game_manager.mission_added.connect(_on_mission_added)
	if game_manager.has_signal("mission_completed"):
		game_manager.mission_completed.connect(_on_mission_completed)
	if game_manager.has_signal("mission_updated"):
		game_manager.mission_updated.connect(_on_mission_updated)
	
	# Setup UI
	_setup_ui()
	_load_missions()
	
	print("MissionLog: Initialized")

func _setup_ui():
	"""Setup the mission log UI"""
	# Connect tab buttons
	if active_missions_tab:
		active_missions_tab.pressed.connect(func(): _switch_tab(MissionTab.ACTIVE))
	if completed_missions_tab:
		completed_missions_tab.pressed.connect(func(): _switch_tab(MissionTab.COMPLETED))
	if available_missions_tab:
		available_missions_tab.pressed.connect(func(): _switch_tab(MissionTab.AVAILABLE))
	
	# Connect mission list
	if mission_list:
		mission_list.item_selected.connect(_on_mission_selected)
	
	# Set initial tab
	_switch_tab(MissionTab.ACTIVE)

func _load_missions():
	"""Load missions from game manager"""
	if not game_manager:
		return
	
	# Generate some sample missions for testing
	_generate_sample_missions()
	_refresh_mission_list()

func _generate_sample_missions():
	"""Generate sample missions for testing"""
	active_missions = [
		{
			"id": "trade_001",
			"title": "Cargo Run to Kepler",
			"description": "Transport 50 units of Food to Kepler system",
			"type": "trade",
			"status": "active",
			"progress": 0.6,
			"reward": 5000,
			"deadline": "2 days",
			"objectives": [
				{"text": "Load 50 Food units", "completed": true},
				{"text": "Travel to Kepler", "completed": false},
				{"text": "Deliver cargo", "completed": false}
			]
		},
		{
			"id": "explore_001",
			"title": "Survey Unknown System",
			"description": "Explore and map the Vega-7 system",
			"type": "exploration",
			"status": "active",
			"progress": 0.3,
			"reward": 8000,
			"deadline": "5 days",
			"objectives": [
				{"text": "Travel to Vega-7", "completed": true},
				{"text": "Scan 3 planets", "completed": false},
				{"text": "Report findings", "completed": false}
			]
		}
	]
	
	completed_missions = [
		{
			"id": "trade_completed_001",
			"title": "Ore Transport",
			"description": "Successfully delivered 100 units of Ore",
			"type": "trade",
			"status": "completed",
			"progress": 1.0,
			"reward": 3000,
			"completion_date": "Yesterday"
		}
	]
	
	available_missions = [
		{
			"id": "combat_001",
			"title": "Pirate Elimination",
			"description": "Clear pirate presence from trade routes",
			"type": "combat",
			"status": "available",
			"progress": 0.0,
			"reward": 12000,
			"difficulty": "Hard",
			"requirements": ["Combat Ship", "Level 5+"]
		},
		{
			"id": "trade_002",
			"title": "Medical Supply Run",
			"description": "Emergency medical supplies needed",
			"type": "trade",
			"status": "available",
			"progress": 0.0,
			"reward": 7000,
			"difficulty": "Medium",
			"requirements": ["Cargo Space: 30+"]
		}
	]

func _switch_tab(tab: MissionTab):
	"""Switch between mission tabs"""
	current_tab = tab
	
	# Update tab button states
	if active_missions_tab:
		active_missions_tab.button_pressed = (tab == MissionTab.ACTIVE)
	if completed_missions_tab:
		completed_missions_tab.button_pressed = (tab == MissionTab.COMPLETED)
	if available_missions_tab:
		available_missions_tab.button_pressed = (tab == MissionTab.AVAILABLE)
	
	_refresh_mission_list()

func _refresh_mission_list():
	"""Refresh the mission list based on current tab"""
	if not mission_list:
		return
	
	mission_list.clear()
	
	var missions_to_show: Array[Dictionary] = []
	match current_tab:
		MissionTab.ACTIVE:
			missions_to_show = active_missions
		MissionTab.COMPLETED:
			missions_to_show = completed_missions
		MissionTab.AVAILABLE:
			missions_to_show = available_missions
	
	for mission in missions_to_show:
		var item_text = _format_mission_item(mission)
		mission_list.add_item(item_text)
		
		# Color code by type
		var item_index = mission_list.get_item_count() - 1
		match mission.get("type", ""):
			"trade":
				mission_list.set_item_custom_bg_color(item_index, Color(0.2, 0.4, 0.2, 0.3))
			"exploration":
				mission_list.set_item_custom_bg_color(item_index, Color(0.2, 0.2, 0.4, 0.3))
			"combat":
				mission_list.set_item_custom_bg_color(item_index, Color(0.4, 0.2, 0.2, 0.3))

func _format_mission_item(mission: Dictionary) -> String:
	"""Format mission for list display"""
	var title = mission.get("title", "Unknown Mission")
	var reward = mission.get("reward", 0)
	var progress = mission.get("progress", 0.0)
	
	var status_text = ""
	match current_tab:
		MissionTab.ACTIVE:
			status_text = " [%d%%]" % (progress * 100)
		MissionTab.COMPLETED:
			status_text = " [DONE]"
		MissionTab.AVAILABLE:
			var difficulty = mission.get("difficulty", "")
			if difficulty != "":
				status_text = " [%s]" % difficulty
	
	return "%s - %d cr%s" % [title, reward, status_text]

func _on_mission_selected(index: int):
	"""Handle mission selection"""
	var missions_to_show: Array[Dictionary] = []
	match current_tab:
		MissionTab.ACTIVE:
			missions_to_show = active_missions
		MissionTab.COMPLETED:
			missions_to_show = completed_missions
		MissionTab.AVAILABLE:
			missions_to_show = available_missions
	
	if index >= 0 and index < missions_to_show.size():
		selected_mission = missions_to_show[index]
		_update_mission_details()
		mission_selected.emit(selected_mission.get("id", ""))

func _update_mission_details():
	"""Update mission details panel"""
	if not mission_details or selected_mission.is_empty():
		return
	
	var details_text = _format_mission_details(selected_mission)
	mission_details.text = details_text

func _format_mission_details(mission: Dictionary) -> String:
	"""Format detailed mission information"""
	var text = ""
	
	# Title and basic info
	text += "[font_size=18][color=cyan]%s[/color][/font_size]\n\n" % mission.get("title", "Unknown")
	text += "[b]Type:[/b] %s\n" % mission.get("type", "Unknown").capitalize()
	text += "[b]Reward:[/b] %d credits\n" % mission.get("reward", 0)
	text += "[b]Status:[/b] %s\n\n" % mission.get("status", "Unknown").capitalize()
	
	# Description
	text += "[b]Description:[/b]\n%s\n\n" % mission.get("description", "No description available")
	
	# Progress for active missions
	if mission.get("status") == "active":
		var progress = mission.get("progress", 0.0)
		text += "[b]Progress:[/b] %d%%\n" % (progress * 100)
		
		var deadline = mission.get("deadline", "")
		if deadline != "":
			text += "[b]Deadline:[/b] %s\n" % deadline
		
		# Objectives
		var objectives = mission.get("objectives", [])
		if objectives.size() > 0:
			text += "\n[b]Objectives:[/b]\n"
			for obj in objectives:
				var status_icon = "✓" if obj.get("completed", false) else "○"
				var color = "green" if obj.get("completed", false) else "white"
				text += "[color=%s]%s %s[/color]\n" % [color, status_icon, obj.get("text", "")]
	
	# Requirements for available missions
	elif mission.get("status") == "available":
		var difficulty = mission.get("difficulty", "")
		if difficulty != "":
			text += "[b]Difficulty:[/b] %s\n" % difficulty
		
		var requirements = mission.get("requirements", [])
		if requirements.size() > 0:
			text += "\n[b]Requirements:[/b]\n"
			for req in requirements:
				text += "• %s\n" % req
	
	# Completion info for completed missions
	elif mission.get("status") == "completed":
		var completion_date = mission.get("completion_date", "")
		if completion_date != "":
			text += "[b]Completed:[/b] %s\n" % completion_date
	
	return text

# Mission management methods
func accept_mission(mission_id: String):
	"""Accept an available mission"""
	for i in range(available_missions.size()):
		if available_missions[i].get("id") == mission_id:
			var mission = available_missions[i]
			mission["status"] = "active"
			mission["progress"] = 0.0
			
			active_missions.append(mission)
			available_missions.remove_at(i)
			
			mission_accepted.emit(mission_id)
			_refresh_mission_list()
			break

func abandon_mission(mission_id: String):
	"""Abandon an active mission"""
	for i in range(active_missions.size()):
		if active_missions[i].get("id") == mission_id:
			var mission = active_missions[i]
			mission["status"] = "available"
			mission["progress"] = 0.0
			
			available_missions.append(mission)
			active_missions.remove_at(i)
			
			mission_abandoned.emit(mission_id)
			_refresh_mission_list()
			break

func complete_mission(mission_id: String):
	"""Complete an active mission"""
	for i in range(active_missions.size()):
		if active_missions[i].get("id") == mission_id:
			var mission = active_missions[i]
			mission["status"] = "completed"
			mission["progress"] = 1.0
			mission["completion_date"] = "Today"
			
			completed_missions.append(mission)
			active_missions.remove_at(i)
			
			_refresh_mission_list()
			break

func update_mission_progress(mission_id: String, progress: float):
	"""Update mission progress"""
	for mission in active_missions:
		if mission.get("id") == mission_id:
			mission["progress"] = clamp(progress, 0.0, 1.0)
			
			# Auto-complete if progress reaches 100%
			if progress >= 1.0:
				complete_mission(mission_id)
			else:
				_refresh_mission_list()
			break

# Game Manager signal handlers
func _on_mission_added(mission_data: Dictionary):
	"""Handle new mission added"""
	available_missions.append(mission_data)
	if current_tab == MissionTab.AVAILABLE:
		_refresh_mission_list()

func _on_mission_completed(mission_id: String):
	"""Handle mission completion"""
	complete_mission(mission_id)

func _on_mission_updated(mission_id: String, updates: Dictionary):
	"""Handle mission updates"""
	# Update in active missions
	for mission in active_missions:
		if mission.get("id") == mission_id:
			for key in updates.keys():
				mission[key] = updates[key]
			_refresh_mission_list()
			return
	
	# Update in available missions
	for mission in available_missions:
		if mission.get("id") == mission_id:
			for key in updates.keys():
				mission[key] = updates[key]
			_refresh_mission_list()
			return

# Utility methods
func get_active_mission_count() -> int:
	"""Get number of active missions"""
	return active_missions.size()

func get_completed_mission_count() -> int:
	"""Get number of completed missions"""
	return completed_missions.size()

func get_available_mission_count() -> int:
	"""Get number of available missions"""
	return available_missions.size()

func get_mission_by_id(mission_id: String) -> Dictionary:
	"""Get mission data by ID"""
	# Check active missions
	for mission in active_missions:
		if mission.get("id") == mission_id:
			return mission
	
	# Check completed missions
	for mission in completed_missions:
		if mission.get("id") == mission_id:
			return mission
	
	# Check available missions
	for mission in available_missions:
		if mission.get("id") == mission_id:
			return mission
	
	return {}

func get_missions_by_type(mission_type: String) -> Array[Dictionary]:
	"""Get all missions of a specific type"""
	var filtered_missions: Array[Dictionary] = []
	
	for mission in active_missions + completed_missions + available_missions:
		if mission.get("type") == mission_type:
			filtered_missions.append(mission)
	
	return filtered_missions