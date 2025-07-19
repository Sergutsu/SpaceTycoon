# Space Transport Tycoon MVP Enhancement - Design Document

## Overview

This design document outlines the technical architecture and implementation approach for transforming the current 3-planet Space Transport Tycoon prototype into a compelling MVP. The enhancement focuses on expanding the galaxy, implementing ship progression systems, introducing artifact discovery mechanics, and establishing the foundation for automation features while maintaining the game's core identity as a progressive idle strategy experience.

The MVP will provide 2-4 hours of engaging gameplay that demonstrates the unique progression from active trading to automated empire management, setting the foundation for future cosmic-scale features.

## Architecture

### System Architecture Overview

The enhanced game follows a modular, signal-driven architecture built on Godot 4.4's scene system. The design separates concerns into specialized systems that communicate through Godot's signal mechanism, ensuring loose coupling and maintainability.

```gdscript
# Core architecture structure
Main (Control)
├── GameManager (Node) - Central orchestration
├── EconomySystem (Node) - Market dynamics and trading
├── ShipSystem (Node) - Upgrades and travel mechanics  
├── ArtifactSystem (Node) - Discovery and effects
├── AutomationSystem (Node) - Trading posts and AI
├── EventSystem (Node) - Dynamic events and variety
├── SaveSystem (Node) - Data persistence
└── MainUI (Control) - User interface controller
```

### Signal-Driven Communication

All systems communicate through signals to maintain decoupling:

```gdscript
# GameManager signals
signal credits_changed(new_credits: int)
signal location_changed(new_system: String)
signal ship_upgraded(upgrade_type: String, level: int)
signal artifact_discovered(artifact_id: String, system_id: String)
signal trading_post_created(system_id: String)
signal event_triggered(event_type: String, duration: float)

# System-specific signals
signal market_prices_updated(system_id: String, prices: Dictionary)
signal automation_profit_generated(amount: int, source: String)
signal discovery_chance_calculated(system_id: String, chance: float)
```

### Data Management Strategy

The game uses a centralized data structure with system-specific managers:

```gdscript
# Enhanced player data structure
var player_data = {
    "credits": 10000,
    "current_system": "terra_prime",
    "ship": {
        "cargo_capacity": 50,
        "fuel_capacity": 100,
        "current_fuel": 100,
        "upgrades": {
            "cargo_hold": 0,
            "engine": 0, 
            "scanner": 0,
            "ai_core": 0
        }
    },
    "inventory": {},
    "artifacts": [],
    "trading_posts": {},
    "statistics": {
        "total_credits_earned": 0,
        "systems_explored": 1,
        "artifacts_found": 0,
        "trades_completed": 0,
        "automation_efficiency": 0.0
    }
}
```

## Components and Interfaces

### Enhanced Galaxy Map System

**Purpose**: Expand from 3 to 5 unique star systems with distinct characteristics and strategic value.

**Implementation**:
```gdscript
class_name GalaxyMapSystem
extends Node

var star_systems = {
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
        }
    }
}

func calculate_travel_cost(from: String, to: String, ship_efficiency: float) -> int:
    var base_cost = star_systems[from]["travel_costs"][to]
    return int(base_cost * ship_efficiency)

func get_system_tooltip(system_id: String) -> String:
    var system = star_systems[system_id]
    return "%s\nRisk: %s\nSpecial: %s" % [
        system.name,
        system.risk_level.capitalize(),
        ", ".join(system.special_features)
    ]
```

**Interface Requirements**:
- Visual galaxy map with clickable systems
- Hover tooltips showing travel costs and system info
- Travel button state management based on fuel availability
- Visual indicators for explored vs unexplored systems

### Ship Upgrade System

**Purpose**: Provide meaningful progression through four upgrade categories that affect different aspects of gameplay.

**Implementation**:
```gdscript
class_name ShipUpgradeSystem
extends Node

var upgrade_definitions = {
    "cargo_hold": {
        "name": "Cargo Hold",
        "description": "Increases ship cargo capacity",
        "levels": [50, 75, 100, 150, 200, 300],
        "costs": [0, 5000, 12000, 25000, 50000, 100000],
        "max_level": 5
    },
    "engine": {
        "name": "Engine System",
        "description": "Improves fuel efficiency and travel speed",
        "fuel_efficiency": [1.0, 0.9, 0.8, 0.7, 0.6, 0.5],
        "speed_multiplier": [1.0, 1.2, 1.5, 1.8, 2.2, 2.5],
        "costs": [0, 8000, 18000, 35000, 70000, 150000],
        "max_level": 5
    },
    "scanner": {
        "name": "Deep Space Scanner",
        "description": "Increases artifact detection range and accuracy",
        "detection_range": [1, 2, 3, 4, 5, 6],
        "detection_chance": [0.05, 0.10, 0.15, 0.22, 0.30, 0.40],
        "costs": [0, 3000, 8000, 18000, 40000, 80000],
        "max_level": 5
    },
    "ai_core": {
        "name": "AI Core",
        "description": "Enables automation features and market analysis",
        "automation_level": [0, 1, 2, 3, 4, 5],
        "efficiency_bonus": [0.0, 0.7, 0.8, 0.9, 0.95, 1.0],
        "costs": [0, 15000, 35000, 75000, 150000, 300000],
        "max_level": 5
    }
}

func can_afford_upgrade(upgrade_type: String, current_level: int, credits: int) -> bool:
    if current_level >= upgrade_definitions[upgrade_type]["max_level"]:
        return false
    var cost = upgrade_definitions[upgrade_type]["costs"][current_level + 1]
    return credits >= cost

func apply_upgrade(upgrade_type: String, new_level: int) -> Dictionary:
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
```

**Interface Requirements**:
- Upgrade shop interface at Nexus Station
- Visual representation of current vs next level benefits
- Cost display with affordability indicators
- Immediate stat updates after purchase

### Artifact Discovery System

**Purpose**: Provide long-term goals and meaningful bonuses through discovery of ancient precursor artifacts.

**Implementation**:
```gdscript
class_name ArtifactSystem
extends Node

var precursor_civilizations = {
    "chronovores": {
        "name": "The Chronovores",
        "lore": "Masters of time who consumed temporal energy until they forgot to exist in the present",
        "discovered": false,
        "artifacts": {
            "temporal_fragment": {
                "name": "Temporal Fragment",
                "rarity": "common",
                "effect_type": "travel_speed",
                "magnitude": 0.15,
                "description": "A crystallized moment that makes journeys feel shorter",
                "lore": "Time itself seems to bend around this strange crystal..."
            },
            "chronos_anchor": {
                "name": "Chronos Anchor",
                "rarity": "rare",
                "effect_type": "global_efficiency",
                "magnitude": 0.25,
                "description": "Accelerates all ship operations by anchoring to stable timestreams",
                "lore": "The Chronovores used these to maintain temporal stability in their cities"
            }
        }
    },
    "silica_gardens": {
        "name": "The Silica Gardens",
        "lore": "Terraformers who grew planets like flowers until their creations gained consciousness and screamed",
        "discovered": false,
        "artifacts": {
            "genesis_seed": {
                "name": "Genesis Seed",
                "rarity": "common", 
                "effect_type": "market_bonus",
                "magnitude": 0.20,
                "description": "Enhances planetary resource generation and trade efficiency",
                "lore": "A seed that could grow entire ecosystems in moments"
            },
            "world_shaper": {
                "name": "World Shaper",
                "rarity": "rare",
                "effect_type": "new_routes",
                "magnitude": 1.0,
                "description": "Reveals hidden hyperspace routes between systems",
                "lore": "The Gardens used these tools to sculpt reality itself"
            }
        }
    },
    "void_weavers": {
        "name": "The Void Weavers", 
        "lore": "Space-time architects who knitted dark matter into dreams and nightmares",
        "discovered": false,
        "artifacts": {
            "space_fold": {
                "name": "Space Fold Device",
                "rarity": "common",
                "effect_type": "fuel_efficiency", 
                "magnitude": 0.20,
                "description": "Bends space to make distant places closer",
                "lore": "The Weavers folded space like origami to travel instantly"
            },
            "reality_loom": {
                "name": "Reality Loom",
                "rarity": "rare",
                "effect_type": "wormhole_access",
                "magnitude": 1.0,
                "description": "Creates temporary wormholes for instant travel",
                "lore": "A device that weaves the fabric of space-time itself"
            }
        }
    }
}

func attempt_discovery(system_id: String, scanner_level: int) -> Dictionary:
    var base_chance = upgrade_definitions["scanner"]["detection_chance"][scanner_level]
    var system_modifier = _get_system_discovery_modifier(system_id)
    var final_chance = base_chance * system_modifier
    
    if randf() < final_chance:
        return _generate_artifact_discovery(system_id)
    
    return {}

func apply_artifact_effects(artifact_id: String, player_stats: Dictionary):
    var artifact = _find_artifact_by_id(artifact_id)
    match artifact.effect_type:
        "travel_speed":
            player_stats.travel_speed_bonus += artifact.magnitude
        "global_efficiency":
            player_stats.efficiency_multiplier += artifact.magnitude
        "market_bonus":
            player_stats.trade_bonus += artifact.magnitude
        "fuel_efficiency":
            player_stats.fuel_efficiency_bonus += artifact.magnitude
```

**Interface Requirements**:
- Discovery notification system with lore presentation
- Artifact collection viewer with effects display
- Integration with ship stats to show active bonuses
- Precursor civilization lore progression tracking

### Basic Automation System

**Purpose**: Introduce the foundation of idle mechanics through automated trading posts.

**Implementation**:
```gdscript
class_name AutomationSystem
extends Node

var trading_post_template = {
    "cost": 50000,
    "efficiency": 0.7,  # 70% of manual trading profit
    "cargo_allocation": 20,
    "auto_buy_threshold": 0.8,  # Buy when price < 80% of average
    "auto_sell_threshold": 1.2,  # Sell when price > 120% of average
    "target_goods": ["food", "minerals"],
    "active": true,
    "profit_generated": 0,
    "trades_executed": 0
}

func can_create_trading_post(system_id: String, ai_level: int, credits: int) -> bool:
    return (ai_level >= 1 and 
            credits >= trading_post_template.cost and
            not trading_posts.has(system_id))

func create_trading_post(system_id: String, config: Dictionary) -> bool:
    if not can_create_trading_post(system_id, config.ai_level, config.credits):
        return false
    
    var post = trading_post_template.duplicate(true)
    post.merge(config, true)
    trading_posts[system_id] = post
    
    trading_post_created.emit(system_id)
    return true

func process_automation(delta: float):
    for system_id in trading_posts.keys():
        var post = trading_posts[system_id]
        if post.active:
            _execute_automated_trades(system_id, post, delta)

func _execute_automated_trades(system_id: String, post: Dictionary, delta: float):
    var trade_interval = 30.0  # Execute trades every 30 seconds
    post.trade_timer += delta
    
    if post.trade_timer >= trade_interval:
        post.trade_timer = 0.0
        
        for good_type in post.target_goods:
            var market_data = economy_system.get_market_data(system_id, good_type)
            var average_price = economy_system.get_average_price(good_type)
            
            # Auto-buy logic
            if market_data.current_price < (average_price * post.auto_buy_threshold):
                var profit = _execute_auto_buy(system_id, good_type, post)
                if profit > 0:
                    post.profit_generated += profit
                    post.trades_executed += 1
                    automation_profit_generated.emit(profit, system_id)
            
            # Auto-sell logic
            elif market_data.current_price > (average_price * post.auto_sell_threshold):
                var profit = _execute_auto_sell(system_id, good_type, post)
                if profit > 0:
                    post.profit_generated += profit
                    post.trades_executed += 1
                    automation_profit_generated.emit(profit, system_id)
```

**Interface Requirements**:
- Trading post creation interface with configuration options
- Status monitoring for active trading posts
- Profit tracking and performance metrics
- Automation efficiency display based on AI Core level

### Enhanced Economic System

**Purpose**: Create dynamic, responsive markets that react to player actions and external events.

**Implementation**:
```gdscript
class_name EconomySystem
extends Node

var market_history = {}
var supply_demand_factors = {}

func calculate_dynamic_price(system_id: String, good_type: String) -> int:
    var base_price = star_systems[system_id]["goods"][good_type]["base_price"]
    var volatility = star_systems[system_id]["goods"][good_type]["volatility"]
    
    # Apply supply/demand modifiers
    var supply_demand = supply_demand_factors.get(system_id + "_" + good_type, 1.0)
    
    # Apply random market fluctuation
    var random_factor = 1.0 + (randf_range(-volatility, volatility))
    
    # Apply event modifiers
    var event_modifier = event_system.get_price_modifier(system_id, good_type)
    
    # Apply artifact bonuses
    var artifact_bonus = artifact_system.get_trade_bonus(good_type)
    
    var final_price = base_price * supply_demand * random_factor * event_modifier * (1.0 + artifact_bonus)
    return max(1, int(final_price))

func execute_trade(system_id: String, good_type: String, quantity: int, is_buying: bool):
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
    
    market_prices_updated.emit(system_id, get_system_prices(system_id))

func get_market_prediction(good_type: String, ai_level: int) -> Dictionary:
    if ai_level < 2:
        return {}
    
    var prediction_accuracy = 0.6 + (ai_level * 0.1)  # 60-90% accuracy
    var trend_data = _analyze_market_trends(good_type)
    
    return {
        "predicted_direction": trend_data.direction,
        "confidence": prediction_accuracy,
        "time_horizon": "next_hour"
    }
```

## Data Models

### Player Data Structure
```gdscript
# Comprehensive player data model
var player_data = {
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
```

### Market Data Structure
```gdscript
# Market state tracking
var market_data = {
    "system_id": {
        "good_type": {
            "current_price": 0,
            "base_price": 0,
            "price_history": [],
            "supply_level": 1.0,
            "demand_level": 1.0,
            "volatility": 0.1,
            "last_updated": 0
        }
    }
}
```

### Event Data Structure
```gdscript
# Active events tracking
var active_events = [
    {
        "type": "solar_flare",
        "start_time": 0,
        "duration": 300,
        "affected_systems": ["frontier_outpost"],
        "effects": {
            "fuel_cost_multiplier": 1.5,
            "scanner_efficiency": 0.5
        },
        "description": "Solar activity disrupts navigation systems"
    }
]
```

## Error Handling

### Save System Error Handling
```gdscript
func save_game() -> bool:
    try:
        var save_data = _compile_save_data()
        var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
        
        if file == null:
            push_error("Failed to open save file for writing")
            return false
        
        file.store_string(JSON.stringify(save_data))
        file.close()
        return true
        
    except:
        push_error("Save operation failed: " + str(error))
        return false

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_FILE):
        print("No save file found, starting new game")
        return false
    
    try:
        var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
        if file == null:
            push_error("Failed to open save file for reading")
            return false
        
        var json_text = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        var parse_result = json.parse(json_text)
        
        if parse_result != OK:
            push_error("Save file corrupted, starting new game")
            return false
        
        _restore_game_state(json.data)
        return true
        
    except:
        push_error("Load operation failed: " + str(error))
        return false
```

### Market System Error Handling
```gdscript
func execute_trade(system_id: String, good_type: String, quantity: int, is_buying: bool) -> Dictionary:
    # Validate inputs
    if not star_systems.has(system_id):
        return {"success": false, "error": "Invalid system ID"}
    
    if not star_systems[system_id]["goods"].has(good_type):
        return {"success": false, "error": "Good not available in this system"}
    
    if quantity <= 0:
        return {"success": false, "error": "Invalid quantity"}
    
    # Check player resources
    if is_buying:
        var total_cost = calculate_trade_cost(system_id, good_type, quantity)
        if player_data.credits < total_cost:
            return {"success": false, "error": "Insufficient credits"}
        
        if get_available_cargo_space() < quantity:
            return {"success": false, "error": "Insufficient cargo space"}
    else:
        if player_data.inventory.get(good_type, 0) < quantity:
            return {"success": false, "error": "Insufficient goods to sell"}
    
    # Execute trade
    try:
        _process_trade_transaction(system_id, good_type, quantity, is_buying)
        return {"success": true, "profit": calculate_profit(system_id, good_type, quantity, is_buying)}
    except:
        return {"success": false, "error": "Trade execution failed"}
```

### Upgrade System Error Handling
```gdscript
func purchase_upgrade(upgrade_type: String) -> Dictionary:
    if not upgrade_definitions.has(upgrade_type):
        return {"success": false, "error": "Invalid upgrade type"}
    
    var current_level = player_data.ship.upgrades[upgrade_type]
    var max_level = upgrade_definitions[upgrade_type]["max_level"]
    
    if current_level >= max_level:
        return {"success": false, "error": "Upgrade already at maximum level"}
    
    var cost = upgrade_definitions[upgrade_type]["costs"][current_level + 1]
    if player_data.credits < cost:
        return {"success": false, "error": "Insufficient credits"}
    
    # Apply upgrade
    player_data.credits -= cost
    player_data.ship.upgrades[upgrade_type] += 1
    
    var effects = apply_upgrade_effects(upgrade_type, current_level + 1)
    ship_upgraded.emit(upgrade_type, current_level + 1)
    
    return {"success": true, "new_level": current_level + 1, "effects": effects}
```

## Testing Strategy

### Unit Testing Approach
```gdscript
# Example test structure for core systems
extends GutTest

func test_market_price_calculation():
    var economy = EconomySystem.new()
    var base_price = 100
    var volatility = 0.1
    
    # Test normal price calculation
    var price = economy.calculate_dynamic_price("terra_prime", "food")
    assert_true(price > 0, "Price should be positive")
    assert_true(price >= base_price * 0.8, "Price shouldn't drop too low")
    assert_true(price <= base_price * 1.2, "Price shouldn't rise too high")

func test_ship_upgrade_system():
    var ship_system = ShipUpgradeSystem.new()
    var initial_capacity = 50
    
    # Test cargo upgrade
    var result = ship_system.purchase_upgrade("cargo_hold")
    assert_true(result.success, "Upgrade should succeed with sufficient credits")
    assert_gt(result.effects.cargo_capacity, initial_capacity, "Capacity should increase")

func test_artifact_discovery():
    var artifact_system = ArtifactSystem.new()
    
    # Test discovery with different scanner levels
    for scanner_level in range(1, 6):
        var discovery = artifact_system.attempt_discovery("frontier_outpost", scanner_level)
        # Higher scanner levels should have better discovery rates
        # (This would need statistical testing over multiple runs)

func test_automation_system():
    var automation = AutomationSystem.new()
    var config = {
        "ai_level": 2,
        "credits": 100000,
        "auto_buy_threshold": 0.8,
        "auto_sell_threshold": 1.2
    }
    
    var result = automation.create_trading_post("nexus_station", config)
    assert_true(result, "Trading post creation should succeed")
    assert_true(automation.trading_posts.has("nexus_station"), "Trading post should be registered")
```

### Integration Testing
```gdscript
# Test system interactions
func test_full_trading_workflow():
    # Setup game state
    var game_manager = GameManager.new()
    game_manager._ready()
    
    # Test complete trading cycle
    var initial_credits = game_manager.player_data.credits
    
    # Travel to system
    game_manager.travel_to_system("minerva_station")
    assert_eq(game_manager.player_data.current_system, "minerva_station")
    
    # Buy goods
    var buy_result = game_manager.buy_good("minerals", 10)
    assert_true(buy_result.success, "Purchase should succeed")
    assert_lt(game_manager.player_data.credits, initial_credits, "Credits should decrease")
    
    # Travel to another system
    game_manager.travel_to_system("terra_prime")
    
    # Sell goods
    var sell_result = game_manager.sell_good("minerals", 10)
    assert_true(sell_result.success, "Sale should succeed")
    
    # Verify profit
    var final_credits = game_manager.player_data.credits
    var profit = final_credits - initial_credits + buy_result.cost - sell_result.revenue
    assert_gt(profit, 0, "Should make profit from trade")

func test_artifact_effects_integration():
    var game_manager = GameManager.new()
    game_manager._ready()
    
    # Simulate artifact discovery
    var artifact_id = "temporal_fragment"
    game_manager.artifact_system.add_artifact(artifact_id)
    
    # Test that artifact effects are applied
    var travel_time_before = game_manager.calculate_travel_time("terra_prime", "nexus_station")
    game_manager.artifact_system.apply_artifact_effects(artifact_id, game_manager.player_data)
    var travel_time_after = game_manager.calculate_travel_time("terra_prime", "nexus_station")
    
    assert_lt(travel_time_after, travel_time_before, "Temporal fragment should reduce travel time")
```

### Performance Testing
```gdscript
func test_automation_performance():
    var automation = AutomationSystem.new()
    
    # Create multiple trading posts
    for i in range(100):
        var system_id = "test_system_" + str(i)
        automation.create_trading_post(system_id, default_config)
    
    # Measure processing time
    var start_time = Time.get_ticks_msec()
    automation.process_automation(1.0)  # Process 1 second
    var end_time = Time.get_ticks_msec()
    
    var processing_time = end_time - start_time
    assert_lt(processing_time, 16, "Automation processing should complete within 16ms (60fps)")

func test_market_system_scalability():
    var economy = EconomySystem.new()
    
    # Simulate many concurrent trades
    var start_time = Time.get_ticks_msec()
    
    for i in range(1000):
        economy.execute_trade("terra_prime", "food", 1, true)
        economy.execute_trade("terra_prime", "food", 1, false)
    
    var end_time = Time.get_ticks_msec()
    var processing_time = end_time - start_time
    
    assert_lt(processing_time, 100, "1000 trades should process within 100ms")
```

This comprehensive design document provides the technical foundation for implementing all requirements while maintaining the game's architectural integrity and ensuring scalability for future enhancements.