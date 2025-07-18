extends Node
class_name GameManager

# Game state signals
signal credits_changed(new_credits: int)
signal fuel_changed(new_fuel: int)
signal cargo_changed(cargo_dict: Dictionary)
signal location_changed(planet_id: String)

# Game state variables
var credits: int = 10000
var fuel: int = 100
var max_fuel: int = 100
var cargo_capacity: int = 50
var cargo: Dictionary = {}
var current_location: String = "terra"

# Ship properties
var ship_data: Dictionary = {
	"name": "Stellar Hauler",
	"speed": 1.0,
	"fuel_efficiency": 1.0,
	"cargo_capacity": 50
}

# Planet data structure
var planets: Dictionary = {
	"terra": {
		"name": "Terra Prime",
		"description": "Agricultural world known for its fertile lands and food production.",
		"position": Vector2(200, 150),
		"goods": {
			"food": {"base_price": 10, "supply": "high", "demand": "low"},
			"minerals": {"base_price": 50, "supply": "low", "demand": "high"},
			"passengers": {"base_price": 25, "supply": "medium", "demand": "medium"}
		}
	},
	"minerva": {
		"name": "Minerva Station", 
		"description": "Industrial mining colony rich in rare minerals and metals.",
		"position": Vector2(800, 300),
		"goods": {
			"food": {"base_price": 20, "supply": "low", "demand": "high"},
			"minerals": {"base_price": 30, "supply": "high", "demand": "low"},
			"passengers": {"base_price": 15, "supply": "low", "demand": "medium"}
		}
	},
	"luxuria": {
		"name": "Luxuria Resort",
		"description": "Luxury tourist destination attracting wealthy travelers from across the galaxy.",
		"position": Vector2(500, 550),
		"goods": {
			"food": {"base_price": 30, "supply": "medium", "demand": "high"},
			"minerals": {"base_price": 40, "supply": "medium", "demand": "medium"},
			"passengers": {"base_price": 50, "supply": "high", "demand": "low"}
		}
	}
}

# Travel distances (fuel costs)
var travel_distances: Dictionary = {
	"terra": {"minerva": 15, "luxuria": 12},
	"minerva": {"terra": 15, "luxuria": 18},
	"luxuria": {"terra": 12, "minerva": 18}
}

func _ready():
	# Initialize game state
	emit_signal("credits_changed", credits)
	emit_signal("fuel_changed", fuel)
	emit_signal("cargo_changed", cargo)
	emit_signal("location_changed", current_location)

# Calculate dynamic price based on supply/demand
func calculate_price(base_price: int, supply: String, demand: String, is_buying: bool = true) -> int:
	var multiplier: float = 1.0
	
	if is_buying:
		# Player buying - higher demand = higher price, higher supply = lower price
		match supply:
			"high": multiplier *= 0.8
			"low": multiplier *= 1.3
		match demand:
			"high": multiplier *= 1.2
			"low": multiplier *= 0.9
	else:
		# Player selling - higher demand = higher price for player
		match demand:
			"high": multiplier *= 1.4
			"low": multiplier *= 0.7
		match supply:
			"high": multiplier *= 0.8
			"low": multiplier *= 1.1
	
	return int(base_price * multiplier)

# Get total cargo count
func get_total_cargo() -> int:
	var total: int = 0
	for amount in cargo.values():
		total += amount
	return total

# Buy goods
func buy_good(good_type: String, price: int) -> bool:
	if credits >= price and get_total_cargo() < cargo_capacity:
		credits -= price
		if not cargo.has(good_type):
			cargo[good_type] = 0
		cargo[good_type] += 1
		
		emit_signal("credits_changed", credits)
		emit_signal("cargo_changed", cargo)
		return true
	return false

# Sell goods
func sell_good(good_type: String, price: int) -> bool:
	if cargo.has(good_type) and cargo[good_type] > 0:
		credits += price
		cargo[good_type] -= 1
		if cargo[good_type] == 0:
			cargo.erase(good_type)
		
		emit_signal("credits_changed", credits)
		emit_signal("cargo_changed", cargo)
		return true
	return false

# Travel to planet
func travel_to_planet(planet_id: String) -> bool:
	if planet_id == current_location:
		return false
		
	var fuel_cost: int = travel_distances[current_location][planet_id]
	if fuel >= fuel_cost:
		fuel -= fuel_cost
		current_location = planet_id
		
		emit_signal("fuel_changed", fuel)
		emit_signal("location_changed", current_location)
		return true
	return false

# Refuel ship
func refuel_ship() -> bool:
	var fuel_needed: int = max_fuel - fuel
	var refuel_cost: int = fuel_needed * 2
	
	if credits >= refuel_cost and fuel < max_fuel:
		credits -= refuel_cost
		fuel = max_fuel
		
		emit_signal("credits_changed", credits)
		emit_signal("fuel_changed", fuel)
		return true
	return false

# Get refuel cost
func get_refuel_cost() -> int:
	return (max_fuel - fuel) * 2

# Get current planet data
func get_current_planet() -> Dictionary:
	return planets[current_location]

# Get available destinations
func get_available_destinations() -> Array:
	var destinations: Array = []
	for planet_id in planets.keys():
		if planet_id != current_location:
			destinations.append({
				"id": planet_id,
				"name": planets[planet_id]["name"],
				"fuel_cost": travel_distances[current_location][planet_id]
			})
	return destinations
