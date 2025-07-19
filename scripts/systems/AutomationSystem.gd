extends Node
class_name AutomationSystem

# Automation system signals
signal trading_post_created(system_id: String, config: Dictionary)
signal automation_profit_generated(amount: int, source: String)
signal trading_post_status_updated(system_id: String, status: Dictionary)
signal automation_efficiency_changed(new_efficiency: float)
signal trading_post_trade_executed(system_id: String, good_type: String, quantity: int, profit: int)

# System references
var economy_system: EconomySystem
var game_manager: GameManager

# Trading posts data
var trading_posts: Dictionary = {}
var automation_timer: float = 0.0
var trade_interval: float = 30.0  # Execute trades every 30 seconds

# Trading post configuration template
var trading_post_template: Dictionary = {
	"cost": 35000,
	"efficiency": 0.65,  # 65% of manual trading profit
	"cargo_allocation": 25,
	"auto_buy_threshold": 0.85,  # Buy when price < 85% of average
	"auto_sell_threshold": 1.15,  # Sell when price > 115% of average
	"target_goods": ["food", "minerals"],
	"active": true,
	"profit_generated": 0,
	"trades_executed": 0,
	"trade_timer": 0.0,
	"inventory": {},  # Trading post local inventory
	"last_trade_time": 0,
	"trade_history": [],
	"ai_level": 1
}

func _ready():
	# Get system references from parent GameManager
	call_deferred("_initialize_system_references")
	# Start automation processing
	set_process(true)

func _initialize_system_references():
	var parent = get_parent()
	if parent and parent.has_method("get"):
		economy_system = parent.economy_system
		game_manager = parent
	else:
		# Fallback - find systems in scene tree
		economy_system = get_node("../EconomySystem") if has_node("../EconomySystem") else null
		game_manager = get_node("../") if get_node("../").has_method("get_current_system") else null

func _process(delta):
	process_automation(delta)

func can_create_trading_post(system_id: String, ai_level: int, credits: int) -> bool:
	# Check AI Core level requirement (Requirement 5.1)
	if ai_level < 1:
		return false
	
	# Check if player has sufficient credits
	if credits < trading_post_template.cost:
		return false
	
	# Check if trading post already exists at this system
	if trading_posts.has(system_id):
		return false
	
	# Check if system exists and is valid
	if not economy_system or not economy_system.get_system_data(system_id).has("name"):
		return false
	
	return true

func create_trading_post(system_id: String, config: Dictionary) -> Dictionary:
	var ai_level = config.get("ai_level", 0)
	var credits = config.get("credits", 0)
	
	# Validate creation requirements
	if not can_create_trading_post(system_id, ai_level, credits):
		var error_msg = ""
		if ai_level < 1:
			error_msg = "AI Core Level 1 required"
		elif credits < trading_post_template.cost:
			error_msg = "Insufficient credits (need " + str(trading_post_template.cost) + ")"
		elif trading_posts.has(system_id):
			error_msg = "Trading post already exists at this system"
		else:
			error_msg = "Invalid system or requirements not met"
		
		return {"success": false, "error": error_msg}
	
	# Create new trading post with configuration
	var post = trading_post_template.duplicate(true)
	
	# Apply custom configuration (Requirement 5.2)
	post["ai_level"] = ai_level
	post["efficiency"] = _calculate_efficiency_from_ai_level(ai_level)
	
	if config.has("cargo_allocation"):
		post["cargo_allocation"] = clamp(config["cargo_allocation"], 10, 100)
	if config.has("auto_buy_threshold"):
		post["auto_buy_threshold"] = clamp(config["auto_buy_threshold"], 0.5, 1.0)
	if config.has("auto_sell_threshold"):
		post["auto_sell_threshold"] = clamp(config["auto_sell_threshold"], 1.0, 2.0)
	if config.has("target_goods"):
		post["target_goods"] = config["target_goods"]
	
	# Initialize trading post inventory
	post["inventory"] = {}
	for good_type in post["target_goods"]:
		post["inventory"][good_type] = 0
	
	# Set creation timestamp
	post["last_trade_time"] = Time.get_unix_time_from_system()
	
	# Store trading post
	trading_posts[system_id] = post
	
	# Emit signal
	trading_post_created.emit(system_id, post)
	
	return {"success": true, "cost": post["cost"], "system_name": economy_system.get_system_data(system_id)["name"]}

func remove_trading_post(system_id: String) -> bool:
	if trading_posts.has(system_id):
		trading_posts.erase(system_id)
		return true
	return false

func get_trading_post_status(system_id: String) -> Dictionary:
	if trading_posts.has(system_id):
		return trading_posts[system_id].duplicate()
	return {}

func get_all_trading_posts() -> Dictionary:
	return trading_posts.duplicate()

func update_trading_post_config(system_id: String, new_config: Dictionary) -> bool:
	if not trading_posts.has(system_id):
		return false
	
	var post = trading_posts[system_id]
	
	# Update configuration
	if new_config.has("auto_buy_threshold"):
		post["auto_buy_threshold"] = new_config["auto_buy_threshold"]
	if new_config.has("auto_sell_threshold"):
		post["auto_sell_threshold"] = new_config["auto_sell_threshold"]
	if new_config.has("target_goods"):
		post["target_goods"] = new_config["target_goods"]
	if new_config.has("active"):
		post["active"] = new_config["active"]
	
	trading_post_status_updated.emit(system_id, post)
	return true

func process_automation(delta: float):
	automation_timer += delta
	
	# Process each active trading post (Requirement 5.3)
	for system_id in trading_posts.keys():
		var post = trading_posts[system_id]
		if post["active"]:
			post["trade_timer"] += delta
			
			# Execute trades at regular intervals
			if post["trade_timer"] >= trade_interval:
				post["trade_timer"] = 0.0
				_execute_automated_trades(system_id, post)

func get_total_automation_profit() -> int:
	var total_profit = 0
	for post in trading_posts.values():
		total_profit += post["profit_generated"]
	return total_profit

func get_automation_efficiency() -> float:
	if trading_posts.is_empty():
		return 0.0
	
	var total_efficiency = 0.0
	for post in trading_posts.values():
		total_efficiency += post["efficiency"]
	
	return total_efficiency / trading_posts.size()

func upgrade_automation_efficiency(ai_level: int):
	var new_efficiency = _calculate_efficiency_from_ai_level(ai_level)
	
	for post in trading_posts.values():
		post["efficiency"] = new_efficiency
	
	automation_efficiency_changed.emit(new_efficiency)

func _execute_automated_trades(system_id: String, post: Dictionary):
	if not economy_system:
		return
	
	var total_profit = 0
	var trades_made = 0
	
	# Execute automated trading logic for each target good (Requirement 5.3)
	for good_type in post["target_goods"]:
		var trade_result = _attempt_automated_trade(system_id, good_type, post)
		if trade_result["profit"] != 0:
			total_profit += trade_result["profit"]
			trades_made += 1
			
			# Record trade in history
			post["trade_history"].append({
				"timestamp": Time.get_unix_time_from_system(),
				"good_type": good_type,
				"action": trade_result["action"],
				"quantity": trade_result["quantity"],
				"profit": trade_result["profit"]
			})
			
			# Limit trade history size
			if post["trade_history"].size() > 50:
				post["trade_history"] = post["trade_history"].slice(-50)
			
			# Emit trade signal
			trading_post_trade_executed.emit(system_id, good_type, trade_result["quantity"], trade_result["profit"])
	
	# Update trading post statistics
	if total_profit > 0:
		post["profit_generated"] += total_profit
		post["trades_executed"] += trades_made
		post["last_trade_time"] = Time.get_unix_time_from_system()
		
		# Apply efficiency reduction (automated trading is less efficient than manual)
		var final_profit = int(total_profit * post["efficiency"])
		
		# Emit profit signal (Requirement 5.4)
		automation_profit_generated.emit(final_profit, system_id)
		trading_post_status_updated.emit(system_id, post)

func _attempt_automated_trade(system_id: String, good_type: String, post: Dictionary) -> Dictionary:
	var result = {"action": "none", "quantity": 0, "profit": 0}
	
	if not economy_system:
		return result
	
	# Get current market data
	var market_data = economy_system.get_market_data(system_id, good_type)
	var current_price = market_data["current_price"]
	var average_price = economy_system.get_average_price(good_type)
	
	if average_price <= 0:
		return result
	
	var price_ratio = current_price / average_price
	var current_inventory = post["inventory"].get(good_type, 0)
	var max_cargo = post["cargo_allocation"]
	
	# Auto-buy logic (Requirement 5.2)
	if price_ratio < post["auto_buy_threshold"] and current_inventory < max_cargo:
		var buy_quantity = min(5, max_cargo - current_inventory)  # Buy up to 5 units at a time
		var buy_cost = current_price * buy_quantity
		
		# Simulate buying (trading posts have their own virtual credits)
		post["inventory"][good_type] = current_inventory + buy_quantity
		result = {
			"action": "buy",
			"quantity": buy_quantity,
			"profit": -buy_cost  # Negative profit for buying (cost)
		}
	
	# Auto-sell logic (Requirement 5.2)
	elif price_ratio > post["auto_sell_threshold"] and current_inventory > 0:
		var sell_quantity = min(5, current_inventory)  # Sell up to 5 units at a time
		var sell_revenue = current_price * sell_quantity
		
		# Simulate selling
		post["inventory"][good_type] = current_inventory - sell_quantity
		result = {
			"action": "sell",
			"quantity": sell_quantity,
			"profit": sell_revenue
		}
	
	return result

func _calculate_efficiency_from_ai_level(ai_level: int) -> float:
	# Efficiency increases with AI Core level (Requirement 5.7)
	var efficiency_levels = [0.0, 0.65, 0.72, 0.80, 0.87, 0.92]
	return efficiency_levels[clamp(ai_level, 0, efficiency_levels.size() - 1)]

# Additional functions for trading post management

func get_trading_post_profit_rate(system_id: String) -> float:
	if not trading_posts.has(system_id):
		return 0.0
	
	var post = trading_posts[system_id]
	var current_time = Time.get_unix_time_from_system()
	var time_since_creation = current_time - post.get("last_trade_time", current_time)
	
	if time_since_creation <= 0:
		return 0.0
	
	# Calculate profit per hour
	return (post["profit_generated"] / time_since_creation) * 3600.0

func get_trading_post_recent_activity(system_id: String, limit: int = 10) -> Array:
	if not trading_posts.has(system_id):
		return []
	
	var post = trading_posts[system_id]
	var history = post.get("trade_history", [])
	
	# Return most recent trades
	var start_index = max(0, history.size() - limit)
	return history.slice(start_index)

func get_trading_post_inventory_status(system_id: String) -> Dictionary:
	if not trading_posts.has(system_id):
		return {}
	
	var post = trading_posts[system_id]
	var inventory = post.get("inventory", {})
	var max_cargo = post["cargo_allocation"]
	var total_cargo = 0
	
	for quantity in inventory.values():
		total_cargo += quantity
	
	return {
		"inventory": inventory.duplicate(),
		"total_cargo": total_cargo,
		"max_cargo": max_cargo,
		"cargo_utilization": float(total_cargo) / max_cargo if max_cargo > 0 else 0.0
	}

func get_automation_summary() -> Dictionary:
	var summary = {
		"total_posts": trading_posts.size(),
		"active_posts": 0,
		"total_profit": 0,
		"total_trades": 0,
		"average_efficiency": 0.0
	}
	
	if trading_posts.is_empty():
		return summary
	
	var total_efficiency = 0.0
	
	for post in trading_posts.values():
		if post["active"]:
			summary["active_posts"] += 1
		
		summary["total_profit"] += post["profit_generated"]
		summary["total_trades"] += post["trades_executed"]
		total_efficiency += post["efficiency"]
	
	summary["average_efficiency"] = total_efficiency / trading_posts.size()
	
	return summary

func get_system_trading_recommendations(system_id: String) -> Dictionary:
	if not economy_system:
		return {}
	
	var recommendations = {
		"good_recommendations": [],
		"threshold_suggestions": {}
	}
	
	var system_data = economy_system.get_system_data(system_id)
	if system_data.is_empty():
		return recommendations
	
	# Analyze each available good for trading potential
	for good_type in system_data["goods"].keys():
		var market_data = economy_system.get_market_data(system_id, good_type)
		var average_price = economy_system.get_average_price(good_type)
		
		if average_price > 0:
			var volatility = market_data.get("volatility", 0.1)
			var current_ratio = market_data["current_price"] / average_price
			
			var recommendation = {
				"good_type": good_type,
				"current_price": market_data["current_price"],
				"average_price": average_price,
				"volatility": volatility,
				"trading_potential": "medium"
			}
			
			# Determine trading potential based on volatility and current price
			if volatility > 0.2:
				recommendation["trading_potential"] = "high"
			elif volatility < 0.1:
				recommendation["trading_potential"] = "low"
			
			# Suggest optimal thresholds based on volatility
			recommendations["threshold_suggestions"][good_type] = {
				"suggested_buy_threshold": max(0.6, 1.0 - volatility),
				"suggested_sell_threshold": min(1.8, 1.0 + volatility)
			}
			
			recommendations["good_recommendations"].append(recommendation)
	
	return recommendations
