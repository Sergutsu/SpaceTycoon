extends Node
class_name EconomySystem

# Economy system signals
signal market_prices_updated(system_id: String, prices: Dictionary)
signal trade_executed(system_id: String, good_type: String, quantity: int, is_buying: bool, profit: int)
signal supply_demand_changed(system_id: String, good_type: String, new_factor: float)

# Market data tracking
var market_history: Dictionary = {}
var supply_demand_factors: Dictionary = {}
var price_trends: Dictionary = {}
var market_volatility_timers: Dictionary = {}

# Market mechanics constants
const SUPPLY_DEMAND_DECAY_RATE: float = 0.02  # How fast supply/demand returns to normal
const PRICE_HISTORY_LIMIT: int = 100
const TREND_ANALYSIS_WINDOW: int = 20
const VOLATILITY_UPDATE_INTERVAL: float = 30.0  # seconds

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
	# Initialize supply/demand factors and market data
	for system_id in star_systems.keys():
		for good_type in star_systems[system_id]["goods"].keys():
			var key = system_id + "_" + good_type
			supply_demand_factors[key] = 1.0
			price_trends[key] = {"direction": "stable", "strength": 0.0, "recent_prices": []}
			market_volatility_timers[key] = 0.0
	
	# Start market update timer
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_process_market_updates)
	timer.autostart = true
	add_child(timer)

func calculate_dynamic_price(system_id: String, good_type: String, event_modifier: float = 1.0, artifact_bonus: float = 0.0) -> int:
	if not star_systems.has(system_id) or not star_systems[system_id]["goods"].has(good_type):
		return 0
	
	var base_price = star_systems[system_id]["goods"][good_type]["base_price"]
	var volatility = star_systems[system_id]["goods"][good_type]["volatility"]
	var key = system_id + "_" + good_type
	
	# Apply supply/demand modifiers
	var supply_demand = supply_demand_factors.get(key, 1.0)
	
	# Apply system-specific volatility modifiers
	var system_volatility_modifier = _get_system_volatility_modifier(system_id)
	var adjusted_volatility = volatility * system_volatility_modifier
	
	# Apply random market fluctuation with enhanced volatility
	var random_factor = 1.0 + (randf_range(-adjusted_volatility, adjusted_volatility))
	
	# Apply trend-based price movement
	var trend_modifier = _get_trend_modifier(key)
	
	# Calculate final price
	var final_price = base_price * supply_demand * random_factor * trend_modifier * event_modifier * (1.0 + artifact_bonus)
	var price = max(1, int(final_price))
	
	# Record price for trend analysis
	_record_price_for_trends(key, price)
	
	return price

func execute_trade(system_id: String, good_type: String, quantity: int, is_buying: bool) -> Dictionary:
	# Validate inputs
	if not star_systems.has(system_id):
		return {"success": false, "error": "Invalid system ID"}
	
	if not star_systems[system_id]["goods"].has(good_type):
		return {"success": false, "error": "Good not available in this system"}
	
	if quantity <= 0:
		return {"success": false, "error": "Invalid quantity"}
	
	var key = system_id + "_" + good_type
	
	# Calculate trade impact based on quantity and system characteristics
	var base_impact = quantity / 100.0  # Base impact factor
	var system_impact_modifier = _get_system_trade_impact_modifier(system_id)
	var impact_factor = base_impact * system_impact_modifier
	
	var current_factor = supply_demand_factors.get(key, 1.0)
	
	if is_buying:
		# Buying increases demand, raises prices
		supply_demand_factors[key] = current_factor + (impact_factor * 0.15)
	else:
		# Selling increases supply, lowers prices
		supply_demand_factors[key] = current_factor - (impact_factor * 0.15)
	
	# Clamp to reasonable bounds with system-specific limits
	var min_factor = _get_system_min_price_factor(system_id)
	var max_factor = _get_system_max_price_factor(system_id)
	supply_demand_factors[key] = clamp(supply_demand_factors[key], min_factor, max_factor)
	
	# Record in market history with enhanced data
	_record_market_transaction(system_id, good_type, quantity, is_buying)
	
	# Update market trends
	_update_market_trends(key, is_buying, quantity)
	
	# Calculate profit for the signal
	var current_price = calculate_dynamic_price(system_id, good_type)
	var profit = 0
	if is_buying:
		profit = -current_price * quantity  # Negative profit for buying (cost)
	else:
		profit = current_price * quantity   # Positive profit for selling
	
	# Emit signals
	supply_demand_changed.emit(system_id, good_type, supply_demand_factors[key])
	market_prices_updated.emit(system_id, get_system_prices(system_id))
	trade_executed.emit(system_id, good_type, quantity, is_buying, profit)
	
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
	
	var prediction_accuracy = 0.6 + (ai_level * 0.08)  # 60-92% accuracy at max level
	var trend_data = _analyze_market_trends(good_type)
	
	# Enhanced prediction based on AI level
	var prediction = {
		"predicted_direction": trend_data.get("direction", "stable"),
		"confidence": prediction_accuracy,
		"time_horizon": "next_30_minutes",
		"trend_strength": trend_data.get("strength", 0.0)
	}
	
	# Add more detailed predictions for higher AI levels
	if ai_level >= 3:
		prediction["price_range_prediction"] = _predict_price_range(good_type, prediction_accuracy)
		prediction["best_systems_to_buy"] = _predict_best_buy_systems(good_type)
		prediction["best_systems_to_sell"] = _predict_best_sell_systems(good_type)
	
	if ai_level >= 4:
		prediction["market_events_forecast"] = _forecast_market_events(good_type)
		prediction["supply_demand_forecast"] = _forecast_supply_demand(good_type)
	
	if ai_level >= 5:
		prediction["optimal_trade_routes"] = _predict_optimal_routes(good_type)
		prediction["profit_potential"] = _calculate_profit_potential(good_type)
	
	return prediction

# Enhanced market prediction functions
func _predict_price_range(good_type: String, accuracy: float) -> Dictionary:
	var price_ranges = {}
	
	for system_id in star_systems.keys():
		if star_systems[system_id]["goods"].has(good_type):
			var current_price = calculate_dynamic_price(system_id, good_type)
			@warning_ignore("unused_variable")
			var base_price = star_systems[system_id]["goods"][good_type]["base_price"]
			var volatility = star_systems[system_id]["goods"][good_type]["volatility"]
			
			# Predict price range based on trends and volatility
			var key = system_id + "_" + good_type
			var trend = price_trends.get(key, {"direction": "stable", "strength": 0.0})
			
			var trend_modifier = 0.0
			match trend.direction:
				"rising":
					trend_modifier = trend.strength * 0.2
				"falling":
					trend_modifier = -trend.strength * 0.2
			
			# Add some uncertainty based on AI accuracy
			var uncertainty = (1.0 - accuracy) * 0.3
			var min_price = int(current_price * (1.0 + trend_modifier - volatility - uncertainty))
			var max_price = int(current_price * (1.0 + trend_modifier + volatility + uncertainty))
			
			price_ranges[system_id] = {
				"min_predicted_price": max(1, min_price),
				"max_predicted_price": max_price,
				"current_price": current_price
			}
	
	return price_ranges

func _predict_best_buy_systems(good_type: String) -> Array:
	var system_scores = []
	
	for system_id in star_systems.keys():
		if star_systems[system_id]["goods"].has(good_type):
			var current_price = calculate_dynamic_price(system_id, good_type)
			var base_price = star_systems[system_id]["goods"][good_type]["base_price"]
			var key = system_id + "_" + good_type
			var supply_demand = supply_demand_factors.get(key, 1.0)
			var trend = price_trends.get(key, {"direction": "stable", "strength": 0.0})
			
			# Score based on current price vs base, supply/demand, and trends
			var price_score = (base_price - current_price) / float(base_price)  # Lower price = better
			var supply_score = (2.0 - supply_demand) / 2.0  # Lower demand = better for buying
			var trend_score = 0.0
			
			if trend.direction == "falling":
				trend_score = trend.strength * 0.5  # Falling prices good for buying
			elif trend.direction == "rising":
				trend_score = -trend.strength * 0.3  # Rising prices bad for buying
			
			var total_score = price_score + supply_score + trend_score
			
			system_scores.append({
				"system_id": system_id,
				"system_name": star_systems[system_id]["name"],
				"score": total_score,
				"current_price": current_price,
				"reason": _generate_buy_reason(price_score, supply_score, trend_score)
			})
	
	# Sort by score (higher is better for buying)
	system_scores.sort_custom(func(a, b): return a.score > b.score)
	return system_scores.slice(0, 3)  # Return top 3

func _predict_best_sell_systems(good_type: String) -> Array:
	var system_scores = []
	
	for system_id in star_systems.keys():
		if star_systems[system_id]["goods"].has(good_type):
			var current_price = calculate_dynamic_price(system_id, good_type)
			var base_price = star_systems[system_id]["goods"][good_type]["base_price"]
			var key = system_id + "_" + good_type
			var supply_demand = supply_demand_factors.get(key, 1.0)
			var trend = price_trends.get(key, {"direction": "stable", "strength": 0.0})
			
			# Score based on current price vs base, supply/demand, and trends
			var price_score = (current_price - base_price) / float(base_price)  # Higher price = better
			var demand_score = (supply_demand - 1.0)  # Higher demand = better for selling
			var trend_score = 0.0
			
			if trend.direction == "rising":
				trend_score = trend.strength * 0.5  # Rising prices good for selling
			elif trend.direction == "falling":
				trend_score = -trend.strength * 0.3  # Falling prices bad for selling
			
			var total_score = price_score + demand_score + trend_score
			
			system_scores.append({
				"system_id": system_id,
				"system_name": star_systems[system_id]["name"],
				"score": total_score,
				"current_price": current_price,
				"reason": _generate_sell_reason(price_score, demand_score, trend_score)
			})
	
	# Sort by score (higher is better for selling)
	system_scores.sort_custom(func(a, b): return a.score > b.score)
	return system_scores.slice(0, 3)  # Return top 3

func _forecast_market_events(good_type: String) -> Dictionary:
	# Predict potential market events that could affect this good
	var forecast = {
		"potential_events": [],
		"risk_level": "low"
	}
	
	# Analyze market conditions to predict events
	for system_id in star_systems.keys():
		if star_systems[system_id]["goods"].has(good_type):
			var key = system_id + "_" + good_type
			var supply_demand = supply_demand_factors.get(key, 1.0)
			var trend = price_trends.get(key, {"direction": "stable", "strength": 0.0})
			
			# High supply/demand imbalance suggests potential events
			if supply_demand > 1.5:
				forecast.potential_events.append({
					"type": "supply_shortage",
					"system": star_systems[system_id]["name"],
					"probability": min(0.8, (supply_demand - 1.0) * 0.4)
				})
				forecast.risk_level = "medium"
			elif supply_demand < 0.6:
				forecast.potential_events.append({
					"type": "demand_crash",
					"system": star_systems[system_id]["name"],
					"probability": min(0.8, (1.0 - supply_demand) * 0.4)
				})
				forecast.risk_level = "medium"
			
			# Strong trends suggest potential reversals
			if trend.strength > 0.7:
				forecast.potential_events.append({
					"type": "trend_reversal",
					"system": star_systems[system_id]["name"],
					"current_trend": trend.direction,
					"probability": trend.strength * 0.3
				})
				if forecast.risk_level == "low":
					forecast.risk_level = "medium"
	
	return forecast

func _forecast_supply_demand(good_type: String) -> Dictionary:
	var forecast = {}
	
	for system_id in star_systems.keys():
		if star_systems[system_id]["goods"].has(good_type):
			var key = system_id + "_" + good_type
			var current_factor = supply_demand_factors.get(key, 1.0)
			var trend = price_trends.get(key, {"direction": "stable", "strength": 0.0})
			
			# Predict future supply/demand based on current trends
			var predicted_factor = current_factor
			match trend.direction:
				"rising":
					predicted_factor += trend.strength * 0.1  # Rising prices suggest increasing demand
				"falling":
					predicted_factor -= trend.strength * 0.1  # Falling prices suggest decreasing demand
			
			# Account for natural decay toward equilibrium
			if predicted_factor > 1.0:
				predicted_factor -= 0.05
			elif predicted_factor < 1.0:
				predicted_factor += 0.05
			
			predicted_factor = clamp(predicted_factor, 0.3, 2.5)
			
			forecast[system_id] = {
				"current_factor": current_factor,
				"predicted_factor": predicted_factor,
				"change_direction": "stable"
			}
			
			if predicted_factor > current_factor + 0.1:
				forecast[system_id]["change_direction"] = "increasing_demand"
			elif predicted_factor < current_factor - 0.1:
				forecast[system_id]["change_direction"] = "decreasing_demand"
	
	return forecast

func _predict_optimal_routes(good_type: String) -> Array:
	var routes = []
	
	# Find profitable trade routes for this good
	for buy_system in star_systems.keys():
		if not star_systems[buy_system]["goods"].has(good_type):
			continue
			
		var buy_price = calculate_dynamic_price(buy_system, good_type)
		
		for sell_system in star_systems.keys():
			if sell_system == buy_system or not star_systems[sell_system]["goods"].has(good_type):
				continue
			
			var sell_price = calculate_dynamic_price(sell_system, good_type)
			var travel_cost = get_travel_cost(buy_system, sell_system)
			
			# Calculate profit potential
			var profit_per_unit = sell_price - buy_price
			var profit_margin = profit_per_unit / float(buy_price) if buy_price > 0 else 0.0
			
			# Factor in travel costs
			var net_profit_per_unit = profit_per_unit - (travel_cost * 2)  # Fuel cost per unit
			
			if net_profit_per_unit > 0:
				routes.append({
					"buy_system": buy_system,
					"buy_system_name": star_systems[buy_system]["name"],
					"sell_system": sell_system,
					"sell_system_name": star_systems[sell_system]["name"],
					"buy_price": buy_price,
					"sell_price": sell_price,
					"profit_per_unit": net_profit_per_unit,
					"profit_margin": profit_margin,
					"travel_cost": travel_cost
				})
	
	# Sort by profit margin
	routes.sort_custom(func(a, b): return a.profit_margin > b.profit_margin)
	return routes.slice(0, 5)  # Return top 5 routes

func _calculate_profit_potential(good_type: String) -> Dictionary:
	var potential = {
		"max_profit_per_unit": 0,
		"best_route": {},
		"market_efficiency": 0.0,
		"volatility_opportunity": 0.0
	}
	
	var max_profit = 0
	var best_route = {}
	var price_differences = []
	
	# Calculate maximum profit potential
	for buy_system in star_systems.keys():
		if not star_systems[buy_system]["goods"].has(good_type):
			continue
			
		var buy_price = calculate_dynamic_price(buy_system, good_type)
		
		for sell_system in star_systems.keys():
			if sell_system == buy_system or not star_systems[sell_system]["goods"].has(good_type):
				continue
			
			var sell_price = calculate_dynamic_price(sell_system, good_type)
			var profit = sell_price - buy_price
			price_differences.append(abs(profit))
			
			if profit > max_profit:
				max_profit = profit
				best_route = {
					"buy_system": star_systems[buy_system]["name"],
					"sell_system": star_systems[sell_system]["name"],
					"profit": profit
				}
	
	potential.max_profit_per_unit = max_profit
	potential.best_route = best_route
	
	# Calculate market efficiency (lower differences = more efficient market)
	if price_differences.size() > 0:
		var avg_difference = 0.0
		for diff in price_differences:
			avg_difference += diff
		avg_difference /= price_differences.size()
		potential.market_efficiency = 1.0 - (avg_difference / 100.0)  # Normalize
	
	# Calculate volatility opportunity
	var total_volatility = 0.0
	var count = 0
	for system_id in star_systems.keys():
		if star_systems[system_id]["goods"].has(good_type):
			total_volatility += star_systems[system_id]["goods"][good_type]["volatility"]
			count += 1
	
	if count > 0:
		potential.volatility_opportunity = total_volatility / count
	
	return potential

func _generate_buy_reason(price_score: float, supply_score: float, trend_score: float) -> String:
	var reasons = []
	
	if price_score > 0.1:
		reasons.append("below average price")
	if supply_score > 0.1:
		reasons.append("low demand")
	if trend_score > 0.1:
		reasons.append("falling price trend")
	
	if reasons.is_empty():
		return "stable market conditions"
	else:
		return ", ".join(reasons)

func _generate_sell_reason(price_score: float, demand_score: float, trend_score: float) -> String:
	var reasons = []
	
	if price_score > 0.1:
		reasons.append("above average price")
	if demand_score > 0.1:
		reasons.append("high demand")
	if trend_score > 0.1:
		reasons.append("rising price trend")
	
	if reasons.is_empty():
		return "stable market conditions"
	else:
		return ", ".join(reasons)

# Public function to get comprehensive market analysis
func get_market_analysis(system_id: String, ai_level: int) -> Dictionary:
	if ai_level < 2:
		return {}
	
	var analysis = {
		"system_name": star_systems[system_id]["name"],
		"goods_analysis": {}
	}
	
	for good_type in star_systems[system_id]["goods"].keys():
		var market_data = get_market_data(system_id, good_type)
		var prediction = get_market_prediction(good_type, ai_level)
		
		analysis.goods_analysis[good_type] = {
			"current_data": market_data,
			"prediction": prediction
		}
	
	return analysis

func _record_market_transaction(system_id: String, good_type: String, quantity: int, is_buying: bool):
	var key = system_id + "_" + good_type
	if not market_history.has(key):
		market_history[key] = []
	
	var current_price = calculate_dynamic_price(system_id, good_type)
	var base_price = star_systems[system_id]["goods"][good_type]["base_price"]
	
	market_history[key].append({
		"timestamp": Time.get_unix_time_from_system(),
		"quantity": quantity,
		"is_buying": is_buying,
		"price": current_price,
		"base_price": base_price,
		"supply_demand_factor": supply_demand_factors.get(key, 1.0),
		"price_change_percent": ((current_price - base_price) / float(base_price)) * 100.0
	})
	
	# Keep only last transactions within limit
	if market_history[key].size() > PRICE_HISTORY_LIMIT:
		market_history[key] = market_history[key].slice(-PRICE_HISTORY_LIMIT)

func _analyze_market_trends(good_type: String) -> Dictionary:
	# Analyze trends across all systems for this good type
	var all_trends = []
	var overall_direction = "stable"
	var overall_strength = 0.0
	
	for system_id in star_systems.keys():
		var key = system_id + "_" + good_type
		if price_trends.has(key):
			var trend = price_trends[key]
			all_trends.append(trend)
			overall_strength += abs(trend.strength)
	
	if all_trends.size() > 0:
		overall_strength /= all_trends.size()
		
		# Determine overall direction based on majority
		var rising_count = 0
		var falling_count = 0
		for trend in all_trends:
			if trend.direction == "rising":
				rising_count += 1
			elif trend.direction == "falling":
				falling_count += 1
		
		if rising_count > falling_count:
			overall_direction = "rising"
		elif falling_count > rising_count:
			overall_direction = "falling"
	
	return {"direction": overall_direction, "strength": overall_strength}

# Enhanced market mechanics helper functions
func _process_market_updates(delta: float = 1.0):
	# Process supply/demand decay and volatility updates
	for key in supply_demand_factors.keys():
		# Gradually return supply/demand to equilibrium
		var current_factor = supply_demand_factors[key]
		if current_factor > 1.0:
			supply_demand_factors[key] = max(1.0, current_factor - SUPPLY_DEMAND_DECAY_RATE * delta)
		elif current_factor < 1.0:
			supply_demand_factors[key] = min(1.0, current_factor + SUPPLY_DEMAND_DECAY_RATE * delta)
		
		# Update volatility timers
		market_volatility_timers[key] += delta
		if market_volatility_timers[key] >= VOLATILITY_UPDATE_INTERVAL:
			market_volatility_timers[key] = 0.0
			_apply_random_market_volatility(key)

func _get_system_volatility_modifier(system_id: String) -> float:
	# Different systems have different volatility characteristics
	match star_systems[system_id]["type"]:
		"agricultural":
			return 0.8  # More stable agricultural systems
		"industrial":
			return 0.9  # Slightly more stable industrial systems
		"luxury":
			return 1.2  # More volatile luxury markets
		"frontier":
			return 1.8  # Highly volatile frontier markets
		"hub":
			return 1.0  # Balanced hub markets
		_:
			return 1.0

func _get_system_trade_impact_modifier(system_id: String) -> float:
	# How much individual trades affect the market in different systems
	match star_systems[system_id]["type"]:
		"agricultural":
			return 0.7  # Large agricultural markets, less impact per trade
		"industrial":
			return 0.8  # Industrial markets somewhat resistant to individual trades
		"luxury":
			return 1.3  # Luxury markets more sensitive to trades
		"frontier":
			return 1.5  # Small frontier markets highly sensitive
		"hub":
			return 0.9  # Hub markets moderately affected
		_:
			return 1.0

func _get_system_min_price_factor(system_id: String) -> float:
	# Minimum price factor based on system characteristics
	match star_systems[system_id]["type"]:
		"agricultural":
			return 0.6  # Agricultural systems have price floors
		"industrial":
			return 0.5  # Industrial systems can have very low prices
		"luxury":
			return 0.8  # Luxury markets maintain higher minimums
		"frontier":
			return 0.3  # Frontier can have extreme lows
		"hub":
			return 0.7  # Hub markets are more stable
		_:
			return 0.5

func _get_system_max_price_factor(system_id: String) -> float:
	# Maximum price factor based on system characteristics
	match star_systems[system_id]["type"]:
		"agricultural":
			return 1.8  # Agricultural systems have moderate ceilings
		"industrial":
			return 2.0  # Industrial systems can have high demand spikes
		"luxury":
			return 2.5  # Luxury markets can reach very high prices
		"frontier":
			return 3.0  # Frontier markets can have extreme highs
		"hub":
			return 1.6  # Hub markets are more controlled
		_:
			return 2.0

func _get_trend_modifier(key: String) -> float:
	# Apply trend-based price movement
	if not price_trends.has(key):
		return 1.0
	
	var trend = price_trends[key]
	var modifier = 1.0
	
	match trend.direction:
		"rising":
			modifier = 1.0 + (trend.strength * 0.1)  # Up to 10% increase
		"falling":
			modifier = 1.0 - (trend.strength * 0.1)  # Up to 10% decrease
		_:
			modifier = 1.0
	
	return modifier

func _record_price_for_trends(key: String, price: int):
	# Record price for trend analysis
	if not price_trends.has(key):
		price_trends[key] = {"direction": "stable", "strength": 0.0, "recent_prices": []}
	
	price_trends[key]["recent_prices"].append(price)
	
	# Keep only recent prices for trend analysis
	if price_trends[key]["recent_prices"].size() > TREND_ANALYSIS_WINDOW:
		price_trends[key]["recent_prices"] = price_trends[key]["recent_prices"].slice(-TREND_ANALYSIS_WINDOW)
	
	# Update trend analysis
	_analyze_price_trend(key)

func _analyze_price_trend(key: String):
	# Analyze price trend for a specific market
	var prices = price_trends[key]["recent_prices"]
	if prices.size() < 5:  # Need at least 5 data points
		return
	
	# Calculate trend using simple linear regression approach
	var n = prices.size()
	var sum_x = 0.0
	var sum_y = 0.0
	var sum_xy = 0.0
	var sum_x2 = 0.0
	
	for i in range(n):
		var x = float(i)
		var y = float(prices[i])
		sum_x += x
		sum_y += y
		sum_xy += x * y
		sum_x2 += x * x
	
	# Calculate slope (trend direction and strength)
	var slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
	var strength = abs(slope) / (sum_y / n) * 10.0  # Normalize strength
	strength = clamp(strength, 0.0, 1.0)
	
	# Determine direction
	var direction = "stable"
	if slope > 0.1:
		direction = "rising"
	elif slope < -0.1:
		direction = "falling"
	
	price_trends[key]["direction"] = direction
	price_trends[key]["strength"] = strength

func _update_market_trends(key: String, is_buying: bool, quantity: int):
	# Update market trends based on trading activity
	if not price_trends.has(key):
		return
	
	var trend = price_trends[key]
	var impact = quantity / 200.0  # Normalize impact
	
	if is_buying:
		# Buying pressure increases upward trend
		if trend.direction == "rising":
			trend.strength = min(1.0, trend.strength + impact * 0.1)
		elif trend.direction == "falling":
			trend.strength = max(0.0, trend.strength - impact * 0.1)
			if trend.strength < 0.2:
				trend.direction = "stable"
	else:
		# Selling pressure increases downward trend
		if trend.direction == "falling":
			trend.strength = min(1.0, trend.strength + impact * 0.1)
		elif trend.direction == "rising":
			trend.strength = max(0.0, trend.strength - impact * 0.1)
			if trend.strength < 0.2:
				trend.direction = "stable"

func _apply_random_market_volatility(key: String):
	# Apply random market events that affect volatility
	if randf() < 0.1:  # 10% chance every volatility interval
		var impact = randf_range(-0.2, 0.2)
		var current_factor = supply_demand_factors.get(key, 1.0)
		supply_demand_factors[key] = clamp(current_factor + impact, 0.3, 2.5)

# Public functions for market analysis
func get_market_data(system_id: String, good_type: String) -> Dictionary:
	var key = system_id + "_" + good_type
	var current_price = calculate_dynamic_price(system_id, good_type)
	var base_price = star_systems[system_id]["goods"][good_type]["base_price"]
	
	return {
		"current_price": current_price,
		"base_price": base_price,
		"supply_demand_factor": supply_demand_factors.get(key, 1.0),
		"trend": price_trends.get(key, {"direction": "stable", "strength": 0.0}),
		"volatility": star_systems[system_id]["goods"][good_type]["volatility"],
		"price_change_percent": ((current_price - base_price) / float(base_price)) * 100.0
	}

func get_average_price(good_type: String) -> float:
	# Calculate average price across all systems for a good type
	var total_price = 0.0
	var count = 0
	
	for system_id in star_systems.keys():
		if star_systems[system_id]["goods"].has(good_type):
			total_price += calculate_dynamic_price(system_id, good_type)
			count += 1
	
	return total_price / count if count > 0 else 0.0

func get_market_history(system_id: String, good_type: String, limit: int = 20) -> Array:
	var key = system_id + "_" + good_type
	if not market_history.has(key):
		return []
	
	var history = market_history[key]
	var start_index = max(0, history.size() - limit)
	return history.slice(start_index)

# Supply/demand visualization functions
func get_supply_demand_indicators(system_id: String) -> Dictionary:
	var indicators = {}
	
	for good_type in star_systems[system_id]["goods"].keys():
		var key = system_id + "_" + good_type
		var factor = supply_demand_factors.get(key, 1.0)
		var trend = price_trends.get(key, {"direction": "stable", "strength": 0.0})
		
		var indicator = "balanced"
		var color = "green"
		
		if factor > 1.3:
			indicator = "high_demand"
			color = "red"
		elif factor > 1.1:
			indicator = "moderate_demand"
			color = "orange"
		elif factor < 0.7:
			indicator = "oversupply"
			color = "blue"
		elif factor < 0.9:
			indicator = "low_demand"
			color = "light_blue"
		
		indicators[good_type] = {
			"indicator": indicator,
			"color": color,
			"factor": factor,
			"trend": trend,
			"description": _get_supply_demand_description(indicator, trend)
		}
	
	return indicators

func get_price_trend_indicators(system_id: String) -> Dictionary:
	var indicators = {}
	
	for good_type in star_systems[system_id]["goods"].keys():
		var key = system_id + "_" + good_type
		var trend = price_trends.get(key, {"direction": "stable", "strength": 0.0})
		var current_price = calculate_dynamic_price(system_id, good_type)
		var base_price = star_systems[system_id]["goods"][good_type]["base_price"]
		
		var arrow = "→"
		var color = "gray"
		
		match trend.direction:
			"rising":
				arrow = "↗" if trend.strength > 0.5 else "↑"
				color = "green"
			"falling":
				arrow = "↙" if trend.strength > 0.5 else "↓"
				color = "red"
			_:
				arrow = "→"
				color = "gray"
		
		indicators[good_type] = {
			"arrow": arrow,
			"color": color,
			"direction": trend.direction,
			"strength": trend.strength,
			"current_price": current_price,
			"base_price": base_price,
			"change_percent": ((current_price - base_price) / float(base_price)) * 100.0
		}
	
	return indicators

func _get_supply_demand_description(indicator: String, trend: Dictionary) -> String:
	var base_desc = ""
	match indicator:
		"high_demand":
			base_desc = "High demand - prices elevated"
		"moderate_demand":
			base_desc = "Moderate demand - prices slightly up"
		"balanced":
			base_desc = "Balanced market - stable prices"
		"low_demand":
			base_desc = "Low demand - prices slightly down"
		"oversupply":
			base_desc = "Oversupply - prices depressed"
	
	# Add trend information
	if trend.strength > 0.3:
		match trend.direction:
			"rising":
				base_desc += " (trending up)"
			"falling":
				base_desc += " (trending down)"
	
	return base_desc

# Market forecasting accuracy simulation
func get_prediction_accuracy_for_ai_level(ai_level: int) -> Dictionary:
	var accuracy_info = {}
	
	match ai_level:
		0, 1:
			accuracy_info = {
				"available": false,
				"description": "Market analysis requires AI Core Level 2+"
			}
		2:
			accuracy_info = {
				"available": true,
				"accuracy": 68,
				"features": ["Basic price trends", "Supply/demand indicators"],
				"description": "Basic market analysis with 68% accuracy"
			}
		3:
			accuracy_info = {
				"available": true,
				"accuracy": 76,
				"features": ["Price range predictions", "Best buy/sell systems", "Market trend analysis"],
				"description": "Advanced market analysis with 76% accuracy"
			}
		4:
			accuracy_info = {
				"available": true,
				"accuracy": 84,
				"features": ["Market event forecasting", "Supply/demand forecasting", "Risk analysis"],
				"description": "Professional market analysis with 84% accuracy"
			}
		5:
			accuracy_info = {
				"available": true,
				"accuracy": 92,
				"features": ["Optimal trade routes", "Profit potential analysis", "Market efficiency metrics"],
				"description": "Expert market analysis with 92% accuracy"
			}
	
	return accuracy_info
