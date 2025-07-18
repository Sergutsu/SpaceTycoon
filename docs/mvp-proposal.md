# Space Transport Tycoon - MVP Proposal

## Executive Summary

Transform the current 3-planet prototype into a compelling MVP that demonstrates the game's unique progression from active trading to automated empire management. The MVP will provide 2-4 hours of engaging gameplay while establishing the foundation for future idle mechanics.

## MVP Feature Breakdown

### **1. Enhanced Galaxy Map System**

#### Current State
- 3 static planets with basic trading
- Simple click-to-travel mechanics
- Fixed fuel costs

#### MVP Enhancement
```gdscript
# Expand to 5 diverse star systems
var star_systems = {
    "terra_prime": {
        "type": "agricultural",
        "risk_level": "safe",
        "special_feature": "stable_prices",
        "goods": {
            "food": {"supply": "high", "base_price": 8},
            "minerals": {"supply": "low", "base_price": 55},
            "tech": {"supply": "medium", "base_price": 30}
        }
    },
    "minerva_station": {
        "type": "industrial", 
        "risk_level": "safe",
        "special_feature": "bulk_discounts",
        "goods": {
            "food": {"supply": "low", "base_price": 25},
            "minerals": {"supply": "high", "base_price": 12},
            "tech": {"supply": "medium", "base_price": 35}
        }
    },
    "luxuria_resort": {
        "type": "luxury",
        "risk_level": "safe", 
        "special_feature": "premium_passengers",
        "goods": {
            "food": {"supply": "medium", "base_price": 18},
            "minerals": {"supply": "medium", "base_price": 40},
            "passengers": {"supply": "high", "base_price": 60}
        }
    },
    "frontier_outpost": {
        "type": "frontier",
        "risk_level": "high",
        "special_feature": "volatile_prices",
        "goods": {
            "food": {"supply": "critical", "base_price": 45},
            "minerals": {"supply": "abundant", "base_price": 8},
            "artifacts": {"supply": "rare", "base_price": 200}
        }
    },
    "nexus_station": {
        "type": "hub",
        "risk_level": "safe",
        "special_feature": "upgrade_shop",
        "goods": {
            "food": {"supply": "medium", "base_price": 15},
            "minerals": {"supply": "medium", "base_price": 25},
            "ship_parts": {"supply": "high", "base_price": 100}
        }
    }
}
```

#### Implementation Priority: **HIGH**
- **Effort**: 2-3 days
- **Impact**: Dramatically increases gameplay variety and replayability

### **2. Ship Upgrade System**

#### Current State
- Single static ship with fixed capabilities
- No progression mechanics

#### MVP Enhancement
```gdscript
# Comprehensive ship upgrade system
class_name ShipUpgradeSystem
extends Node

var upgrade_categories = {
    "cargo_hold": {
        "levels": [50, 75, 100, 150, 200, 300],
        "costs": [0, 5000, 12000, 25000, 50000, 100000],
        "descriptions": [
            "Basic cargo bay",
            "Expanded storage", 
            "Modular containers",
            "Quantum compression",
            "Dimensional pockets",
            "Infinite storage matrix"
        ]
    },
    "engine": {
        "levels": [1.0, 0.9, 0.8, 0.7, 0.6, 0.5],  # Fuel efficiency multiplier
        "costs": [0, 8000, 18000, 35000, 70000, 150000],
        "descriptions": [
            "Chemical thrusters",
            "Ion drive",
            "Fusion engine", 
            "Antimatter core",
            "Zero-point drive",
            "Quantum tunneling"
        ]
    },
    "scanner": {
        "levels": [1, 2, 3, 4, 5, 6],  # Artifact detection range
        "costs": [0, 3000, 8000, 18000, 40000, 80000],
        "descriptions": [
            "Basic sensors",
            "Deep space radar",
            "Quantum scanner",
            "Temporal detector", 
            "Dimensional probe",
            "Omniscient array"
        ]
    },
    "ai_core": {
        "levels": [0, 1, 2, 3, 4, 5],  # Automation capability
        "costs": [0, 15000, 35000, 75000, 150000, 300000],
        "descriptions": [
            "Manual control only",
            "Basic autopilot",
            "Trade assistant",
            "Market predictor",
            "Fleet coordinator", 
            "Galactic consciousness"
        ]
    }
}

func calculate_upgrade_effect(category: String, level: int) -> Dictionary:
    match category:
        "cargo_hold":
            return {"cargo_capacity": upgrade_categories[category]["levels"][level]}
        "engine":
            return {
                "fuel_efficiency": upgrade_categories[category]["levels"][level],
                "travel_speed": 2.0 - upgrade_categories[category]["levels"][level]
            }
        "scanner":
            return {"artifact_detection_range": upgrade_categories[category]["levels"][level]}
        "ai_core":
            return {"automation_level": upgrade_categories[category]["levels"][level]}
```

#### Implementation Priority: **HIGH**
- **Effort**: 3-4 days
- **Impact**: Core progression system that drives player engagement

### **3. Artifact Discovery System**

#### Current State
- No discovery mechanics
- Static gameplay experience

#### MVP Enhancement
```gdscript
# Artifact system with meaningful progression impact
class_name ArtifactSystem
extends Node

var precursor_races = {
    "chronovores": {
        "lore": "Masters of time who consumed temporal energy until they forgot to exist",
        "artifacts": {
            "temporal_fragment": {
                "rarity": "common",
                "effect": "reduce_travel_time",
                "magnitude": 0.15,
                "description": "A crystallized moment that makes journeys feel shorter"
            },
            "time_anchor": {
                "rarity": "rare", 
                "effect": "boost_all_actions",
                "magnitude": 0.25,
                "description": "Accelerates all ship operations by bending local time"
            }
        }
    },
    "silica_gardens": {
        "lore": "Terraformers who grew planets like flowers until their creations screamed",
        "artifacts": {
            "genesis_seed": {
                "rarity": "common",
                "effect": "boost_planet_production",
                "magnitude": 0.20,
                "description": "Enhances planetary resource generation"
            },
            "world_shaper": {
                "rarity": "rare",
                "effect": "create_new_trade_route", 
                "magnitude": 1.0,
                "description": "Reveals hidden connections between worlds"
            }
        }
    },
    "void_weavers": {
        "lore": "Space-time architects who knitted dark matter into dreams and nightmares",
        "artifacts": {
            "space_fold": {
                "rarity": "common",
                "effect": "reduce_fuel_cost",
                "magnitude": 0.20,
                "description": "Bends space to make distant places closer"
            },
            "reality_loom": {
                "rarity": "rare",
                "effect": "generate_wormhole",
                "magnitude": 1.0, 
                "description": "Creates permanent shortcuts through space"
            }
        }
    }
}

func discover_artifact(system_id: String, scanner_level: int) -> Dictionary:
    var discovery_chance = scanner_level * 0.1  # 10% per scanner level
    if randf() < discovery_chance:
        return _generate_random_artifact()
    return {}

func apply_artifact_effect(artifact_id: String, player_stats: Dictionary):
    var artifact = _get_artifact_data(artifact_id)
    match artifact.effect:
        "reduce_travel_time":
            player_stats.travel_speed_multiplier += artifact.magnitude
        "boost_planet_production":
            player_stats.production_multiplier += artifact.magnitude
        "reduce_fuel_cost":
            player_stats.fuel_efficiency_bonus += artifact.magnitude
```

#### Implementation Priority: **MEDIUM-HIGH**
- **Effort**: 2-3 days
- **Impact**: Adds discovery-driven progression and long-term goals

### **4. Basic Automation System**

#### Current State
- Fully manual trading
- No automation mechanics

#### MVP Enhancement
```gdscript
# Trading post automation system
class_name AutomationSystem
extends Node

var trading_posts = {}

func create_trading_post(system_id: String, config: Dictionary) -> bool:
    if not can_afford_trading_post(config.cost):
        return false
    
    trading_posts[system_id] = {
        "auto_buy_goods": config.auto_buy_goods,
        "buy_threshold": config.buy_threshold,  # Buy when price < X% of average
        "auto_sell_goods": config.auto_sell_goods,
        "sell_threshold": config.sell_threshold,  # Sell when price > X% of average
        "efficiency": config.efficiency,  # Percentage of manual trading profit
        "cargo_allocation": config.cargo_allocation,
        "active": true
    }
    return true

func process_automated_trading(delta: float):
    for system_id in trading_posts.keys():
        var post = trading_posts[system_id]
        if post.active:
            _execute_automated_trades(system_id, post)

func _execute_automated_trades(system_id: String, post: Dictionary):
    var system_data = GameManager.star_systems[system_id]
    
    # Auto-buy logic
    for good_type in post.auto_buy_goods:
        var current_price = _get_current_price(system_id, good_type)
        var average_price = _get_average_price(good_type)
        
        if current_price < (average_price * post.buy_threshold):
            _execute_auto_buy(system_id, good_type, post.efficiency)
    
    # Auto-sell logic  
    for good_type in post.auto_sell_goods:
        var current_price = _get_current_price(system_id, good_type)
        var average_price = _get_average_price(good_type)
        
        if current_price > (average_price * post.sell_threshold):
            _execute_auto_sell(system_id, good_type, post.efficiency)
```

#### Implementation Priority: **MEDIUM**
- **Effort**: 3-4 days
- **Impact**: Introduces idle mechanics foundation

### **5. Event System**

#### Current State
- Static market conditions
- Predictable gameplay

#### MVP Enhancement
```gdscript
# Dynamic event system for variety
class_name EventSystem
extends Node

var active_events = []
var event_templates = {
    "solar_flare": {
        "probability": 0.05,  # 5% chance per hour
        "duration": 300,      # 5 minutes
        "effects": {
            "fuel_cost_multiplier": 1.5,
            "scanner_efficiency": 0.5
        },
        "description": "Solar activity disrupts navigation systems"
    },
    "trade_boom": {
        "probability": 0.03,
        "duration": 600,      # 10 minutes
        "effects": {
            "price_volatility": 2.0,
            "profit_multiplier": 1.3
        },
        "description": "Economic surge increases trading opportunities"
    },
    "artifact_signal": {
        "probability": 0.02,
        "duration": 0,        # Instant
        "effects": {
            "reveal_artifact": true
        },
        "description": "Ancient technology detected in nearby system"
    },
    "pirate_activity": {
        "probability": 0.04,
        "duration": 450,      # 7.5 minutes
        "effects": {
            "travel_risk": 0.1,  # 10% chance of cargo loss
            "insurance_cost": 1.2
        },
        "description": "Pirate raids reported in outer systems"
    }
}

func process_events(delta: float):
    _check_for_new_events()
    _update_active_events(delta)
    _apply_event_effects()

func _check_for_new_events():
    for event_type in event_templates.keys():
        var template = event_templates[event_type]
        if randf() < template.probability * (1.0/3600.0):  # Per second probability
            _trigger_event(event_type, template)
```

#### Implementation Priority: **LOW-MEDIUM**
- **Effort**: 2 days
- **Impact**: Adds variety and unpredictability

## MVP Architecture Proposal

### **Enhanced GameManager Structure**
```gdscript
extends Node
class_name GameManager

# Core systems - modular design
@onready var economy_system: EconomySystem = $EconomySystem
@onready var ship_system: ShipSystem = $ShipSystem
@onready var artifact_system: ArtifactSystem = $ArtifactSystem
@onready var automation_system: AutomationSystem = $AutomationSystem
@onready var event_system: EventSystem = $EventSystem

# Enhanced game state
var player_data = {
    "credits": 10000,
    "ship_upgrades": {"cargo_hold": 0, "engine": 0, "scanner": 0, "ai_core": 0},
    "artifacts_found": [],
    "systems_visited": ["terra_prime"],
    "trading_posts": {},
    "statistics": {
        "total_credits_earned": 0,
        "successful_trades": 0,
        "systems_explored": 1,
        "artifacts_discovered": 0,
        "automation_efficiency": 0.0
    }
}

# Enhanced signals for complex interactions
signal ship_upgraded(upgrade_type: String, new_level: int)
signal artifact_discovered(artifact_id: String, system_id: String)
signal trading_post_created(system_id: String, efficiency: float)
signal event_triggered(event_type: String, duration: float)
signal automation_profit_generated(amount: int, source: String)
```

### **Modular System Design**
Each system handles its own logic and communicates through signals:

- **EconomySystem**: Market dynamics, price calculations, trade execution
- **ShipSystem**: Upgrades, travel mechanics, fuel management
- **ArtifactSystem**: Discovery mechanics, effect application, lore delivery
- **AutomationSystem**: Trading posts, AI behavior, passive income
- **EventSystem**: Random events, temporary effects, narrative moments

### **Data Persistence Architecture**
```gdscript
# Save/Load system for MVP
class_name SaveSystem
extends Node

const SAVE_FILE = "user://spacetycoon_save.dat"

func save_game():
    var save_data = {
        "version": "1.0",
        "timestamp": Time.get_unix_time_from_system(),
        "player_data": GameManager.player_data,
        "system_states": GameManager.economy_system.get_system_states(),
        "active_events": GameManager.event_system.active_events
    }
    
    var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data))
    file.close()

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_FILE):
        return false
    
    var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
    var save_data = JSON.parse_string(file.get_as_text())
    file.close()
    
    GameManager.player_data = save_data.player_data
    GameManager.economy_system.restore_system_states(save_data.system_states)
    GameManager.event_system.active_events = save_data.active_events
    
    return true
```

## Development Timeline

### **Phase 1: Core Systems (Week 1-2)**
- [ ] Expand galaxy map to 5 systems
- [ ] Implement ship upgrade system
- [ ] Create modular system architecture
- [ ] Add save/load functionality

### **Phase 2: Discovery & Automation (Week 3-4)**
- [ ] Implement artifact discovery system
- [ ] Create basic trading post automation
- [ ] Add market prediction algorithms
- [ ] Implement event system

### **Phase 3: Balance & Polish (Week 5-6)**
- [ ] Balance economic systems and upgrade costs
- [ ] Create tutorial and onboarding flow
- [ ] Add visual feedback and animations
- [ ] Implement achievement system

### **Phase 4: Testing & Launch Prep (Week 7-8)**
- [ ] Comprehensive playtesting
- [ ] Performance optimization
- [ ] Bug fixes and stability improvements
- [ ] Prepare for initial release

## Success Metrics

### **Engagement Metrics**
- **Session Length**: Target 45+ minutes average
- **Return Rate**: 60%+ players return within 24 hours
- **Progression Rate**: 80%+ players upgrade their ship at least once

### **Feature Adoption**
- **Exploration**: 90%+ players visit all 5 systems
- **Discovery**: 70%+ players find at least one artifact
- **Automation**: 50%+ players create a trading post

### **Retention Indicators**
- **Multi-session Play**: 40%+ players play 3+ sessions
- **Deep Engagement**: 20%+ players reach advanced ship upgrades
- **Word-of-Mouth**: Positive feedback on discovery and progression

## Risk Mitigation

### **Technical Risks**
- **Performance**: Modular architecture allows for optimization
- **Complexity**: Phased implementation prevents feature creep
- **Save System**: Simple JSON format ensures compatibility

### **Design Risks**
- **Balance**: Extensive playtesting with adjustable parameters
- **Progression**: Multiple upgrade paths prevent linear gameplay
- **Retention**: Artifact system provides long-term goals

### **Scope Risks**
- **Feature Creep**: Strict MVP feature list with post-launch roadmap
- **Timeline**: Buffer time built into each phase
- **Quality**: Automated testing and continuous integration

This MVP proposal transforms the current prototype into a compelling game that demonstrates the unique progression from active trading to automated empire management, while establishing the foundation for the full vision of cosmic-scale idle gameplay.