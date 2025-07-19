extends Node
class_name ProgressionSystem

# Progression system signals
signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
signal milestone_reached(milestone_id: String, milestone_data: Dictionary)
signal statistics_updated(stat_name: String, new_value)
signal progress_summary_updated(summary: Dictionary)

# Achievement definitions
var achievement_definitions: Dictionary = {
	# Trading achievements
	"first_trade": {
		"name": "First Steps",
		"description": "Complete your first trade",
		"icon": "🚀",
		"requirement_type": "trades_completed",
		"requirement_value": 1,
		"reward_type": "credits",
		"reward_value": 500,
		"category": "trading"
	},
	"trade_apprentice": {
		"name": "Trade Apprentice",
		"description": "Complete 10 trades",
		"icon": "📦",
		"requirement_type": "trades_completed",
		"requirement_value": 10,
		"reward_type": "credits",
		"reward_value": 2000,
		"category": "trading"
	},
	"trade_master": {
		"name": "Trade Master",
		"description": "Complete 50 trades",
		"icon": "💼",
		"requirement_type": "trades_completed",
		"requirement_value": 50,
		"reward_type": "credits",
		"reward_value": 10000,
		"category": "trading"
	},
	"profit_seeker": {
		"name": "Profit Seeker",
		"description": "Earn 50,000 credits total",
		"icon": "💰",
		"requirement_type": "total_credits_earned",
		"requirement_value": 50000,
		"reward_type": "fuel_efficiency",
		"reward_value": 0.05,
		"category": "trading"
	},
	"space_tycoon": {
		"name": "Space Tycoon",
		"description": "Earn 500,000 credits total",
		"icon": "👑",
		"requirement_type": "total_credits_earned",
		"requirement_value": 500000,
		"reward_type": "trade_bonus",
		"reward_value": 0.1,
		"category": "trading"
	},
	
	# Exploration achievements
	"first_journey": {
		"name": "First Journey",
		"description": "Travel to another star system",
		"icon": "🌟",
		"requirement_type": "systems_explored",
		"requirement_value": 2,
		"reward_type": "credits",
		"reward_value": 1000,
		"category": "exploration"
	},
	"system_explorer": {
		"name": "System Explorer",
		"description": "Visit all 5 star systems",
		"icon": "🗺️",
		"requirement_type": "systems_explored",
		"requirement_value": 5,
		"reward_type": "scanner_bonus",
		"reward_value": 0.1,
		"category": "exploration"
	},
	"long_hauler": {
		"name": "Long Hauler",
		"description": "Travel 1000 units of distance",
		"icon": "🚛",
		"requirement_type": "distance_traveled",
		"requirement_value": 1000,
		"reward_type": "fuel_efficiency",
		"reward_value": 0.1,
		"category": "exploration"
	},
	"galactic_wanderer": {
		"name": "Galactic Wanderer",
		"description": "Travel 5000 units of distance",
		"icon": "🌌",
		"requirement_type": "distance_traveled",
		"requirement_value": 5000,
		"reward_type": "travel_speed",
		"reward_value": 0.15,
		"category": "exploration"
	},
	
	# Discovery achievements
	"first_discovery": {
		"name": "Ancient Secrets",
		"description": "Discover your first artifact",
		"icon": "🔍",
		"requirement_type": "artifacts_found",
		"requirement_value": 1,
		"reward_type": "scanner_bonus",
		"reward_value": 0.05,
		"category": "discovery"
	},
	"artifact_hunter": {
		"name": "Artifact Hunter",
		"description": "Discover 5 artifacts",
		"icon": "🏺",
		"requirement_type": "artifacts_found",
		"requirement_value": 5,
		"reward_type": "discovery_bonus",
		"reward_value": 0.2,
		"category": "discovery"
	},
	"precursor_scholar": {
		"name": "Precursor Scholar",
		"description": "Unlock lore from all 3 precursor civilizations",
		"icon": "📚",
		"requirement_type": "precursor_civilizations_discovered",
		"requirement_value": 3,
		"reward_type": "global_efficiency",
		"reward_value": 0.1,
		"category": "discovery"
	},
	
	# Progression achievements
	"ship_upgrader": {
		"name": "Ship Upgrader",
		"description": "Purchase your first ship upgrade",
		"icon": "⚙️",
		"requirement_type": "upgrades_purchased",
		"requirement_value": 1,
		"reward_type": "credits",
		"reward_value": 3000,
		"category": "progression"
	},
	"tech_enthusiast": {
		"name": "Tech Enthusiast",
		"description": "Purchase 10 ship upgrades",
		"icon": "🔧",
		"requirement_type": "upgrades_purchased",
		"requirement_value": 10,
		"reward_type": "upgrade_discount",
		"reward_value": 0.05,
		"category": "progression"
	},
	"automation_pioneer": {
		"name": "Automation Pioneer",
		"description": "Create your first trading post",
		"icon": "🤖",
		"requirement_type": "trading_posts_created",
		"requirement_value": 1,
		"reward_type": "automation_efficiency",
		"reward_value": 0.1,
		"category": "progression"
	},
	"empire_builder": {
		"name": "Empire Builder",
		"description": "Create 3 trading posts",
		"icon": "🏭",
		"requirement_type": "trading_posts_created",
		"requirement_value": 3,
		"reward_type": "automation_efficiency",
		"reward_value": 0.2,
		"category": "progression"
	},
	
	# Time-based achievements
	"dedicated_trader": {
		"name": "Dedicated Trader",
		"description": "Play for 1 hour total",
		"icon": "⏰",
		"requirement_type": "playtime_hours",
		"requirement_value": 1,
		"reward_type": "credits",
		"reward_value": 5000,
		"category": "dedication"
	},
	"space_veteran": {
		"name": "Space Veteran",
		"description": "Play for 5 hours total",
		"icon": "🎖️",
		"requirement_type": "playtime_hours",
		"requirement_value": 5,
		"reward_type": "global_efficiency",
		"reward_value": 0.05,
		"category": "dedication"
	}
}

# Milestone definitions for progression indicators
var milestone_definitions: Dictionary = {
	"credits_10k": {
		"name": "First Fortune",
		"description": "Accumulate 10,000 credits",
		"target_value": 10000,
		"stat_name": "total_credits_earned",
		"category": "wealth"
	},
	"credits_100k": {
		"name": "Wealthy Trader",
		"description": "Accumulate 100,000 credits",
		"target_value": 100000,
		"stat_name": "total_credits_earned",
		"category": "wealth"
	},
	"trades_25": {
		"name": "Experienced Trader",
		"description": "Complete 25 trades",
		"target_value": 25,
		"stat_name": "trades_completed",
		"category": "trading"
	},
	"systems_all": {
		"name": "Galaxy Explorer",
		"description": "Visit all star systems",
		"target_value": 5,
		"stat_name": "systems_explored",
		"category": "exploration"
	},
	"artifacts_3": {
		"name": "Relic Collector",
		"description": "Discover 3 artifacts",
		"target_value": 3,
		"stat_name": "artifacts_found",
		"category": "discovery"
	}
}

# Current player statistics (extended from GameManager)
var player_statistics: Dictionary = {}

# Achievement tracking
var unlocked_achievements: Array = []
var completed_milestones: Array = []

# Session tracking
var session_start_time: float = 0.0
var last_progress_summary: Dictionary = {}

func _ready():
	session_start_time = Time.get_unix_time_from_system()
	set_process(true)

func _process(delta):
	# Update playtime
	if player_statistics.has("playtime_seconds"):
		player_statistics["playtime_seconds"] += delta
		
		# Check for time-based achievements
		var playtime_hours = player_statistics["playtime_seconds"] / 3600.0
		_check_achievement_progress("playtime_hours", playtime_hours)

# Initialize progression system with player data
func initialize_progression(player_data: Dictionary):
	player_statistics = player_data.get("statistics", {})
	unlocked_achievements = player_data.get("achievements_unlocked", [])
	
	# Ensure all required statistics exist
	_ensure_statistics_exist()
	
	# Check for any achievements that should already be unlocked
	_validate_existing_achievements()

func _ensure_statistics_exist():
	var required_stats = [
		"total_credits_earned",
		"systems_explored", 
		"artifacts_found",
		"trades_completed",
		"distance_traveled",
		"automation_efficiency",
		"playtime_seconds",
		"upgrades_purchased",
		"trading_posts_created",
		"precursor_civilizations_discovered",
		"rare_artifacts_found",
		"automation_profits_earned",
		"fuel_consumed",
		"cargo_transported"
	]
	
	for stat in required_stats:
		if not player_statistics.has(stat):
			player_statistics[stat] = 0

# Update a specific statistic
func update_statistic(stat_name: String, value, is_increment: bool = true):
	if not player_statistics.has(stat_name):
		player_statistics[stat_name] = 0
	
	var old_value = player_statistics[stat_name]
	
	if is_increment:
		player_statistics[stat_name] += value
	else:
		player_statistics[stat_name] = value
	
	var new_value = player_statistics[stat_name]
	
	# Emit signal for UI updates
	statistics_updated.emit(stat_name, new_value)
	
	# Check for achievement progress
	_check_achievement_progress(stat_name, new_value)
	
	# Check for milestone progress
	_check_milestone_progress(stat_name, new_value)
	
	# Update progress summary if significant change
	if _is_significant_change(stat_name, old_value, new_value):
		_update_progress_summary()

# Check if a statistic change is significant enough to update progress summary
func _is_significant_change(stat_name: String, old_value, new_value) -> bool:
	match stat_name:
		"total_credits_earned":
			return abs(new_value - old_value) >= 1000
		"trades_completed", "systems_explored", "artifacts_found":
			return new_value != old_value
		"distance_traveled":
			return abs(new_value - old_value) >= 50
		_:
			return new_value != old_value

# Check achievement progress for a specific statistic
func _check_achievement_progress(stat_name: String, current_value):
	for achievement_id in achievement_definitions.keys():
		# Skip already unlocked achievements
		if achievement_id in unlocked_achievements:
			continue
		
		var achievement = achievement_definitions[achievement_id]
		
		# Check if this achievement matches the updated statistic
		if achievement["requirement_type"] == stat_name:
			if current_value >= achievement["requirement_value"]:
				_unlock_achievement(achievement_id)

# Check milestone progress for a specific statistic
func _check_milestone_progress(stat_name: String, current_value):
	for milestone_id in milestone_definitions.keys():
		# Skip already completed milestones
		if milestone_id in completed_milestones:
			continue
		
		var milestone = milestone_definitions[milestone_id]
		
		# Check if this milestone matches the updated statistic
		if milestone["stat_name"] == stat_name:
			if current_value >= milestone["target_value"]:
				_complete_milestone(milestone_id)

# Unlock an achievement
func _unlock_achievement(achievement_id: String):
	if achievement_id in unlocked_achievements:
		return
	
	unlocked_achievements.append(achievement_id)
	var achievement_data = achievement_definitions[achievement_id]
	
	# Apply achievement reward
	_apply_achievement_reward(achievement_data)
	
	# Emit signal for UI notification
	achievement_unlocked.emit(achievement_id, achievement_data)
	
	print("Achievement unlocked: " + achievement_data["name"])

# Complete a milestone
func _complete_milestone(milestone_id: String):
	if milestone_id in completed_milestones:
		return
	
	completed_milestones.append(milestone_id)
	var milestone_data = milestone_definitions[milestone_id]
	
	# Emit signal for UI notification
	milestone_reached.emit(milestone_id, milestone_data)
	
	print("Milestone reached: " + milestone_data["name"])

# Apply achievement rewards
func _apply_achievement_reward(achievement_data: Dictionary):
	match achievement_data["reward_type"]:
		"credits":
			# This would need to be handled by GameManager
			pass
		"fuel_efficiency", "trade_bonus", "scanner_bonus", "discovery_bonus", "global_efficiency", "travel_speed", "automation_efficiency", "upgrade_discount":
			# These bonuses would be applied through the GameManager
			pass

# Validate existing achievements (for save game loading)
func _validate_existing_achievements():
	for achievement_id in unlocked_achievements.duplicate():
		var achievement = achievement_definitions.get(achievement_id, {})
		if achievement.is_empty():
			# Remove invalid achievement
			unlocked_achievements.erase(achievement_id)
			continue
		
		# Verify the achievement should still be unlocked
		var stat_value = player_statistics.get(achievement["requirement_type"], 0)
		if stat_value < achievement["requirement_value"]:
			# Achievement shouldn't be unlocked, remove it
			unlocked_achievements.erase(achievement_id)

# Update progress summary for session overview
func _update_progress_summary():
	var current_time = Time.get_unix_time_from_system()
	var session_duration = current_time - session_start_time
	
	last_progress_summary = {
		"session_duration": session_duration,
		"credits_earned_this_session": player_statistics.get("total_credits_earned", 0) - last_progress_summary.get("starting_credits", 0),
		"trades_this_session": player_statistics.get("trades_completed", 0) - last_progress_summary.get("starting_trades", 0),
		"systems_explored_this_session": player_statistics.get("systems_explored", 0) - last_progress_summary.get("starting_systems", 0),
		"artifacts_found_this_session": player_statistics.get("artifacts_found", 0) - last_progress_summary.get("starting_artifacts", 0),
		"achievements_unlocked_this_session": unlocked_achievements.size() - last_progress_summary.get("starting_achievements", 0),
		"total_statistics": player_statistics.duplicate()
	}
	
	progress_summary_updated.emit(last_progress_summary)

# Get achievement progress for UI display
func get_achievement_progress() -> Dictionary:
	var progress = {
		"unlocked": [],
		"available": [],
		"categories": {}
	}
	
	# Organize achievements by category
	for achievement_id in achievement_definitions.keys():
		var achievement = achievement_definitions[achievement_id]
		var category = achievement["category"]
		
		if not progress["categories"].has(category):
			progress["categories"][category] = {
				"unlocked": [],
				"available": []
			}
		
		var achievement_info = achievement.duplicate()
		achievement_info["id"] = achievement_id
		achievement_info["unlocked"] = achievement_id in unlocked_achievements
		
		# Add progress information
		var current_value = player_statistics.get(achievement["requirement_type"], 0)
		achievement_info["current_progress"] = current_value
		achievement_info["progress_percentage"] = min(100.0, (float(current_value) / float(achievement["requirement_value"])) * 100.0)
		
		if achievement_info["unlocked"]:
			progress["unlocked"].append(achievement_info)
			progress["categories"][category]["unlocked"].append(achievement_info)
		else:
			progress["available"].append(achievement_info)
			progress["categories"][category]["available"].append(achievement_info)
	
	return progress

# Get milestone progress for UI display
func get_milestone_progress() -> Dictionary:
	var progress = {
		"completed": [],
		"available": [],
		"categories": {}
	}
	
	for milestone_id in milestone_definitions.keys():
		var milestone = milestone_definitions[milestone_id]
		var category = milestone["category"]
		
		if not progress["categories"].has(category):
			progress["categories"][category] = {
				"completed": [],
				"available": []
			}
		
		var milestone_info = milestone.duplicate()
		milestone_info["id"] = milestone_id
		milestone_info["completed"] = milestone_id in completed_milestones
		
		# Add progress information
		var current_value = player_statistics.get(milestone["stat_name"], 0)
		milestone_info["current_progress"] = current_value
		milestone_info["progress_percentage"] = min(100.0, (float(current_value) / float(milestone["target_value"])) * 100.0)
		
		if milestone_info["completed"]:
			progress["completed"].append(milestone_info)
			progress["categories"][category]["completed"].append(milestone_info)
		else:
			progress["available"].append(milestone_info)
			progress["categories"][category]["available"].append(milestone_info)
	
	return progress

# Get comprehensive statistics for UI display
func get_statistics_display() -> Dictionary:
	return {
		"core_stats": {
			"Total Credits Earned": _format_number(player_statistics.get("total_credits_earned", 0)),
			"Trades Completed": str(player_statistics.get("trades_completed", 0)),
			"Systems Explored": str(player_statistics.get("systems_explored", 0)) + "/5",
			"Artifacts Found": str(player_statistics.get("artifacts_found", 0)),
			"Distance Traveled": _format_number(player_statistics.get("distance_traveled", 0)) + " units"
		},
		"progression_stats": {
			"Ship Upgrades Purchased": str(player_statistics.get("upgrades_purchased", 0)),
			"Trading Posts Created": str(player_statistics.get("trading_posts_created", 0)),
			"Automation Profits": _format_number(player_statistics.get("automation_profits_earned", 0)),
			"Precursor Civilizations": str(player_statistics.get("precursor_civilizations_discovered", 0)) + "/3"
		},
		"efficiency_stats": {
			"Automation Efficiency": str(int(player_statistics.get("automation_efficiency", 0.0) * 100)) + "%",
			"Fuel Consumed": _format_number(player_statistics.get("fuel_consumed", 0)) + " units",
			"Cargo Transported": _format_number(player_statistics.get("cargo_transported", 0)) + " units",
			"Playtime": _format_time(player_statistics.get("playtime_seconds", 0))
		},
		"session_summary": last_progress_summary
	}

# Get next goals for progression indicators
func get_next_goals() -> Array:
	var goals = []
	
	# Find next achievements to unlock
	for achievement_id in achievement_definitions.keys():
		if achievement_id in unlocked_achievements:
			continue
		
		var achievement = achievement_definitions[achievement_id]
		var current_value = player_statistics.get(achievement["requirement_type"], 0)
		var progress_percentage = (float(current_value) / float(achievement["requirement_value"])) * 100.0
		
		# Only show goals that are somewhat close (>10% progress) or very important
		if progress_percentage > 10.0 or achievement["category"] == "trading":
			goals.append({
				"type": "achievement",
				"id": achievement_id,
				"name": achievement["name"],
				"description": achievement["description"],
				"progress": current_value,
				"target": achievement["requirement_value"],
				"progress_percentage": progress_percentage,
				"category": achievement["category"]
			})
	
	# Find next milestones
	for milestone_id in milestone_definitions.keys():
		if milestone_id in completed_milestones:
			continue
		
		var milestone = milestone_definitions[milestone_id]
		var current_value = player_statistics.get(milestone["stat_name"], 0)
		var progress_percentage = (float(current_value) / float(milestone["target_value"])) * 100.0
		
		goals.append({
			"type": "milestone",
			"id": milestone_id,
			"name": milestone["name"],
			"description": milestone["description"],
			"progress": current_value,
			"target": milestone["target_value"],
			"progress_percentage": progress_percentage,
			"category": milestone["category"]
		})
	
	# Sort by progress percentage (closest to completion first)
	goals.sort_custom(func(a, b): return a["progress_percentage"] > b["progress_percentage"])
	
	# Return top 5 goals
	return goals.slice(0, 5)

# Get achievement rewards that can be applied
func get_achievement_rewards() -> Dictionary:
	var rewards = {
		"credits": 0,
		"fuel_efficiency": 0.0,
		"trade_bonus": 0.0,
		"scanner_bonus": 0.0,
		"discovery_bonus": 0.0,
		"global_efficiency": 0.0,
		"travel_speed": 0.0,
		"automation_efficiency": 0.0,
		"upgrade_discount": 0.0
	}
	
	for achievement_id in unlocked_achievements:
		var achievement = achievement_definitions.get(achievement_id, {})
		if achievement.is_empty():
			continue
		
		var reward_type = achievement["reward_type"]
		var reward_value = achievement["reward_value"]
		
		if rewards.has(reward_type):
			rewards[reward_type] += reward_value
	
	return rewards

# Utility functions
func _format_number(number: int) -> String:
	if number >= 1000000:
		return str(number / 1000000) + "M"
	elif number >= 1000:
		return str(number / 1000) + "K"
	else:
		return str(number)

func _format_time(seconds: float) -> String:
	var hours = int(seconds / 3600)
	var minutes = int((seconds % 3600) / 60)
	
	if hours > 0:
		return str(hours) + "h " + str(minutes) + "m"
	else:
		return str(minutes) + "m"

# Save/load functions
func get_save_data() -> Dictionary:
	return {
		"statistics": player_statistics,
		"unlocked_achievements": unlocked_achievements,
		"completed_milestones": completed_milestones,
		"session_start_time": session_start_time
	}

func load_save_data(save_data: Dictionary):
	player_statistics = save_data.get("statistics", {})
	unlocked_achievements = save_data.get("unlocked_achievements", [])
	completed_milestones = save_data.get("completed_milestones", [])
	session_start_time = save_data.get("session_start_time", Time.get_unix_time_from_system())
	
	_ensure_statistics_exist()
	_validate_existing_achievements()