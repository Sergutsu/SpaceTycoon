# Space Transport Tycoon - Design Document

## Project Overview

**Game Title**: Space Transport Tycoon  
**Genre**: Progressive Idle Strategy/Tycoon  
**Platform**: Godot 4.4 (Desktop/Mobile)  
**Development Status**: MVP Development Phase  
**Last Updated**: July 19, 2025

## Revised Core Concept

**Space Transport Tycoon** is a progressive idle strategy game that evolves from active trading simulation to automated galactic empire management. Players begin as hands-on space traders, gradually building automated systems that allow them to focus on exploration, discovery, and cosmic-scale decisions.

### **Evolution Phases**

#### Phase 1: Active Trader (MVP)
- **Manual Trading**: Buy low, sell high across 3-5 star systems
- **Ship Management**: Upgrade vessels, manage fuel and cargo
- **Route Optimization**: Learn profitable trade routes through experience
- **Foundation Building**: Establish first automated trading posts

#### Phase 2: Fleet Commander 
- **Automated Routes**: Set up recurring trade routes with AI captains
- **Fleet Expansion**: Manage multiple specialized ships
- **Station Construction**: Build trading posts and refueling stations
- **Market Manipulation**: Influence supply/demand through strategic trading

#### Phase 3: Galactic Tycoon
- **Idle Economy**: Self-managing trade networks generate passive income
- **Exploration Focus**: Discover ancient artifacts and lost civilizations
- **Cosmic Infrastructure**: Dyson spheres, space elevators, stellar engineering
- **Transcendence Path**: Evolve beyond physical limitations

### **Core Gameplay Pillars**

1. **Progressive Automation**: Start hands-on, gradually automate routine tasks
2. **Meaningful Discovery**: Exploration reveals game-changing artifacts and lore
3. **Economic Mastery**: Deep but accessible supply/demand mechanics
4. **Cosmic Scale**: Progression from single ship to galactic consciousness
5. **Relaxed Pacing**: No time pressure, play at your own pace

### **The Ancient Mystery**
Six precursor civilizations left reality-altering artifacts scattered across the galaxy. Each discovery unlocks new capabilities and reveals fragments of their tragic stories:

- **Chronovores**: Masters of time manipulation (temporal acceleration artifacts)
- **Silica Gardens**: Terraforming specialists (planet transformation tools)
- **Void Weavers**: Space-time architects (wormhole generators)
- **Harmonium**: Quantum resonance builders (efficiency multipliers)
- **Nexus Architects**: Dimensional engineers (teleportation networks)
- **The Last Light**: Energy transcendents (stellar harvesting technology)

## Current Implementation Status

### ✅ Completed Features (MVP Foundation v0.1)

#### Galaxy Map System
- **3 Planet System**: Terra Prime (Agricultural), Minerva Station (Mining), Luxuria Resort (Tourist)
- **Interactive Map**: Visual galaxy map with clickable planets and animated ship movement
- **Distance-based Travel**: Fuel costs vary by route distance
- **Real-time Updates**: Ship position updates with smooth animations

#### Economic System
- **Dynamic Pricing**: Supply/demand affects buy/sell prices in real-time
- **Three Commodity Types**: Food, Minerals, Passengers with unique market characteristics
- **Market Differentiation**: Each planet has distinct economic profiles
- **Profit Optimization**: Clear price spreads encourage strategic trading

#### Fleet Management (Basic)
- **Single Ship**: Stellar Hauler with upgradeable stats
- **Cargo System**: 50-unit capacity with inventory tracking
- **Fuel Management**: 100-unit fuel tank with consumption-based travel
- **Refueling**: Station-based refueling with market-rate pricing

#### User Interface
- **Signal-Driven Architecture**: Clean separation between game logic and UI
- **Dynamic Content**: Runtime generation of market and travel options
- **Responsive Design**: Godot-native UI with proper scaling
- **Real-time Feedback**: All stats update automatically via signals

### 🚧 Technical Architecture

#### File Structure
```
SpaceTycoon/
├── project.godot           # Godot project configuration
├── scenes/                 # Scene files
│   └── Main.tscn          # Main game scene with UI layout
├── scripts/               # GDScript source code
│   ├── GameManager.gd     # Core game logic and state management
│   └── UI/                # User interface controllers
│       ├── MainUI.gd      # Main interface and panel management
│       └── GalaxyMap.gd   # Galaxy map visualization and interaction
└── JSPrototype/           # Original web prototype (reference)
```

#### Core Systems Architecture
- **GameManager**: Centralized game state with signal-based communication
- **Signal Architecture**: Decoupled UI updates via Godot signals
- **Scene Composition**: Modular UI panels and game components
- **Dynamic Content**: Runtime UI generation for scalable content

## MVP Feature Set & Architecture

### **MVP Goals (Phase 1: Active Trader)**
Create a compelling 2-4 hour gameplay loop that demonstrates the core trading mechanics and sets up the foundation for automation.

#### **Core MVP Features**

1. **Enhanced Galaxy Map (5 Systems)**
   ```gdscript
   # Expanded from current 3 to 5 systems
   var star_systems = {
       "terra_system": {...},      # Agricultural hub
       "minerva_system": {...},    # Mining colony  
       "luxuria_system": {...},    # Tourist destination
       "frontier_outpost": {...},  # High-risk, high-reward
       "nexus_station": {...}      # Central trading hub
   }
   ```

2. **Ship Upgrade System**
   ```gdscript
   # Ship progression system
   var ship_upgrades = {
       "cargo_capacity": [50, 75, 100, 150, 200],
       "fuel_efficiency": [1.0, 0.9, 0.8, 0.7, 0.6],
       "speed": [1.0, 1.2, 1.5, 2.0, 2.5],
       "scanner_range": [1, 2, 3, 4, 5]  # For artifact discovery
   }
   ```

3. **Artifact Discovery System**
   ```gdscript
   # Simple artifact system for MVP
   var artifacts = {
       "chronovore_fragment": {
           "effect": "reduce_travel_time",
           "magnitude": 0.1,
           "rarity": "common"
       },
       "silica_seed": {
           "effect": "boost_planet_production", 
           "magnitude": 0.15,
           "rarity": "uncommon"
       }
   }
   ```

4. **Basic Automation (Trading Posts)**
   ```gdscript
   # First step toward idle mechanics
   var trading_posts = {
       "auto_buy_threshold": 0.8,   # Buy when price < 80% of average
       "auto_sell_threshold": 1.2,  # Sell when price > 120% of average
       "efficiency": 0.7            # 70% of manual trading profit
   }
   ```

5. **Event System**
   ```gdscript
   # Random events to add variety
   var events = [
       {"type": "solar_flare", "effect": "fuel_cost_increase", "duration": 300},
       {"type": "trade_boom", "effect": "price_volatility_increase", "duration": 600},
       {"type": "artifact_signal", "effect": "reveal_artifact_location", "duration": 0}
   ]
   ```

#### **MVP Architecture Design**

```gdscript
# Enhanced GameManager structure
extends Node
class_name GameManager

# Core systems
var economy_system: EconomySystem
var ship_system: ShipSystem  
var artifact_system: ArtifactSystem
var automation_system: AutomationSystem
var event_system: EventSystem

# Progression tracking
var player_stats = {
    "total_credits_earned": 0,
    "systems_visited": [],
    "artifacts_found": [],
    "upgrades_purchased": [],
    "automation_level": 0
}
```

#### **MVP Content Scope**

**Star Systems (5 total)**:
1. **Terra Prime** - Agricultural (Food cheap, Minerals expensive)
2. **Minerva Station** - Mining (Minerals cheap, Food expensive) 
3. **Luxuria Resort** - Tourism (Passengers expensive, everything else costly)
4. **Frontier Outpost** - High-risk (Great prices, random events)
5. **Nexus Station** - Trading hub (Moderate prices, upgrade shop)

**Ship Upgrades (4 categories)**:
- **Cargo Hold**: 50 → 200 units (5 levels)
- **Engine**: Fuel efficiency and speed (5 levels)
- **Scanner**: Artifact detection range (5 levels)  
- **AI Core**: Automation capabilities (3 levels)

**Artifacts (6 types, 2 per precursor race)**:
- **Chronovore**: Time acceleration, fuel efficiency
- **Silica Gardens**: Planet bonuses, cargo expansion
- **Void Weavers**: Travel shortcuts, market intel

**Automation Features**:
- **Trading Posts**: Auto-buy/sell at set thresholds
- **Route Planning**: AI suggests optimal trade routes
- **Market Analysis**: Predictive price modeling

#### **MVP Success Metrics**

1. **Engagement**: Players spend 2+ hours in first session
2. **Progression**: Clear upgrade path with meaningful choices
3. **Discovery**: At least 2 artifacts found in typical playthrough
4. **Automation**: Players set up first trading post
5. **Retention**: 60%+ return for second session

#### **Post-MVP Roadmap**

**Phase 2 Features**:
- Fleet management (multiple ships)
- Advanced automation (trade routes)
- Station construction
- Competitive AI traders

**Phase 3 Features**:
- Procedural galaxy expansion
- Idle mechanics (offline progress)
- Cosmic-scale infrastructure
- Transcendence system

## Technical Implementation Plan

### **MVP Development Phases**

#### **Week 1-2: Core Systems Enhancement**
- Expand galaxy map to 5 systems
- Implement ship upgrade system
- Add basic artifact discovery mechanics

#### **Week 3-4: Automation Foundation**  
- Create trading post system
- Implement AI route suggestions
- Add market prediction algorithms

#### **Week 5-6: Content & Polish**
- Balance economic systems
- Add event system
- Create tutorial and onboarding

#### **Week 7-8: Testing & Refinement**
- Playtesting and balance adjustments
- Performance optimization
- Bug fixes and polish

### **Architecture Patterns**

```gdscript
# Modular system design
# GameManager orchestrates, systems handle specifics

# EconomySystem.gd
extends Node
class_name EconomySystem
signal price_changed(planet_id: String, good_type: String, new_price: int)

# ShipSystem.gd  
extends Node
class_name ShipSystem
signal ship_upgraded(upgrade_type: String, new_level: int)

# ArtifactSystem.gd
extends Node
class_name ArtifactSystem
signal artifact_discovered(artifact_id: String, location: String)
```

## Design Philosophy

### **Core Principles**
1. **Progressive Complexity**: Start simple, add depth gradually
2. **Meaningful Automation**: Automation enhances rather than replaces gameplay
3. **Discovery-Driven**: Exploration and artifacts provide major progression moments
4. **Economic Realism**: Supply/demand creates emergent strategic opportunities
5. **Relaxed Pacing**: No time pressure, play at your own pace

### **Player Experience Goals**
- **Session 1**: Learn trading basics, make first profits, discover first artifact
- **Session 2-3**: Upgrade ship, explore all systems, set up first automation
- **Session 4-5**: Master market dynamics, find rare artifacts, plan fleet expansion
- **Long-term**: Transition to fleet management and cosmic-scale thinking

### **Monetization Strategy (Future)**
- **Premium Version**: Advanced automation features, cosmetic ship designs
- **DLC Expansions**: New galaxy sectors, precursor civilizations
- **No Pay-to-Win**: All gameplay advantages earned through play

This revised design document provides a clear path from the current prototype to a compelling MVP that demonstrates the game's unique progression from active trading to idle empire management, while maintaining the mysterious ancient civilization theme that will drive long-term engagement.