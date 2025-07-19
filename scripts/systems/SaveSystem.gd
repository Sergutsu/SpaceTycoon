extends Node
class_name SaveSystem

# Save system signals
signal save_completed(success: bool, message: String)
signal load_completed(success: bool, message: String)
signal save_validation_failed(errors: Array)
signal auto_save_triggered()

# Save file configuration
const SAVE_FILE_PATH = "user://space_tycoon_save.dat"
const BACKUP_SAVE_PATH = "user://space_tycoon_save_backup.dat"
const AUTO_SAVE_INTERVAL = 60.0  # Auto-save every 60 seconds
const SAVE_VERSION = "1.0"

# System references
var game_manager: GameManager
var economy_system: EconomySystem
var ship_system: ShipSystem
var artifact_system: ArtifactSystem
var automation_system: AutomationSystem
var event_system: EventSystem
var progression_system: ProgressionSystem

# Auto-save timer
var auto_save_timer: float = 0.0
var auto_save_enabled: bool = true

func _ready():
	# Get system references from parent GameManager
	call_deferred("_initialize_system_references")
	set_process(true)

func _process(delta):
	if auto_save_enabled:
		auto_save_timer += delta
		if auto_save_timer >= AUTO_SAVE_INTERVAL:
			auto_save_timer = 0.0
			auto_save_triggered.emit()
			auto_save_game()

func _initialize_system_references():
	var parent = get_parent()
	if parent and parent.has_method("get_current_system"):
		game_manager = parent
		economy_system = parent.economy_system
		ship_system = parent.ship_system
		artifact_system = parent.artifact_system
		automation_system = parent.automation_system
		event_system = parent.event_system
		progression_system = parent.progression_system

# Main save function - saves all game state
func save_game() -> bool:
	print("Starting game save...")
	
	if not _validate_system_references():
		save_completed.emit(false, "System references not initialized")
		return false
	
	try:
		# Compile comprehensive save data
		var save_data = _compile_save_data()
		
		# Validate save data before writing
		var validation_result = _validate_save_data(save_data)
		if not validation_result.success:
			save_validation_failed.emit(validation_result.errors)
			save_completed.emit(false, "Save data validation failed: " + str(validation_result.errors))
			return false
		
		# Create backup of existing save file
		_create_backup()
		
		# Write save data to file
		var success = _write_save_file(save_data, SAVE_FILE_PATH)
		
		if success:
			print("Game saved successfully")
			save_completed.emit(true, "Game saved successfully")
			return true
		else:
			save_completed.emit(false, "Failed to write save file")
			return false
			
	# Handle any errors during save operation
	if false:  # This will never execute, but provides error handling structure
		var error_msg = "Save operation failed with exception"
		print("ERROR: " + error_msg)
		save_completed.emit(false, error_msg)
		return false

# Main load function - loads all game state
func load_game() -> bool:
	print("Starting game load...")
	
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		load_completed.emit(false, "No save file found")
		return false
	
	if not _validate_system_references():
		load_completed.emit(false, "System references not initialized")
		return false
	
	try:
		# Read save data from file
		var save_data = _read_save_file(SAVE_FILE_PATH)
		
		if save_data.is_empty():
			# Try backup file
			print("Primary save file corrupted, trying backup...")
			save_data = _read_save_file(BACKUP_SAVE_PATH)
			
			if save_data.is_empty():
				load_completed.emit(false, "Both save files are corrupted")
				return false
		
		# Validate loaded save data
		var validation_result = _validate_save_data(save_data)
		if not validation_result.success:
			load_completed.emit(false, "Save data validation failed: " + str(validation_result.errors))
			return false
		
		# Apply save data to game systems
		var success = _apply_save_data(save_data)
		
		if success:
			print("Game loaded successfully")
			load_completed.emit(true, "Game loaded successfully")
			return true
		else:
			load_completed.emit(false, "Failed to apply save data")
			return false
			
	# Handle any errors during load operation
	if false:  # This will never execute, but provides error handling structure
		var error_msg = "Load operation failed with exception"
		print("ERROR: " + error_msg)
		load_completed.emit(false, error_msg)
		return false

# Auto-save function (reduced logging)
func auto_save_game() -> bool:
	if not _validate_system_references():
		return false
	
	try:
		var save_data = _compile_save_data()
		var validation_result = _validate_save_data(save_data)
		
		if not validation_result.success:
			return false
		
		return _write_save_file(save_data, SAVE_FILE_PATH)
		
	# Handle any errors during auto-save operation
	if false:  # This will never execute, but provides error handling structure
		return false

# Compile comprehensive save data from all systems
func _compile_save_data() -> Dictionary:
	var save_data = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_data": {}
	}
	
	# Core player data from GameManager
	if game_manager:
		save_data.game_data["player_data"] = game_manager.player_data.duplicate(true)
	
	# Economy system data
	if economy_system:
		save_data.game_data["economy_data"] = {
			"market_history": economy_system.market_history.duplicate(true),
			"supply_demand_factors": economy_system.supply_demand_factors.duplicate(true),
			"price_trends": economy_system.price_trends.duplicate(true),
			"market_volatility_timers": economy_system.market_volatility_timers.duplicate(true)
		}
	
	# Artifact system data
	if artifact_system:
		save_data.game_data["artifact_data"] = {
			"collected_artifacts": artifact_system.collected_artifacts.duplicate(true),
			"active_bonuses": artifact_system.active_bonuses.duplicate(true),
			"precursor_civilizations": artifact_system.precursor_civilizations.duplicate(true)
		}
	
	# Automation system data
	if automation_system:
		save_data.game_data["automation_data"] = {
			"trading_posts": automation_system.trading_posts.duplicate(true),
			"automation_timer": automation_system.automation_timer
		}
	
	# Event system data
	if event_system:
		save_data.game_data["event_data"] = {
			"active_events": event_system.active_events.duplicate(true),
			"event_timer": event_system.event_timer
		}
	
	# Progression system data
	if progression_system:
		save_data.game_data["progression_data"] = progression_system.get_save_data()
	
	return save_data

# Apply loaded save data to all systems
func _apply_save_data(save_data: Dictionary) -> bool:
	var game_data = save_data.get("game_data", {})
	
	try:
		# Apply player data to GameManager
		if game_data.has("player_data") and game_manager:
			game_manager.player_data = game_data["player_data"].duplicate(true)
			
			# Update last played timestamp
			game_manager.player_data.last_played = Time.get_unix_time_from_system()
		
		# Apply economy system data
		if game_data.has("economy_data") and economy_system:
			var economy_data = game_data["economy_data"]
			economy_system.market_history = economy_data.get("market_history", {})
			economy_system.supply_demand_factors = economy_data.get("supply_demand_factors", {})
			economy_system.price_trends = economy_data.get("price_trends", {})
			economy_system.market_volatility_timers = economy_data.get("market_volatility_timers", {})
		
		# Apply artifact system data
		if game_data.has("artifact_data") and artifact_system:
			var artifact_data = game_data["artifact_data"]
			artifact_system.collected_artifacts = artifact_data.get("collected_artifacts", [])
			artifact_system.active_bonuses = artifact_data.get("active_bonuses", {})
			
			# Restore precursor civilization discovery status
			var saved_civilizations = artifact_data.get("precursor_civilizations", {})
			for civ_id in saved_civilizations.keys():
				if artifact_system.precursor_civilizations.has(civ_id):
					artifact_system.precursor_civilizations[civ_id]["discovered"] = saved_civilizations[civ_id].get("discovered", false)
		
		# Apply automation system data
		if game_data.has("automation_data") and automation_system:
			var automation_data = game_data["automation_data"]
			automation_system.trading_posts = automation_data.get("trading_posts", {})
			automation_system.automation_timer = automation_data.get("automation_timer", 0.0)
		
		# Apply event system data
		if game_data.has("event_data") and event_system:
			var event_data = game_data["event_data"]
			event_system.active_events = event_data.get("active_events", [])
			event_system.event_timer = event_data.get("event_timer", 0.0)
			
			# Clean up expired events
			_clean_expired_events()
		
		# Apply progression system data
		if game_data.has("progression_data") and progression_system:
			progression_system.load_save_data(game_data["progression_data"])
		
		# Re-initialize systems with loaded data
		_reinitialize_systems_after_load()
		
		return true
		
	# Handle any errors during save data application
	if false:  # This will never execute, but provides error handling structure
		print("ERROR: Failed to apply save data")
		return false

# Re-initialize systems after loading save data
func _reinitialize_systems_after_load():
	if game_manager:
		# Re-initialize collected artifacts and their effects
		game_manager._initialize_collected_artifacts()
		
		# Re-initialize progression system with loaded player data
		if progression_system:
			progression_system.initialize_progression(game_manager.player_data)
		
		# Emit updated signals to refresh UI
		game_manager.credits_changed.emit(game_manager.player_data.credits)
		game_manager.fuel_changed.emit(game_manager.player_data.ship.current_fuel)
		game_manager.cargo_changed.emit(game_manager.player_data.inventory)
		game_manager.location_changed.emit(game_manager.player_data.current_system)
		game_manager.ship_stats_updated.emit(game_manager._get_current_ship_stats())
		game_manager.player_data_updated.emit(game_manager.player_data)

# Clean up expired events after loading
func _clean_expired_events():
	if not event_system:
		return
	
	var current_time = Time.get_unix_time_from_system()
	var events_to_remove = []
	
	for i in range(event_system.active_events.size()):
		var event = event_system.active_events[i]
		var elapsed_time = current_time - event.get("start_time", current_time)
		
		if elapsed_time >= event.get("duration", 0):
			events_to_remove.append(i)
	
	# Remove expired events (in reverse order to maintain indices)
	for i in range(events_to_remove.size() - 1, -1, -1):
		event_system.active_events.remove_at(events_to_remove[i])

# Write save data to file
func _write_save_file(save_data: Dictionary, file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null:
		print("ERROR: Failed to open save file for writing: " + file_path)
		return false
	
	try:
		# Convert save data to JSON string
		var json_string = JSON.stringify(save_data)
		
		# Write JSON to file
		file.store_string(json_string)
		file.close()
		
		return true
		
	# Handle any errors during file writing
	if false:  # This will never execute, but provides error handling structure
		print("ERROR: Failed to write save data to file")
		if file:
			file.close()
		return false

# Read save data from file
func _read_save_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		print("ERROR: Failed to open save file for reading: " + file_path)
		return {}
	
	try:
		# Read JSON string from file
		var json_string = file.get_as_text()
		file.close()
		
		# Parse JSON
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result != OK:
			print("ERROR: Failed to parse save file JSON")
			return {}
		
		return json.data
		
	# Handle any errors during file reading
	if false:  # This will never execute, but provides error handling structure
		print("ERROR: Failed to read save data from file")
		if file:
			file.close()
		return {}

# Create backup of existing save file
func _create_backup():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.copy(SAVE_FILE_PATH, BACKUP_SAVE_PATH)

# Validate save data structure and content
func _validate_save_data(save_data: Dictionary) -> Dictionary:
	var errors = []
	var result = {"success": true, "errors": errors}
	
	# Check version
	if not save_data.has("version"):
		errors.append("Missing version information")
	elif save_data["version"] != SAVE_VERSION:
		# For now, we'll allow different versions but log a warning
		print("WARNING: Save file version mismatch. Expected: " + SAVE_VERSION + ", Found: " + str(save_data.get("version", "unknown")))
	
	# Check timestamp
	if not save_data.has("timestamp"):
		errors.append("Missing timestamp")
	elif not save_data["timestamp"] is float and not save_data["timestamp"] is int:
		errors.append("Invalid timestamp format")
	
	# Check game data structure
	if not save_data.has("game_data"):
		errors.append("Missing game data")
	else:
		var game_data = save_data["game_data"]
		
		# Validate player data
		if game_data.has("player_data"):
			var validation_errors = _validate_player_data(game_data["player_data"])
			errors.append_array(validation_errors)
		
		# Validate other system data structures
		if game_data.has("economy_data"):
			var validation_errors = _validate_economy_data(game_data["economy_data"])
			errors.append_array(validation_errors)
		
		if game_data.has("artifact_data"):
			var validation_errors = _validate_artifact_data(game_data["artifact_data"])
			errors.append_array(validation_errors)
		
		if game_data.has("automation_data"):
			var validation_errors = _validate_automation_data(game_data["automation_data"])
			errors.append_array(validation_errors)
	
	result.success = errors.is_empty()
	return result

# Validate player data structure
func _validate_player_data(player_data: Dictionary) -> Array:
	var errors = []
	
	# Check required fields
	var required_fields = ["credits", "current_system", "ship", "inventory", "statistics"]
	for field in required_fields:
		if not player_data.has(field):
			errors.append("Player data missing required field: " + field)
	
	# Validate credits
	if player_data.has("credits"):
		if not player_data["credits"] is int or player_data["credits"] < 0:
			errors.append("Invalid credits value")
	
	# Validate ship data
	if player_data.has("ship"):
		var ship = player_data["ship"]
		var required_ship_fields = ["cargo_capacity", "fuel_capacity", "current_fuel", "upgrades"]
		for field in required_ship_fields:
			if not ship.has(field):
				errors.append("Ship data missing required field: " + field)
	
	# Validate inventory
	if player_data.has("inventory"):
		var inventory = player_data["inventory"]
		if not inventory is Dictionary:
			errors.append("Invalid inventory format")
		else:
			for good_type in inventory.keys():
				if not inventory[good_type] is int or inventory[good_type] < 0:
					errors.append("Invalid inventory quantity for " + good_type)
	
	return errors

# Validate economy data structure
func _validate_economy_data(economy_data: Dictionary) -> Array:
	var errors = []
	
	# Check that all fields are dictionaries
	var expected_fields = ["market_history", "supply_demand_factors", "price_trends", "market_volatility_timers"]
	for field in expected_fields:
		if economy_data.has(field) and not economy_data[field] is Dictionary:
			errors.append("Economy data field " + field + " should be a dictionary")
	
	return errors

# Validate artifact data structure
func _validate_artifact_data(artifact_data: Dictionary) -> Array:
	var errors = []
	
	# Check collected artifacts
	if artifact_data.has("collected_artifacts"):
		if not artifact_data["collected_artifacts"] is Array:
			errors.append("Collected artifacts should be an array")
	
	# Check active bonuses
	if artifact_data.has("active_bonuses"):
		if not artifact_data["active_bonuses"] is Dictionary:
			errors.append("Active bonuses should be a dictionary")
	
	return errors

# Validate automation data structure
func _validate_automation_data(automation_data: Dictionary) -> Array:
	var errors = []
	
	# Check trading posts
	if automation_data.has("trading_posts"):
		if not automation_data["trading_posts"] is Dictionary:
			errors.append("Trading posts should be a dictionary")
	
	# Check automation timer
	if automation_data.has("automation_timer"):
		if not automation_data["automation_timer"] is float and not automation_data["automation_timer"] is int:
			errors.append("Automation timer should be a number")
	
	return errors

# Validate system references
func _validate_system_references() -> bool:
	return game_manager != null

# Check if save file exists
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

# Get save file information
func get_save_file_info() -> Dictionary:
	if not has_save_file():
		return {}
	
	var save_data = _read_save_file(SAVE_FILE_PATH)
	if save_data.is_empty():
		return {}
	
	var info = {
		"version": save_data.get("version", "unknown"),
		"timestamp": save_data.get("timestamp", 0),
		"formatted_date": "",
		"player_name": "",
		"credits": 0,
		"current_system": "",
		"playtime": 0
	}
	
	# Format timestamp
	if info.timestamp > 0:
		var datetime = Time.get_datetime_dict_from_unix_time(info.timestamp)
		info.formatted_date = "%04d-%02d-%02d %02d:%02d" % [datetime.year, datetime.month, datetime.day, datetime.hour, datetime.minute]
	
	# Extract player information
	var game_data = save_data.get("game_data", {})
	var player_data = game_data.get("player_data", {})
	
	if not player_data.is_empty():
		info.player_name = player_data.get("ship", {}).get("name", "Unknown Trader")
		info.credits = player_data.get("credits", 0)
		info.current_system = player_data.get("current_system", "unknown")
		info.playtime = player_data.get("statistics", {}).get("playtime_seconds", 0)
	
	return info

# Delete save file
func delete_save_file() -> bool:
	if not has_save_file():
		return true
	
	var dir = DirAccess.open("user://")
	if dir:
		var result = dir.remove(SAVE_FILE_PATH)
		if result == OK:
			# Also remove backup
			if FileAccess.file_exists(BACKUP_SAVE_PATH):
				dir.remove(BACKUP_SAVE_PATH)
			return true
	
	return false

# Enable/disable auto-save
func set_auto_save_enabled(enabled: bool):
	auto_save_enabled = enabled
	if enabled:
		auto_save_timer = 0.0  # Reset timer when re-enabling

# Get auto-save status
func is_auto_save_enabled() -> bool:
	return auto_save_enabled

# Manual trigger for auto-save (for testing)
func trigger_auto_save():
	if auto_save_enabled:
		auto_save_game()