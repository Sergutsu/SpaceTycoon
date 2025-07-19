extends Node
class_name SystemTest

# Simple test script to verify system integration
func test_systems():
	print("Testing enhanced system architecture...")
	
	# Test EconomySystem
	var economy = EconomySystem.new()
	var price = economy.calculate_dynamic_price("terra_prime", "food")
	print("Terra Prime food price: ", price)
	assert(price > 0, "Price should be positive")
	
	# Test ShipSystem
	var ship = ShipSystem.new()
	var can_afford = ship.can_afford_upgrade("cargo_hold", 0, 10000)
	print("Can afford cargo upgrade: ", can_afford)
	assert(can_afford == true, "Should be able to afford first cargo upgrade")
	
	# Test ArtifactSystem
	var artifacts = ArtifactSystem.new()
	var discovery = artifacts.attempt_discovery("frontier_outpost", 1)
	print("Artifact discovery attempt: ", discovery)
	
	# Test AutomationSystem
	var automation = AutomationSystem.new()
	var can_create = automation.can_create_trading_post("nexus_station", 1, 100000)
	print("Can create trading post: ", can_create)
	assert(can_create == true, "Should be able to create trading post with sufficient resources")
	
	# Test EventSystem
	var events = EventSystem.new()
	var event_result = events.trigger_event("solar_flare")
	print("Event triggered: ", event_result)
	assert(event_result.success == true, "Event should trigger successfully")
	
	print("All system tests passed!")

func _ready():
	test_systems()