extends Panel
class_name ProgressionPanel

# UI References
@onready var tab_container: TabContainer = $VBoxContainer/TabContainer
@onready var statistics_container: VBoxContainer = $VBoxContainer/TabContainer/Statistics/ScrollContainer/StatisticsContainer
@onready var achievements_container: VBoxContainer = $VBoxContainer/TabContainer/Achievements/ScrollContainer/AchievementsContainer
@onready var goals_container: VBoxContainer = $VBoxContainer/TabContainer/Goals/ScrollContainer/GoalsContainer

# Game Manager reference
var game_manager: GameManager

# Achievement notification dialog
var achievement_notification: AcceptDialog

func _ready():
	# Get game manager reference
	game_manager = get_node("../../GameManager")
	
	# Create achievement notification dialog
	_create_achievement_notification()
	
	# Connect to progression system signals
	game_manager.progression_system.achievement_unlocked.connect(_on_achievement_unlocked)
	game_manager.progression_system.milestone_reached.connect(_on_milestone_reached)
	game_manager.progression_system.statistics_updated.connect(_on_statistics_updated)
	
	# Initial display update
	_update_all_displays()

func _create_achievement_notification():
	achievement_notification = AcceptDialog.new()
	achievement_notification.title = "Achievement Unlocked!"
	achievement_notification.size = Vector2(400, 300)
	
	var vbox = VBoxContainer.new()
	
	var achievement_icon = Label.new()
	achievement_icon.name = "AchievementIcon"
	achievement_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievement_icon.add_theme_font_size_override("font_size", 32)
	
	var achievement_name = Label.new()
	achievement_name.name = "AchievementName"
	achievement_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievement_name.add_theme_font_size_override("font_size", 18)
	
	var achievement_description = Label.new()
	achievement_description.name = "AchievementDescription"
	achievement_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	achievement_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	achievement_description.add_theme_font_size_override("font_size", 12)
	
	var reward_label = Label.new()
	reward_label.name = "RewardLabel"
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 14)
	reward_label.modulate = Color.GOLD
	
	vbox.add_child(achievement_icon)
	vbox.add_child(achievement_name)
	vbox.add_child(achievement_description)
	vbox.add_child(reward_label)
	
	achievement_notification.add_child(vbox)
	add_child(achievement_notification)

func _update_all_displays():
	_update_statistics_display()
	_update_achievements_display()
	_update_goals_display()

func _update_statistics_display():
	# Clear existing statistics
	for child in statistics_container.get_children():
		child.queue_free()
	
	var stats_data = game_manager.get_statistics_display()
	
	# Core Statistics Section
	_create_statistics_section("Core Statistics", stats_data["core_stats"])
	
	# Progression Statistics Section
	_create_statistics_section("Progression", stats_data["progression_stats"])
	
	# Efficiency Statistics Section
	_create_statistics_section("Efficiency", stats_data["efficiency_stats"])
	
	# Session Summary Section
	if not stats_data["session_summary"].is_empty():
		_create_session_summary_section(stats_data["session_summary"])

func _create_statistics_section(section_name: String, stats: Dictionary):
	# Section header
	var header = Label.new()
	header.text = section_name
	header.add_theme_font_size_override("font_size", 16)
	header.modulate = Color.CYAN
	statistics_container.add_child(header)
	
	# Statistics items
	for stat_name in stats.keys():
		var stat_container = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = stat_name + ":"
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var value_label = Label.new()
		value_label.text = str(stats[stat_name])
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.modulate = Color.WHITE
		
		stat_container.add_child(name_label)
		stat_container.add_child(value_label)
		statistics_container.add_child(stat_container)
	
	# Add separator
	var separator = HSeparator.new()
	statistics_container.add_child(separator)

func _create_session_summary_section(session_data: Dictionary):
	var header = Label.new()
	header.text = "This Session"
	header.add_theme_font_size_override("font_size", 16)
	header.modulate = Color.GREEN
	statistics_container.add_child(header)
	
	var session_stats = {
		"Session Duration": _format_time(session_data.get("session_duration", 0)),
		"Credits Earned": str(session_data.get("credits_earned_this_session", 0)),
		"Trades Completed": str(session_data.get("trades_this_session", 0)),
		"Systems Explored": str(session_data.get("systems_explored_this_session", 0)),
		"Artifacts Found": str(session_data.get("artifacts_found_this_session", 0)),
		"Achievements Unlocked": str(session_data.get("achievements_unlocked_this_session", 0))
	}
	
	for stat_name in session_stats.keys():
		var stat_container = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = stat_name + ":"
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var value_label = Label.new()
		value_label.text = session_stats[stat_name]
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.modulate = Color.LIGHT_GREEN
		
		stat_container.add_child(name_label)
		stat_container.add_child(value_label)
		statistics_container.add_child(stat_container)

func _update_achievements_display():
	# Clear existing achievements
	for child in achievements_container.get_children():
		child.queue_free()
	
	var achievement_data = game_manager.get_achievement_progress()
	
	# Show unlocked achievements first
	if not achievement_data["unlocked"].is_empty():
		var unlocked_header = Label.new()
		unlocked_header.text = "Unlocked Achievements (" + str(achievement_data["unlocked"].size()) + ")"
		unlocked_header.add_theme_font_size_override("font_size", 16)
		unlocked_header.modulate = Color.GOLD
		achievements_container.add_child(unlocked_header)
		
		for achievement in achievement_data["unlocked"]:
			var achievement_item = _create_achievement_item(achievement, true)
			achievements_container.add_child(achievement_item)
		
		var separator = HSeparator.new()
		achievements_container.add_child(separator)
	
	# Show available achievements
	if not achievement_data["available"].is_empty():
		var available_header = Label.new()
		available_header.text = "Available Achievements (" + str(achievement_data["available"].size()) + ")"
		available_header.add_theme_font_size_override("font_size", 16)
		available_header.modulate = Color.LIGHT_GRAY
		achievements_container.add_child(available_header)
		
		# Sort available achievements by progress
		achievement_data["available"].sort_custom(func(a, b): return a["progress_percentage"] > b["progress_percentage"])
		
		for achievement in achievement_data["available"]:
			var achievement_item = _create_achievement_item(achievement, false)
			achievements_container.add_child(achievement_item)

func _create_achievement_item(achievement: Dictionary, is_unlocked: bool) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	
	# Achievement header
	var header_container = HBoxContainer.new()
	
	var icon_label = Label.new()
	icon_label.text = achievement["icon"]
	icon_label.add_theme_font_size_override("font_size", 20)
	
	var name_label = Label.new()
	name_label.text = achievement["name"]
	name_label.add_theme_font_size_override("font_size", 14)
	if is_unlocked:
		name_label.modulate = Color.GOLD
	else:
		name_label.modulate = Color.WHITE
	
	var category_label = Label.new()
	category_label.text = "[" + achievement["category"].capitalize() + "]"
	category_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	category_label.add_theme_font_size_override("font_size", 10)
	category_label.modulate = Color.LIGHT_GRAY
	
	header_container.add_child(icon_label)
	header_container.add_child(name_label)
	header_container.add_child(category_label)
	
	# Description
	var description_label = Label.new()
	description_label.text = achievement["description"]
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 11)
	description_label.modulate = Color.LIGHT_GRAY
	
	# Progress bar (for available achievements)
	if not is_unlocked:
		var progress_container = HBoxContainer.new()
		
		var progress_bar = ProgressBar.new()
		progress_bar.min_value = 0
		progress_bar.max_value = 100
		progress_bar.value = achievement["progress_percentage"]
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_bar.custom_minimum_size.y = 20
		
		var progress_label = Label.new()
		progress_label.text = str(achievement["current_progress"]) + "/" + str(achievement["requirement_value"])
		progress_label.add_theme_font_size_override("font_size", 10)
		
		progress_container.add_child(progress_bar)
		progress_container.add_child(progress_label)
		container.add_child(progress_container)
	else:
		# Reward display for unlocked achievements
		var reward_label = Label.new()
		var reward_text = _format_achievement_reward(achievement["reward_type"], achievement["reward_value"])
		reward_label.text = "Reward: " + reward_text
		reward_label.add_theme_font_size_override("font_size", 10)
		reward_label.modulate = Color.GREEN
		container.add_child(reward_label)
	
	# Add components
	container.add_child(header_container)
	container.add_child(description_label)
	
	# Add separator
	var separator = HSeparator.new()
	container.add_child(separator)
	
	return container

func _update_goals_display():
	# Clear existing goals
	for child in goals_container.get_children():
		child.queue_free()
	
	var goals = game_manager.get_next_goals()
	
	if goals.is_empty():
		var no_goals_label = Label.new()
		no_goals_label.text = "All current goals completed!\nKeep playing to unlock more achievements."
		no_goals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_goals_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		no_goals_label.modulate = Color.LIGHT_GRAY
		goals_container.add_child(no_goals_label)
		return
	
	var header = Label.new()
	header.text = "Next Goals"
	header.add_theme_font_size_override("font_size", 16)
	header.modulate = Color.CYAN
	goals_container.add_child(header)
	
	for goal in goals:
		var goal_item = _create_goal_item(goal)
		goals_container.add_child(goal_item)

func _create_goal_item(goal: Dictionary) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	
	# Goal header
	var header_container = HBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = goal["name"]
	name_label.add_theme_font_size_override("font_size", 13)
	
	var type_label = Label.new()
	type_label.text = "[" + goal["type"].capitalize() + "]"
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.modulate = Color.LIGHT_BLUE
	
	header_container.add_child(name_label)
	header_container.add_child(type_label)
	
	# Description
	var description_label = Label.new()
	description_label.text = goal["description"]
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 10)
	description_label.modulate = Color.LIGHT_GRAY
	
	# Progress
	var progress_container = HBoxContainer.new()
	
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = goal["progress_percentage"]
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.custom_minimum_size.y = 16
	
	var progress_label = Label.new()
	progress_label.text = str(goal["progress"]) + "/" + str(goal["target"])
	progress_label.add_theme_font_size_override("font_size", 9)
	
	progress_container.add_child(progress_bar)
	progress_container.add_child(progress_label)
	
	# Add components
	container.add_child(header_container)
	container.add_child(description_label)
	container.add_child(progress_container)
	
	# Add separator
	var separator = HSeparator.new()
	container.add_child(separator)
	
	return container

# Signal handlers
func _on_achievement_unlocked(achievement_id: String, achievement_data: Dictionary):
	# Show achievement notification
	_show_achievement_notification(achievement_data)
	
	# Update achievements display
	_update_achievements_display()
	_update_goals_display()

@warning_ignore("unused_parameter")
func _on_milestone_reached(milestone_id: String, milestone_data: Dictionary):
	# Update goals display
	_update_goals_display()

@warning_ignore("unused_parameter")
func _on_statistics_updated(stat_name: String, new_value):
	# Update statistics display
	_update_statistics_display()

func _show_achievement_notification(achievement_data: Dictionary):
	var icon_label = achievement_notification.get_node("VBoxContainer/AchievementIcon")
	var name_label = achievement_notification.get_node("VBoxContainer/AchievementName")
	var description_label = achievement_notification.get_node("VBoxContainer/AchievementDescription")
	var reward_label = achievement_notification.get_node("VBoxContainer/RewardLabel")
	
	icon_label.text = achievement_data["icon"]
	name_label.text = achievement_data["name"]
	description_label.text = achievement_data["description"]
	
	var reward_text = _format_achievement_reward(achievement_data["reward_type"], achievement_data["reward_value"])
	reward_label.text = "Reward: " + reward_text
	
	achievement_notification.popup_centered()

# Utility functions
func _format_achievement_reward(reward_type: String, reward_value) -> String:
	match reward_type:
		"credits":
			return str(reward_value) + " Credits"
		"fuel_efficiency":
			return str(int(reward_value * 100)) + "% Fuel Efficiency"
		"trade_bonus":
			return str(int(reward_value * 100)) + "% Trade Bonus"
		"scanner_bonus":
			return str(int(reward_value * 100)) + "% Scanner Bonus"
		"discovery_bonus":
			return str(int(reward_value * 100)) + "% Discovery Bonus"
		"global_efficiency":
			return str(int(reward_value * 100)) + "% Global Efficiency"
		"travel_speed":
			return str(int(reward_value * 100)) + "% Travel Speed"
		"automation_efficiency":
			return str(int(reward_value * 100)) + "% Automation Efficiency"
		"upgrade_discount":
			return str(int(reward_value * 100)) + "% Upgrade Discount"
		_:
			return "Unknown Reward"

func _format_time(seconds: float) -> String:
	var hours = int(seconds / 3600)
	var minutes = int((int(seconds) % 3600) / 60)
	
	if hours > 0:
		return str(hours) + "h " + str(minutes) + "m"
	else:
		return str(minutes) + "m"

# Public functions for external access
func show_progression_panel():
	visible = true
	_update_all_displays()

func hide_progression_panel():
	visible = false