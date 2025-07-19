extends Node
class_name GameManager

# Core game state signals
signal credits_changed(new_credits: int)
signal fuel_changed(new_fuel: int)
signal cargo_changed(cargo_dict: Dictionary)
signal location_changed(system_id: String)
signal ship_stats_updated(stats: Dictionary)
signal player_data_updated(data: Dictionary)

# System references
@onready var economy_system: EconomySystem
@onready var ship_system: ShipSystem
@onready var artifact_system: ArtifactSystem
@onready var automation_system: AutomationSystem
@onready var event_system: EventSystem

# Enhanced player data structure
var player_data: Dictionary = {
	"version": "1.0",
	"created_at": 0,
	"last_played": 0,
	
	# Core resources
	"credits": 10000,
	"current_system": "terra_prime",
	
	# Ship configuration
	"ship": {
		"name": "Stellar Hauler",
		"cargo_capacity": 50,
		"fuel_capacity": 100,
		"current_fuel": 100,
		"upgrades": {
			"cargo_hold": 0,
			"engine": 0,
			"scanner": 0,
			"ai_core": 0
		},
		"bonuses": {
			"fuel_efficiency": 1.0,
			"travel_speed": 1.0,
			"detection_range": 1,
			"automation_level": 0
		}
	},
	
	# Inventory and cargo
	"inventory": {
		"food": 0,
		"minerals": 0,
		"tech": 0,
		"passengers": 0
	},
	
	# Discovery progress
	"artifacts": [],
	"precursor_lore": {
		"chronovores": {"discovered": false, "lore_fragments": 0},
		"silica_gardens": {"discovered": false, "lore_fragments": 0},
		"void_weavers": {"discovered": false, "lore_fragments": 0}
	},
	
	# Automation
	"trading_posts": {},
	"automation_profits": 0,
	
	# Statistics and achievements
	"statistics": {
		"total_credits_earned": 0,
		"systems_explored": 1,
		"artifacts_found": 0,
		"trades_completed": 0,
		"distance_traveled": 0,
		"automation_efficiency": 0.0,
		"playtime_seconds": 0
	},
	
	# Game state
	"systems_visited": ["terra_prime"],
	"tutorial_completed": false,
	"achievements_unlocked": []
}



func _ready():
	# Initialize systems
	_initialize_systems()
	_connect_system_signals()
	
	# Initialize game state
	player_data.created_at = Time.get_unix_time_from_system()
	player_data.last_played = Time.get_unix_time_from_system()
	
	# Emit initial state signals
	credits_changed.emit(player_data.credits)
	fuel_changed.emit(player_data.ship.current_fuel)
	cargo_changed.emit(player_data.inventory)
	location_changed.emit(player_data.current_system)
	ship_stats_updated.emit(_get_current_ship_stats())
	player_data_updated.emit(player_data)

func _initialize_systems():
	# Create system instances
	economy_system = EconomySystem.new()
	ship_system = ShipSystem.new()
	artifact_system = ArtifactSystem.new()
	automation_system = AutomationSystem.new()
	event_system = EventSystem.new()
	
	# Add systems as children
	add_child(economy_system)
	add_child(ship_system)
	add_child(artifact_system)
	add_child(automation_system)
	add_child(event_system)

func _connect_system_signals():
	# Connect economy system signals
	economy_system.market_prices_updated.connect(_on_market_prices_updated)
	economy_system.trade_executed.connect(_on_trade_executed)
	
	# Connect ship system signals
	ship_system.ship_upgraded.connect(_on_ship_upgraded)
	ship_system.upgrade_purchased.connect(_on_upgrade_purchased)
	
	# Connect artifact system signals
	artifact_system.artifact_discovered.connect(_on_artifact_discovered)
	artifact_system.artifact_collected.connect(_on_artifact_collected)
	artifact_system.precursor_lore_unlocked.connect(_on_precursor_lore_unlocked)
	
	# Connect automation system signals
	automation_system.trading_post_created.connect(_on_trading_post_created)
	automation_system.automation_profit_generated.connect(_on_automation_profit_generated)
	
	# Connect event system signals
	event_system.event_triggered.connect(_on_event_triggered)
	event_system.event_expired.connect(_on_event_expired)

# Core game functions using new systems

# Get total cargo count
func get_total_cargo() -> int:
	var total: int = 0
	for amount in player_data.inventory.values():
		total += amount
	return total

# Buy goods
func buy_good(good_type: String, quantity: int = 1) -> Dictionary:
	var current_system = player_data.current_system
	var price = economy_system.calculate_dynamic_price(current_system, good_type)
	var total_cost = price * quantity
	
	# Check if player can afford and has cargo space
	if player_data.credits < total_cost:
		return {"success": false, "error": "Insufficient credits"}
	
	if get_total_cargo() + quantity > player_data.ship.cargo_capacity:
		return {"success": false, "error": "Insufficient cargo space"}
	
	# Execute trade
	player_data.credits -= total_cost
	if not player_data.inventory.has(good_type):
		player_data.inventory[good_type] = 0
	player_data.inventory[good_type] += quantity
	
	# Update statistics
	player_data.statistics.trades_completed += 1
	player_data.statistics.total_credits_earned -= total_cost  # Negative for purchases
	
	# Execute trade in economy system
	economy_system.execute_trade(current_system, good_type, quantity, true)
	
	# Emit signals
	credits_changed.emit(player_data.credits)
	cargo_changed.emit(player_data.inventory)
	player_data_updated.emit(player_data)
	
	return {"success": true, "cost": total_cost, "quantity": quantity}

# Sell goods
func sell_good(good_type: String, quantity: int = 1) -> Dictionary:
	# Check if player has goods to sell
	if not player_data.inventory.has(good_type) or player_data.inventory[good_type] < quantity:
		return {"success": false, "error": "Insufficient goods to sell"}
	
	var current_system = player_data.current_system
	var price = economy_system.calculate_dynamic_price(current_system, good_type)
	var total_revenue = price * quantity
	
	# Execute trade
	player_data.credits += total_revenue
	player_data.inventory[good_type] -= quantity
	if player_data.inventory[good_type] == 0:
		player_data.inventory.erase(good_type)
	
	# Update statistics
	player_data.statistics.trades_completed += 1
	player_data.statistics.total_credits_earned += total_revenue
	
	# Execute trade in economy system
	economy_system.execute_trade(current_system, good_type, quantity, false)
	
	# Emit signals
	credits_changed.emit(player_data.credits)
	cargo_changed.emit(player_data.inventory)
	player_data_updated.emit(player_data)
	
	return {"success": true, "revenue": total_revenue, "quantity": quantity}

# Travel to system
func travel_to_system(system_id: String) -> Dictionary:
	if system_id == player_data.current_system:
		return {"success": false, "error": "Already at destination"}
	
	var fuel_cost = economy_system.get_travel_cost(player_data.current_system, system_id)
	var ship_efficiency = player_data.ship.bonuses.fuel_efficiency
	var final_fuel_cost = ship_system.calculate_travel_cost(player_data.current_system, system_id, fuel_cost, ship_efficiency)
	
	# Apply event modifiers
	var event_modifier = event_system.get_fuel_cost_modifier()
	final_fuel_cost = int(final_fuel_cost * event_modifier)
	
	if player_data.ship.current_fuel < final_fuel_cost:
		return {"success": false, "error": "Insufficient fuel"}
	
	# Execute travel
	player_data.ship.current_fuel -= final_fuel_cost
	player_data.current_system = system_id
	
	# Update statistics
	player_data.statistics.distance_traveled += fuel_cost
	if not player_data.systems_visited.has(system_id):
		player_data.systems_visited.append(system_id)
		player_data.statistics.systems_explored += 1
	
	# Attempt artifact discovery
	_attempt_artifact_discovery(system_id)
	
	# Emit signals
	fuel_changed.emit(player_data.ship.current_fuel)
	location_changed.emit(player_data.current_system)
	player_data_updated.emit(player_data)
	
	return {"success": true, "fuel_cost": final_fuel_cost}

# Refuel ship
func refuel_ship() -> Dictionary:
	var fuel_needed = player_data.ship.fuel_capacity - player_data.ship.current_fuel
	var refuel_cost = fuel_needed * 2
	
	if player_data.credits < refuel_cost:
		return {"success": false, "error": "Insufficient credits"}
	
	if fuel_needed <= 0:
		return {"success": false, "error": "Fuel tank already full"}
	
	player_data.credits -= refuel_cost
	player_data.ship.current_fuel = player_data.ship.fuel_capacity
	
	credits_changed.emit(player_data.credits)
	fuel_changed.emit(player_data.ship.current_fuel)
	player_data_updated.emit(player_data)
	
	return {"success": true, "cost": refuel_cost, "fuel_added": fuel_needed}

# Get current system data
func get_current_system() -> Dictionary:
	return economy_system.get_system_data(player_data.current_system)

# Get available destinations
func get_available_destinations() -> Array:
	var destinations: Array = []
	var all_systems = economy_system.get_all_systems()
	
	for system_id in all_systems.keys():
		if system_id != player_data.current_system:
			var system_data = all_systems[system_id]
			var fuel_cost = economy_system.get_travel_cost(player_data.current_system, system_id)
			var ship_efficiency = player_data.ship.bonuses.fuel_efficiency
			var final_fuel_cost = ship_system.calculate_travel_cost(player_data.current_system, system_id, fuel_cost, ship_efficiency)
			
			destinations.append({
				"id": system_id,
				"name": system_data["name"],
				"fuel_cost": final_fuel_cost,
				"can_travel": player_data.ship.current_fuel >= final_fuel_cost
			})
	
	return destinations

# Get current ship stats
func _get_current_ship_stats() -> Dictionary:
	return ship_system.get_ship_stats(player_data.ship)

# Attempt artifact discovery when visiting systems
func _attempt_artifact_discovery(system_id: String):
	var scanner_level = player_data.ship.upgrades.scanner
	var discovery_result = artifact_system.attempt_discovery(system_id, scanner_level)
	
	if not discovery_result.is_empty():
		# Artifact discovered!
		var collect_result = artifact_system.collect_artifact(discovery_result.artifact_id)
		if collect_result.success:
			player_data.artifacts.append(discovery_result.artifact_id)
			player_data.statistics.artifacts_found += 1
			
			# Update ship bonuses from artifact effects
			_apply_artifact_bonuses()

# Apply artifact bonuses to ship stats
func _apply_artifact_bonuses():
	var bonuses = artifact_system.get_active_bonuses()
	
	# Apply bonuses to ship stats
	player_data.ship.bonuses.fuel_efficiency = 1.0 - bonuses.get("fuel_efficiency_bonus", 0.0)
	player_data.ship.bonuses.travel_speed = 1.0 + bonuses.get("travel_speed_bonus", 0.0)
	
	ship_stats_updated.emit(_get_current_ship_stats())

# System signal handlers
func _on_market_prices_updated(system_id: String, prices: Dictionary):
	# Market prices updated - UI can respond to this
	pass

func _on_trade_executed(system_id: String, good_type: String, quantity: int, is_buying: bool, profit: int):
	# Trade executed in economy system
	pass

func _on_ship_upgraded(upgrade_type: String, new_level: int, effects: Dictionary):
	# Ship upgrade completed
	player_data.ship.upgrades[upgrade_type] = new_level
	
	# Apply upgrade effects to ship bonuses
	for effect_key in effects.keys():
		if player_data.ship.bonuses.has(effect_key):
			player_data.ship.bonuses[effect_key] = effects[effect_key]
	
	ship_stats_updated.emit(_get_current_ship_stats())
	player_data_updated.emit(player_data)

func _on_upgrade_purchased(upgrade_type: String, cost: int):
	# Upgrade purchased - deduct credits
	player_data.credits -= cost
	credits_changed.emit(player_data.credits)

func _on_artifact_discovered(artifact_id: String, system_id: String, lore_fragment: String):
	# Artifact discovered
	pass

func _on_artifact_collected(artifact_id: String, effects: Dictionary):
	# Artifact collected and effects applied
	_apply_artifact_bonuses()

func _on_precursor_lore_unlocked(civilization: String, lore_text: String):
	# New precursor lore unlocked
	player_data.precursor_lore[civilization]["discovered"] = true
	player_data.precursor_lore[civilization]["lore_fragments"] += 1

func _on_trading_post_created(system_id: String, config: Dictionary):
	# Trading post created
	player_data.trading_posts[system_id] = config

func _on_automation_profit_generated(amount: int, source: String):
	# Automation generated profit
	player_data.credits += amount
	player_data.automation_profits += amount
	player_data.statistics.total_credits_earned += amount
	credits_changed.emit(player_data.credits)

func _on_event_triggered(event_type: String, duration: float, effects: Dictionary):
	# Dynamic event triggered
	pass

func _on_event_expired(event_type: String):
	# Dynamic event expired
	pass
