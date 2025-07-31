extends RefCounted
class_name DataExportUtility

# Data Export Utility - Export game data to various formats
# Supports CSV, JSON, and custom formats

static func export_to_csv(data: Array[Dictionary], filename: String = "") -> String:
	"""Export array of dictionaries to CSV format"""
	if data.is_empty():
		return ""
	
	var csv_content = ""
	var headers = data[0].keys()
	
	# Add headers
	csv_content += ",".join(headers) + "\n"
	
	# Add data rows
	for row in data:
		var values = []
		for header in headers:
			var value = str(row.get(header, ""))
			# Escape commas and quotes
			if value.contains(",") or value.contains("\""):
				value = "\"" + value.replace("\"", "\"\"") + "\""
			values.append(value)
		csv_content += ",".join(values) + "\n"
	
	# Save to file if filename provided
	if filename != "":
		_save_to_file(csv_content, filename)
	
	return csv_content

static func export_to_json(data, filename: String = "") -> String:
	"""Export data to JSON format"""
	var json_content = JSON.stringify(data, "\t")
	
	# Save to file if filename provided
	if filename != "":
		_save_to_file(json_content, filename)
	
	return json_content

static func export_panel_states_to_csv(panel_states: Dictionary) -> String:
	"""Export panel states to CSV format"""
	var data = []
	
	for panel_name in panel_states.keys():
		if panel_name in ["active_panel", "panel_history"]:
			continue
		
		var state_data = panel_states[panel_name]
		data.append({
			"panel_name": panel_name,
			"state": state_data.get("state", ""),
			"visible": state_data.get("visible", false),
			"position_x": state_data.get("position", Vector2.ZERO).x,
			"position_y": state_data.get("position", Vector2.ZERO).y,
			"size_x": state_data.get("size", Vector2.ZERO).x,
			"size_y": state_data.get("size", Vector2.ZERO).y
		})
	
	return export_to_csv(data)

static func export_game_statistics_to_csv(game_manager: GameManager) -> String:
	"""Export game statistics to CSV format"""
	if not game_manager:
		return ""
	
	var stats_data = []
	
	# Basic game stats
	stats_data.append({
		"metric": "Credits",
		"value": game_manager.credits,
		"category": "Economy"
	})
	
	stats_data.append({
		"metric": "Fuel",
		"value": game_manager.fuel,
		"category": "Resources"
	})
	
	stats_data.append({
		"metric": "Current Location",
		"value": game_manager.current_location,
		"category": "Navigation"
	})
	
	# Cargo stats
	var total_cargo = 0
	for good in game_manager.cargo.keys():
		var quantity = game_manager.cargo[good]
		total_cargo += quantity
		
		stats_data.append({
			"metric": "Cargo: " + good,
			"value": quantity,
			"category": "Inventory"
		})
	
	stats_data.append({
		"metric": "Total Cargo",
		"value": total_cargo,
		"category": "Inventory"
	})
	
	return export_to_csv(stats_data)

static func export_market_data_to_csv(game_manager: GameManager) -> String:
	"""Export market data to CSV format"""
	if not game_manager:
		return ""
	
	var market_data = []
	
	for system_id in game_manager.planets.keys():
		var system = game_manager.planets[system_id]
		var system_name = system.get("name", system_id)
		
		for good in system.get("market", {}).keys():
			var market_info = system["market"][good]
			
			market_data.append({
				"system": system_name,
				"system_id": system_id,
				"good": good,
				"buy_price": market_info.get("buy_price", 0),
				"sell_price": market_info.get("sell_price", 0),
				"supply": market_info.get("supply", 0),
				"demand": market_info.get("demand", 0)
			})
	
	return export_to_csv(market_data)

static func export_trade_history_to_csv(trade_history: Array[Dictionary]) -> String:
	"""Export trade history to CSV format"""
	if trade_history.is_empty():
		return ""
	
	var formatted_history = []
	
	for trade in trade_history:
		formatted_history.append({
			"timestamp": trade.get("timestamp", ""),
			"system": trade.get("system", ""),
			"action": trade.get("action", ""),
			"good": trade.get("good", ""),
			"quantity": trade.get("quantity", 0),
			"price": trade.get("price", 0),
			"total_value": trade.get("total_value", 0),
			"profit": trade.get("profit", 0)
		})
	
	return export_to_csv(formatted_history)

static func export_ship_stats_to_csv(ship_stats: Dictionary) -> String:
	"""Export ship statistics to CSV format"""
	var stats_data = []
	
	for stat_name in ship_stats.keys():
		var stat_value = ship_stats[stat_name]
		
		stats_data.append({
			"stat_name": stat_name,
			"value": stat_value,
			"type": typeof(stat_value)
		})
	
	return export_to_csv(stats_data)

static func _save_to_file(content: String, filename: String):
	"""Save content to file"""
	var file = FileAccess.open("user://" + filename, FileAccess.WRITE)
	if file:
		file.store_string(content)
		file.close()
		print("DataExportUtility: Saved to user://" + filename)
	else:
		print("DataExportUtility: Failed to save file: " + filename)

# Advanced export functions
static func export_comprehensive_game_data(game_manager: GameManager, ui_manager: UIManager) -> Dictionary:
	"""Export comprehensive game data including UI state"""
	var export_data = {
		"timestamp": Time.get_datetime_string_from_system(),
		"game_version": "1.0.0",  # Should be from project settings
		"export_type": "comprehensive"
	}
	
	# Game state
	if game_manager:
		export_data["game_state"] = {
			"credits": game_manager.credits,
			"fuel": game_manager.fuel,
			"current_location": game_manager.current_location,
			"cargo": game_manager.cargo.duplicate(),
			"ship_stats": game_manager.get_ship_stats() if game_manager.has_method("get_ship_stats") else {}
		}
		
		export_data["market_data"] = _extract_market_data(game_manager)
	
	# UI state
	if ui_manager:
		export_data["ui_state"] = {
			"panel_states": ui_manager.save_panel_states(),
			"accessibility_enabled": ui_manager.accessibility_enabled,
			"high_contrast_mode": ui_manager.high_contrast_mode,
			"ui_scale": ui_manager.ui_scale
		}
		
		if ui_manager.docking_system:
			export_data["ui_state"]["docking_layout"] = ui_manager.docking_system.save_layout()
	
	return export_data

static func _extract_market_data(game_manager: GameManager) -> Dictionary:
	"""Extract market data from game manager"""
	var market_data = {}
	
	for system_id in game_manager.planets.keys():
		var system = game_manager.planets[system_id]
		market_data[system_id] = {
			"name": system.get("name", system_id),
			"market": system.get("market", {}).duplicate()
		}
	
	return market_data

# Import functions
static func import_comprehensive_game_data(data: Dictionary, game_manager: GameManager, ui_manager: UIManager) -> bool:
	"""Import comprehensive game data"""
	if not data.has("export_type") or data["export_type"] != "comprehensive":
		print("DataExportUtility: Invalid export data format")
		return false
	
	# Import game state
	if data.has("game_state") and game_manager:
		var game_state = data["game_state"]
		
		if game_state.has("credits"):
			game_manager.credits = game_state["credits"]
		if game_state.has("fuel"):
			game_manager.fuel = game_state["fuel"]
		if game_state.has("current_location"):
			game_manager.current_location = game_state["current_location"]
		if game_state.has("cargo"):
			game_manager.cargo = game_state["cargo"]
	
	# Import UI state
	if data.has("ui_state") and ui_manager:
		var ui_state = data["ui_state"]
		
		if ui_state.has("panel_states"):
			ui_manager.restore_panel_states(ui_state["panel_states"])
		
		if ui_state.has("accessibility_enabled"):
			ui_manager.enable_accessibility_mode(ui_state["accessibility_enabled"])
		
		if ui_state.has("high_contrast_mode"):
			ui_manager.enable_high_contrast_mode(ui_state["high_contrast_mode"])
		
		if ui_state.has("ui_scale"):
			ui_manager.set_ui_scale(ui_state["ui_scale"])
		
		if ui_state.has("docking_layout") and ui_manager.docking_system:
			ui_manager.docking_system.load_layout(ui_state["docking_layout"])
	
	print("DataExportUtility: Comprehensive data imported successfully")
	return true

# Utility functions for data formatting
static func format_number_with_commas(number: float) -> String:
	"""Format number with comma separators"""
	var str_number = str(int(number))
	var formatted = ""
	var count = 0
	
	for i in range(str_number.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = str_number[i] + formatted
		count += 1
	
	return formatted

static func format_percentage(value: float, decimal_places: int = 1) -> String:
	"""Format value as percentage"""
	return str(round(value * 100 * pow(10, decimal_places)) / pow(10, decimal_places)) + "%"

static func format_currency(amount: float) -> String:
	"""Format amount as currency"""
	return format_number_with_commas(amount) + " cr"

static func sanitize_filename(filename: String) -> String:
	"""Sanitize filename for safe file operations"""
	var sanitized = filename
	var invalid_chars = ["<", ">", ":", "\"", "/", "\\", "|", "?", "*"]
	
	for char in invalid_chars:
		sanitized = sanitized.replace(char, "_")
	
	return sanitized

static func get_export_timestamp() -> String:
	"""Get formatted timestamp for exports"""
	var datetime = Time.get_datetime_dict_from_system()
	return "%04d%02d%02d_%02d%02d%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]