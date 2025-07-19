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

# Event definitions
var event_definitions: Dictionary = {
	"solar_flare": {
		"name": "Solar Flare",
		"description": "Solar activity disrupts navigation systems",
		"probability": 0.15,
		"duration_range": [180, 300],  # 3-5 minutes
		"effects": {
			"fuel_cost_multiplier": 1.5,
			"scanner_efficiency": 0.5
		},
		"affected_systems": ["frontier_outpost", "terra_prime"]
	},
	"trade_boom": {
		"name": "Trade Boom",
		"description": "Economic prosperity increases trade opportunities",
		"probability": 0.20,
		"duration_range": [240, 480],  # 4-8 minutes
		"effects": {
			"price_volatility": 1.5,
			"profit_multiplier": 1.3
		},
		"affected_systems": ["nexus_station", "luxuria_resort"]
	},
	"artifact_signal": {
		"name": "Artifact Signal Detected",
		"description": "Ancient technology signatures detected in deep space",
		"probability": 0.10,
		"duration_range": [120, 180],  # 2-3 minutes
		"effects": {
			"artifact_discovery_bonus": 2.0
		},
		"affected_systems": ["frontier_outpost", "void_sector"]
	},
	"pirate_activity": {
		"name": "Pirate Activity",
		"description": "Increased pirate presence threatens cargo shipments",
		"probability": 0.12,
		"duration_range": [300, 600],  # 5-10 minutes
		"effects": {
			"cargo_loss_risk": 0.15,
			"travel_danger": 1.5
		},
		"affected_systems": ["frontier_outpost", "outer_rim"]
	},
	"market_crash": {
		"name": "Market Instability",
		"description": "Economic uncertainty causes price fluctuations",
		"probability": 0.08,
		"duration_range": [180, 360],  # 3-6 minutes
		"effects": {
			"price_volatility": 2.0,
			"profit_multiplier": 0.7
		},
		"affected_systems": ["all"]
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
			if event["effects"].has("profit_multiplier"):
				modifier *= event["effects"]["profit_multiplier"]
			if event["effects"].has("price_volatility"):
				# Price volatility affects random price fluctuations
				modifier *= (1.0 + (randf() - 0.5) * 0.2 * event["effects"]["price_volatility"])
	
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
		"artifact_discovery_bonus": 0.0,
		"cargo_loss_risk": 0.0,
		"price_volatility": 1.0
	}
	
	for event in active_events:
		for effect_type in event["effects"].keys():
			var effect_value = event["effects"][effect_type]
			
			match effect_type:
				"fuel_cost_multiplier", "scanner_efficiency", "profit_multiplier", "price_volatility":
					combined[effect_type] *= effect_value
				"artifact_discovery_bonus":
					combined[effect_type] += (effect_value - 1.0)
				"cargo_loss_risk":
					combined[effect_type] = max(combined[effect_type], effect_value)
	
	return combined

func _check_for_new_events():
	# Don't trigger too many events at once
	if active_events.size() >= 3:
		return
	
	for event_type in event_definitions.keys():
		var event_def = event_definitions[event_type]
		
		# Check if this event type is already active
		var already_active = false
		for active_event in active_events:
			if active_event["type"] == event_type:
				already_active = true
				break
		
		if not already_active and randf() < event_def["probability"]:
			trigger_event(event_type)
			break  # Only trigger one event per check

func _update_active_events(delta: float):
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