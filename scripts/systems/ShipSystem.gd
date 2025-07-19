extends Node
class_name ShipSystem

# Ship system signals
signal ship_upgraded(upgrade_type: String, new_level: int, effects: Dictionary)
signal upgrade_purchased(upgrade_type: String, cost: int)
@warning_ignore("unused_signal")
signal ship_stats_updated(stats: Dictionary)

# Ship upgrade definitions
var upgrade_definitions: Dictionary = {
	"cargo_hold": {
		"name": "Cargo Hold",
		"description": "Increases ship cargo capacity",
		"levels": [50, 75, 100, 150, 200, 300],
		"costs": [0, 3500, 8500, 18000, 35000, 70000],
		"max_level": 5
	},
	"engine": {
		"name": "Engine System",
		"description": "Improves fuel efficiency and travel speed",
		"fuel_efficiency": [1.0, 0.9, 0.8, 0.7, 0.6, 0.5],
		"speed_multiplier": [1.0, 1.2, 1.5, 1.8, 2.2, 2.5],
		"costs": [0, 6000, 14000, 28000, 55000, 110000],
		"max_level": 5
	},
	"scanner": {
		"name": "Deep Space Scanner",
		"description": "Increases artifact detection range and accuracy",
		"detection_range": [1, 2, 3, 4, 5, 6],
		"detection_chance": [0.08, 0.14, 0.22, 0.32, 0.44, 0.58],
		"costs": [0, 2500, 6500, 15000, 32000, 65000],
		"max_level": 5
	},
	"ai_core": {
		"name": "AI Core",
		"description": "Enables automation features and market analysis",
		"automation_level": [0, 1, 2, 3, 4, 5],
		"efficiency_bonus": [0.0, 0.65, 0.75, 0.85, 0.92, 0.98],
		"costs": [0, 12000, 28000, 60000, 120000, 240000],
		"max_level": 5
	}
}

func can_afford_upgrade(upgrade_type: String, current_level: int, credits: int) -> bool:
	if not upgrade_definitions.has(upgrade_type):
		return false
	
	if current_level >= upgrade_definitions[upgrade_type]["max_level"]:
		return false
	
	var cost = upgrade_definitions[upgrade_type]["costs"][current_level + 1]
	return credits >= cost

func get_upgrade_cost(upgrade_type: String, current_level: int) -> int:
	if not upgrade_definitions.has(upgrade_type):
		return 0
	
	if current_level >= upgrade_definitions[upgrade_type]["max_level"]:
		return 0
	
	return upgrade_definitions[upgrade_type]["costs"][current_level + 1]

func purchase_upgrade(upgrade_type: String, current_level: int, credits: int) -> Dictionary:
	if not upgrade_definitions.has(upgrade_type):
		return {"success": false, "error": "Invalid upgrade type"}
	
	var max_level = upgrade_definitions[upgrade_type]["max_level"]
	if current_level >= max_level:
		return {"success": false, "error": "Upgrade already at maximum level"}
	
	var cost = upgrade_definitions[upgrade_type]["costs"][current_level + 1]
	if credits < cost:
		return {"success": false, "error": "Insufficient credits"}
	
	var new_level = current_level + 1
	var effects = apply_upgrade_effects(upgrade_type, new_level)
	
	# Emit signals
	upgrade_purchased.emit(upgrade_type, cost)
	ship_upgraded.emit(upgrade_type, new_level, effects)
	
	return {
		"success": true,
		"new_level": new_level,
		"cost": cost,
		"effects": effects
	}

func apply_upgrade_effects(upgrade_type: String, new_level: int) -> Dictionary:
	var effects = {}
	
	match upgrade_type:
		"cargo_hold":
			effects["cargo_capacity"] = upgrade_definitions[upgrade_type]["levels"][new_level]
		"engine":
			effects["fuel_efficiency"] = upgrade_definitions[upgrade_type]["fuel_efficiency"][new_level]
			effects["speed_multiplier"] = upgrade_definitions[upgrade_type]["speed_multiplier"][new_level]
		"scanner":
			effects["detection_range"] = upgrade_definitions[upgrade_type]["detection_range"][new_level]
			effects["detection_chance"] = upgrade_definitions[upgrade_type]["detection_chance"][new_level]
		"ai_core":
			effects["automation_level"] = upgrade_definitions[upgrade_type]["automation_level"][new_level]
			effects["efficiency_bonus"] = upgrade_definitions[upgrade_type]["efficiency_bonus"][new_level]
	
	return effects

@warning_ignore("unused_parameter")
func calculate_travel_cost(from_system: String, to_system: String, base_cost: int, fuel_efficiency: float) -> int:
	return max(1, int(base_cost * fuel_efficiency))

@warning_ignore("unused_parameter")
func calculate_travel_time(from_system: String, to_system: String, base_time: float, speed_multiplier: float) -> float:
	return base_time / speed_multiplier

func get_ship_stats(ship_data: Dictionary) -> Dictionary:
	var stats = {
		"cargo_capacity": ship_data.get("cargo_capacity", 50),
		"fuel_capacity": ship_data.get("fuel_capacity", 100),
		"fuel_efficiency": ship_data.get("fuel_efficiency", 1.0),
		"speed_multiplier": ship_data.get("speed_multiplier", 1.0),
		"detection_range": ship_data.get("detection_range", 1),
		"detection_chance": ship_data.get("detection_chance", 0.05),
		"automation_level": ship_data.get("automation_level", 0),
		"efficiency_bonus": ship_data.get("efficiency_bonus", 0.0)
	}
	
	return stats

func get_upgrade_info(upgrade_type: String, current_level: int) -> Dictionary:
	if not upgrade_definitions.has(upgrade_type):
		return {}
	
	var upgrade_def = upgrade_definitions[upgrade_type]
	var info = {
		"name": upgrade_def["name"],
		"description": upgrade_def["description"],
		"current_level": current_level,
		"max_level": upgrade_def["max_level"],
		"can_upgrade": current_level < upgrade_def["max_level"],
		"next_cost": 0,
		"current_effects": {},
		"next_effects": {}
	}
	
	if info["can_upgrade"]:
		info["next_cost"] = upgrade_def["costs"][current_level + 1]
		info["current_effects"] = apply_upgrade_effects(upgrade_type, current_level)
		info["next_effects"] = apply_upgrade_effects(upgrade_type, current_level + 1)
	else:
		info["current_effects"] = apply_upgrade_effects(upgrade_type, current_level)
	
	return info

func get_all_upgrade_types() -> Array:
	return upgrade_definitions.keys()
