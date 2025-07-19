extends Node
class_name EconomySystem

# Economy system signals
signal market_prices_updated(system_id: String, prices: Dictionary)
signal trade_executed(system_id: String, good_type: String, quantity: int, is_buying: bool, profit: int)
signal supply_demand_changed(system_id: String, good_type: String, new_factor: float)

# Market data tracking
var market_history: Dictionary = {}
var supply_demand_factors: Dictionary = {}

# Star systems with enhanced economic data
var star_systems: Dictionary = {
	"terra_prime": {
		"name": "Terra Prime",
		"type": "agricultural",
		"risk_level": "safe",
		"special_features": ["stable_prices", "food_surplus"],
		"position": Vector2(100, 200),
		"goods": {
			"food": {"base_price": 8, "volatility": 0.1},
			"minerals": {"base_price": 55, "volatility": 0.2},
			"tech": {"base_price": 30, "volatility": 0.15}
		},
		"travel_costs": {
			"minerva_station": 15,
			"luxuria_resort": 20,
			"frontier_outpost": 35,
			"nexus_station": 25
		}
	},
	"minerva_station": {
		"name": "Minerva Station",
		"type": "industrial", 
		"risk_level": "safe",
		"special_features": ["bulk_discounts", "mineral_surplus"],
		"position": Vector2(300, 150),
		"goods": {
			"food": {"base_price": 25, "volatility": 0.2},
			"minerals": {"base_price": 12, "volatility": 0.1},
			"tech": {"base_price": 35, "volatility": 0.15}
		},
		"travel_costs": {
			"terra_prime": 15,
			"luxuria_resort": 22,
			"frontier_outpost": 28,
			"nexus_station": 18
		}
	},
	"luxuria_resort": {
		"name": "Luxuria Resort",
		"type": "luxury",
		"risk_level": "safe",
		"special_features": ["premium_passengers", "luxury_goods"],
		"position": Vector2(200, 350),
		"goods": {
			"food": {"base_price": 18, "volatility": 0.15},
			"minerals": {"base_price": 40, "volatility": 0.2},
			"passengers": {"base_price": 60, "volatility": 0.3}
		},
		"travel_costs": {
			"terra_prime": 20,
			"minerva_station": 22,
			"frontier_outpost": 30,
			"nexus_station": 15
		}
	},
	"frontier_outpost": {
		"name": "Frontier Outpost",
		"type": "frontier",
		"risk_level": "high",
		"special_features": ["volatile_prices", "rare_goods"],
		"position": Vector2(450, 300),
		"goods": {
			"food": {"base_price": 45, "volatility": 0.4},
			"minerals": {"base_price": 8, "volatility": 0.3},
			"artifacts": {"base_price": 200, "volatility": 0.5}
		},
		"travel_costs": {
			"terra_prime": 35,
			"minerva_station": 28,
			"luxuria_resort": 30,
			"nexus_station": 20
		}
	},
	"nexus_station": {
		"name": "Nexus Station",
		"type": "hub",
		"risk_level": "safe",
		"special_features": ["upgrade_shop", "trade_hub"],
		"position": Vector2(250, 200),
		"goods": {
			"food": {"base_price": 15, "volatility": 0.12},
			"minerals": {"base_price": 25, "volatility": 0.12},
			"ship_parts": {"base_price": 100, "volatility": 0.1}
		},
		"travel_costs": {
			"terra_prime": 25,
			"minerva_station": 18,
			"luxuria_resort": 15,
			"frontier_outpost": 20
		}
	}
}

func _ready():
	# Initialize supply/demand factors
	for system_id in star_systems.keys():
		for good_type in star_systems[system_id]["goods"].keys():
			supply_demand_factors[system_id + "_" + good_type] = 1.0

func calculate_dynamic_price(system_id: String, good_type: String, event_modifier: float = 1.0, artifact_bonus: float = 0.0) -> int:
	if not star_systems.has(system_id) or not star_systems[system_id]["goods"].has(good_type):
		return 0
	
	var base_price = star_systems[system_id]["goods"][good_type]["base_price"]
	var volatility = star_systems[system_id]["goods"][good_type]["volatility"]
	
	# Apply supply/demand modifiers
	var supply_demand = supply_demand_factors.get(system_id + "_" + good_type, 1.0)
	
	# Apply random market fluctuation
	var random_factor = 1.0 + (randf_range(-volatility, volatility))
	
	# Calculate final price
	var final_price = base_price * supply_demand * random_factor * event_modifier * (1.0 + artifact_bonus)
	return max(1, int(final_price))

func execute_trade(system_id: String, good_type: String, quantity: int, is_buying: bool) -> Dictionary:
	# Validate inputs
	if not star_systems.has(system_id):
		return {"success": false, "error": "Invalid system ID"}
	
	if not star_systems[system_id]["goods"].has(good_type):
		return {"success": false, "error": "Good not available in this system"}
	
	if quantity <= 0:
		return {"success": false, "error": "Invalid quantity"}
	
	# Update supply/demand based on trade volume
	var impact_factor = quantity / 100.0  # Larger trades have more impact
	var current_factor = supply_demand_factors.get(system_id + "_" + good_type, 1.0)
	
	if is_buying:
		# Buying increases demand, raises prices
		supply_demand_factors[system_id + "_" + good_type] = current_factor + (impact_factor * 0.1)
	else:
		# Selling increases supply, lowers prices
		supply_demand_factors[system_id + "_" + good_type] = current_factor - (impact_factor * 0.1)
	
	# Clamp to reasonable bounds
	supply_demand_factors[system_id + "_" + good_type] = clamp(
		supply_demand_factors[system_id + "_" + good_type], 0.5, 2.0
	)
	
	# Record in market history
	_record_market_transaction(system_id, good_type, quantity, is_buying)
	
	# Emit signals
	supply_demand_changed.emit(system_id, good_type, supply_demand_factors[system_id + "_" + good_type])
	market_prices_updated.emit(system_id, get_system_prices(system_id))
	
	return {"success": true}

func get_system_prices(system_id: String, event_modifier: float = 1.0, artifact_bonus: float = 0.0) -> Dictionary:
	var prices = {}
	if star_systems.has(system_id):
		for good_type in star_systems[system_id]["goods"].keys():
			prices[good_type] = calculate_dynamic_price(system_id, good_type, event_modifier, artifact_bonus)
	return prices

func get_system_data(system_id: String) -> Dictionary:
	return star_systems.get(system_id, {})

func get_all_systems() -> Dictionary:
	return star_systems

func get_travel_cost(from_system: String, to_system: String) -> int:
	if star_systems.has(from_system) and star_systems[from_system]["travel_costs"].has(to_system):
		return star_systems[from_system]["travel_costs"][to_system]
	return 0

func get_market_prediction(good_type: String, ai_level: int) -> Dictionary:
	if ai_level < 2:
		return {}
	
	var prediction_accuracy = 0.6 + (ai_level * 0.1)  # 60-90% accuracy
	var trend_data = _analyze_market_trends(good_type)
	
	return {
		"predicted_direction": trend_data.get("direction", "stable"),
		"confidence": prediction_accuracy,
		"time_horizon": "next_hour"
	}

func _record_market_transaction(system_id: String, good_type: String, quantity: int, is_buying: bool):
	var key = system_id + "_" + good_type
	if not market_history.has(key):
		market_history[key] = []
	
	market_history[key].append({
		"timestamp": Time.get_unix_time_from_system(),
		"quantity": quantity,
		"is_buying": is_buying,
		"price": calculate_dynamic_price(system_id, good_type)
	})
	
	# Keep only last 100 transactions
	if market_history[key].size() > 100:
		market_history[key] = market_history[key].slice(-100)

func _analyze_market_trends(good_type: String) -> Dictionary:
	# Simple trend analysis - could be enhanced
	return {"direction": "stable", "strength": 0.5}