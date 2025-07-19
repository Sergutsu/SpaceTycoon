extends Node
class_name AutomationSystem

# Automation system signals
signal trading_post_created(system_id: String, config: Dictionary)
signal automation_profit_generated(amount: int, source: String)
signal trading_post_status_updated(system_id: String, status: Dictionary)
signal automation_efficiency_changed(new_efficiency: float)

# Trading posts data
var trading_posts: Dictionary = {}
var automation_timer: float = 0.0
var trade_interval: float = 30.0  # Execute trades every 30 seconds

# Trading post template
var trading_post_template: Dictionary = {
	"cost": 50000,
	"efficiency": 0.7,  # 70% of manual trading profit
	"cargo_allocation": 20,
	"auto_buy_threshold": 0.8,  # Buy when price < 80% of average
	"auto_sell_threshold": 1.2,  # Sell when price > 120% of average
	"target_goods": ["food", "minerals"],
	"active": true,
	"profit_generated": 0,
	"trades_executed": 0,
	"trade_timer": 0.0
}

func _ready():
	# Start automation processing
	set_process(true)

func _process(delta):
	process_automation(delta)

func can_create_trading_post(system_id: String, ai_level: int, credits: int) -> bool:
	return (ai_level >= 1 and 
			credits >= trading_post_template.cost and
			not trading_posts.has(system_id))

func create_trading_post(system_id: String, config: Dictionary) -> Dictionary:
	if not can_create_trading_post(system_id, config.get("ai_level", 0), config.get("credits", 0)):
		return {"success": false, "error": "Cannot create trading post"}
	
	var post = trading_post_template.duplicate(true)
	
	# Apply custom configuration
	if config.has("cargo_allocation"):
		post["cargo_allocation"] = config["cargo_allocation"]
	if config.has("auto_buy_threshold"):
		post["auto_buy_threshold"] = config["auto_buy_threshold"]
	if config.has("auto_sell_threshold"):
		post["auto_sell_threshold"] = config["auto_sell_threshold"]
	if config.has("target_goods"):
		post["target_goods"] = config["target_goods"]
	if config.has("ai_level"):
		post["efficiency"] = _calculate_efficiency_from_ai_level(config["ai_level"])
	
	trading_posts[system_id] = post
	
	# Emit signal
	trading_post_created.emit(system_id, post)
	
	return {"success": true, "cost": post["cost"]}

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
	
	for system_id in trading_posts.keys():
		var post = trading_posts[system_id]
		if post["active"]:
			post["trade_timer"] += delta
			
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
	# This would integrate with EconomySystem to execute actual trades
	# For now, simulate basic trading logic
	
	var simulated_profit = _simulate_trading_profit(system_id, post)
	if simulated_profit > 0:
		post["profit_generated"] += simulated_profit
		post["trades_executed"] += 1
		automation_profit_generated.emit(simulated_profit, system_id)
		trading_post_status_updated.emit(system_id, post)

@warning_ignore("unused_parameter")
func _simulate_trading_profit(system_id: String, post: Dictionary) -> int:
	# Simple simulation - would be replaced with actual market integration
	var base_profit = 100
	var efficiency_modifier = post["efficiency"]
	var cargo_modifier = post["cargo_allocation"] / 50.0  # Normalize to 50 cargo
	
	# Add some randomness
	var random_factor = randf_range(0.5, 1.5)
	
	return int(base_profit * efficiency_modifier * cargo_modifier * random_factor)

func _calculate_efficiency_from_ai_level(ai_level: int) -> float:
	var efficiency_levels = [0.0, 0.7, 0.8, 0.9, 0.95, 1.0]
	return efficiency_levels[clamp(ai_level, 0, efficiency_levels.size() - 1)]
