extends Node
class_name EventSystem

# Event system signals
signal event_triggered(event_type: String, duration: float, effects: Dictionary)
signal event_expired(event_type: String)
signal event_effects_updated(active_effects: Dictionary)

# Active events
var active_events: Array = []
var event_timer: float = 0.0
var event_check_interval: float = 60.0  # Check for new events every minute

# Event definitions - Enhanced with specific templates from requirements
var event_definitions: Dictionary = {
	"solar_flare": {
		"name": "Solar Flare",
		"description": "Intense solar radiation disrupts navigation and scanning systems across the galaxy",
		"probability": 0.12,
		"duration_range": [120, 240],  # 2-4 minutes
		"effects": {
			"fuel_cost_multiplier": 1.3,
			"scanner_efficiency": 0.7
		},
		"affected_systems": ["all"],
		"severity": "moderate",
		"category": "environmental"
	},
	"trade_boom": {
		"name": "Trade Boom",
		"description": "Economic prosperity creates increased demand and volatile pricing opportunities",
		"probability": 0.16,
		"duration_range": [180, 360],  # 3-6 minutes
		"effects": {
			"price_volatility": 1.3,
			"profit_multiplier": 1.2
		},
		"affected_systems": ["nexus_station", "luxuria_resort", "terra_prime"],
		"severity": "beneficial",
		"category": "economic"
	},
	"artifact_signal": {
		"name": "Artifact Signal Detected",
		"description": "Deep space sensors detect ancient precursor technology signatures",
		"probability": 0.14,
		"duration_range": [150, 240],  # 2.5-4 minutes
		"effects": {
			"artifact_discovery_bonus": 1.8,
			"scanner_efficiency": 1.3
		},
		"affected_systems": ["frontier_outpost"],
		"severity": "beneficial",
		"category": "discovery",
		"special_location": "frontier_outpost"
	},
	"pirate_activity": {
		"name": "Pirate Activity",
		"description": "Increased pirate presence in outer systems threatens cargo shipments",
		"probability": 0.08,
		"duration_range": [240, 420],  # 4-7 minutes
		"effects": {
			"cargo_loss_risk": 0.10,
			"travel_danger": 1.3,
			"fuel_cost_multiplier": 1.15
		},
		"affected_systems": ["frontier_outpost"],
		"severity": "dangerous",
		"category": "security"
	},
	"market_crash": {
		"name": "Market Instability",
		"description": "Economic uncertainty causes widespread price fluctuations and reduced profits",
		"probability": 0.08,
		"duration_range": [180, 360],  # 3-6 minutes
		"effects": {
			"price_volatility": 2.0,
			"profit_multiplier": 0.7
		},
		"affected_systems": ["all"],
		"severity": "harmful",
		"category": "economic"
	},
	"supply_shortage": {
		"name": "Supply Shortage",
		"description": "Critical resource shortages drive up prices in industrial systems",
		"probability": 0.14,
		"duration_range": [240, 420],  # 4-7 minutes
		"effects": {
			"price_multiplier": 1.4,
			"specific_goods": ["minerals", "tech"]
		},
		"affected_systems": ["minerva_station", "nexus_station"],
		"severity": "moderate",
		"category": "economic"
	},
	"luxury_demand": {
		"name": "Luxury Demand Spike",
		"description": "High society events create temporary demand for luxury goods and passenger transport",
		"probability": 0.11,
		"duration_range": [150, 300],  # 2.5-5 minutes
		"effects": {
			"price_multiplier": 1.6,
			"specific_goods": ["passengers", "luxury_goods"]
		},
		"affected_systems": ["luxuria_resort"],
		"severity": "beneficial",
		"category": "economic"
	}
}

func _ready():
	set_process(true)

func _process(delta):
	event_timer += delta
	
	# Check for new events
	if event_timer >= event_check_interval:
		event_timer = 0.0
		_check_for_new_events()
	
	# Update active events
	_update_active_events(delta)

func trigger_event(event_type: String, custom_duration: float = -1.0) -> Dictionary:
	if not event_definitions.has(event_type):
		return {"success": false, "error": "Unknown event type"}
	
	var event_def = event_definitions[event_type]
	var duration = custom_duration
	
	if duration <= 0:
		var duration_range = event_def["duration_range"]
		duration = randf_range(duration_range[0], duration_range[1])
	
	var event_data = {
		"type": event_type,
		"name": event_def["name"],
		"description": event_def["description"],
		"start_time": Time.get_unix_time_from_system(),
		"duration": duration,
		"effects": event_def["effects"].duplicate(),
		"affected_systems": event_def["affected_systems"].duplicate()
	}
	
	active_events.append(event_data)
	
	# Emit signal
	event_triggered.emit(event_type, duration, event_def["effects"])
	_update_combined_effects()
	
	return {"success": true, "event": event_data}

func get_active_events() -> Array:
	return active_events.duplicate()

func get_price_modifier(system_id: String, good_type: String) -> float:
	var modifier = 1.0
	
	for event in active_events:
		if _is_system_affected(system_id, event["affected_systems"]):
			# Apply general profit multiplier
			if event["effects"].has("profit_multiplier"):
				modifier *= event["effects"]["profit_multiplier"]
			
			# Apply direct price multiplier
			if event["effects"].has("price_multiplier"):
				modifier *= event["effects"]["price_multiplier"]
			
			# Apply specific good modifiers
			if event["effects"].has("specific_goods"):
				var specific_goods = event["effects"]["specific_goods"]
				if specific_goods.has(good_type):
					if event["effects"].has("price_multiplier"):
						modifier *= event["effects"]["price_multiplier"]
			
			# Apply price volatility as random fluctuation
			if event["effects"].has("price_volatility"):
				var volatility_factor = event["effects"]["price_volatility"]
				modifier *= (1.0 + (randf() - 0.5) * 0.3 * volatility_factor)
	
	return modifier

func get_fuel_cost_modifier() -> float:
	var modifier = 1.0
	
	for event in active_events:
		if event["effects"].has("fuel_cost_multiplier"):
			modifier *= event["effects"]["fuel_cost_multiplier"]
	
	return modifier

func get_scanner_efficiency_modifier() -> float:
	var modifier = 1.0
	
	for event in active_events:
		if event["effects"].has("scanner_efficiency"):
			modifier *= event["effects"]["scanner_efficiency"]
	
	return modifier

func get_artifact_discovery_bonus() -> float:
	var bonus = 0.0
	
	for event in active_events:
		if event["effects"].has("artifact_discovery_bonus"):
			bonus += event["effects"]["artifact_discovery_bonus"] - 1.0
	
	return bonus

func get_cargo_loss_risk() -> float:
	var risk = 0.0
	
	for event in active_events:
		if event["effects"].has("cargo_loss_risk"):
			risk = max(risk, event["effects"]["cargo_loss_risk"])
	
	return risk

func get_combined_effects() -> Dictionary:
	var combined = {
		"fuel_cost_multiplier": 1.0,
		"scanner_efficiency": 1.0,
		"profit_multiplier": 1.0,
		"price_multiplier": 1.0,
		"artifact_discovery_bonus": 0.0,
		"cargo_loss_risk": 0.0,
		"price_volatility": 1.0,
		"travel_danger": 1.0
	}
	
	for event in active_events:
		for effect_type in event["effects"].keys():
			var effect_value = event["effects"][effect_type]
			
			match effect_type:
				"fuel_cost_multiplier", "scanner_efficiency", "profit_multiplier", "price_multiplier", "price_volatility", "travel_danger":
					combined[effect_type] *= effect_value
				"artifact_discovery_bonus":
					combined[effect_type] += (effect_value - 1.0)
				"cargo_loss_risk":
					combined[effect_type] = max(combined[effect_type], effect_value)
	
	return combined

# Get events affecting a specific system
func get_system_events(system_id: String) -> Array:
	var system_events = []
	
	for event in active_events:
		if _is_system_affected(system_id, event["affected_systems"]):
			system_events.append(event)
	
	return system_events

# Get events by category
func get_events_by_category(category: String) -> Array:
	var category_events = []
	
	for event in active_events:
		if event_definitions[event["type"]]["category"] == category:
			category_events.append(event)
	
	return category_events

# Get event remaining time
func get_event_remaining_time(event_type: String) -> float:
	for event in active_events:
		if event["type"] == event_type:
			var current_time = Time.get_unix_time_from_system()
			var elapsed_time = current_time - event["start_time"]
			return max(0.0, event["duration"] - elapsed_time)
	
	return 0.0

# Check if specific event is active
func is_event_active(event_type: String) -> bool:
	for event in active_events:
		if event["type"] == event_type:
			return true
	return false

# Get event severity level
func get_event_severity(event_type: String) -> String:
	if event_definitions.has(event_type):
		return event_definitions[event_type].get("severity", "unknown")
	return "unknown"

func _check_for_new_events():
	# Don't trigger too many events at once (max 2 active events)
	if active_events.size() >= 2:
		return
	
	# Calculate base probability modifier based on current events
	var probability_modifier = 1.0
	if active_events.size() > 0:
		probability_modifier = 0.7  # Reduce chance of new events when others are active
	
	# Weighted random selection for more interesting event distribution
	var available_events = []
	
	for event_type in event_definitions.keys():
		var event_def = event_definitions[event_type]
		
		# Check if this event type is already active
		var already_active = false
		for active_event in active_events:
			if active_event["type"] == event_type:
				already_active = true
				break
		
		if not already_active:
			var adjusted_probability = event_def["probability"] * probability_modifier
			
			# Add some variety - boost probability if no events of this category are active
			var category = event_def["category"]
			var category_active = false
			for active_event in active_events:
				if event_definitions[active_event["type"]]["category"] == category:
					category_active = true
					break
			
			if not category_active:
				adjusted_probability *= 1.3  # 30% boost for new categories
			
			if randf() < adjusted_probability:
				available_events.append(event_type)
	
	# Trigger one random event from available events
	if available_events.size() > 0:
		var selected_event = available_events[randi() % available_events.size()]
		trigger_event(selected_event)

func _update_active_events(_delta: float):
	var current_time = Time.get_unix_time_from_system()
	var events_to_remove = []
	
	for i in range(active_events.size()):
		var event = active_events[i]
		var elapsed_time = current_time - event["start_time"]
		
		if elapsed_time >= event["duration"]:
			events_to_remove.append(i)
			event_expired.emit(event["type"])
	
	# Remove expired events (in reverse order to maintain indices)
	for i in range(events_to_remove.size() - 1, -1, -1):
		active_events.remove_at(events_to_remove[i])
	
	if not events_to_remove.is_empty():
		_update_combined_effects()

func _update_combined_effects():
	var combined_effects = get_combined_effects()
	event_effects_updated.emit(combined_effects)

func _is_system_affected(system_id: String, affected_systems: Array) -> bool:
	return affected_systems.has("all") or affected_systems.has(system_id)

# Force trigger a specific event (for testing or special circumstances)
func force_trigger_event(event_type: String, duration_override: float = -1.0) -> Dictionary:
	return trigger_event(event_type, duration_override)

# End a specific active event early
func end_event(event_type: String) -> bool:
	for i in range(active_events.size()):
		if active_events[i]["type"] == event_type:
			event_expired.emit(event_type)
			active_events.remove_at(i)
			_update_combined_effects()
			return true
	return false

# Get detailed event information for UI display
func get_event_display_info(event_type: String) -> Dictionary:
	if not event_definitions.has(event_type):
		return {}
	
	var event_def = event_definitions[event_type]
	var remaining_time = get_event_remaining_time(event_type)
	
	return {
		"name": event_def["name"],
		"description": event_def["description"],
		"severity": event_def["severity"],
		"category": event_def["category"],
		"remaining_time": remaining_time,
		"affected_systems": event_def["affected_systems"],
		"effects": event_def["effects"],
		"is_active": is_event_active(event_type)
	}

# Get all active events with display information
func get_active_events_display() -> Array:
	var display_events = []
	
	for event in active_events:
		var display_info = get_event_display_info(event["type"])
		display_info["start_time"] = event["start_time"]
		display_info["duration"] = event["duration"]
		display_events.append(display_info)
	
	return display_events

# Clear all active events (for testing or reset)
func clear_all_events():
	for event in active_events:
		event_expired.emit(event["type"])
	active_events.clear()
	_update_combined_effects()
