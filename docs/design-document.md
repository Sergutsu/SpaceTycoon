# Space Transport Tycoon - Design Document

## Project Overview

**Game Title**: Space Transport Tycoon  
**Genre**: Strategy/Tycoon/Business Simulation  
**Platform**: Godot 4.4 (Desktop/Mobile)  
**Development Status**: Godot Implementation Phase  
**Last Updated**: July 18, 2025

## Core Concept

Space Transport Tycoon is a strategy game where players build and manage a space transport empire. Starting with a single spaceship and limited funds, players expand their operations by transporting goods and passengers across a dynamic galaxy, outmaneuvering competitors, and overcoming space hazards.

## Current Implementation Status

### ✅ Completed Features (Prototype v0.1)

#### Galaxy Map System
- **3 Planet System**: Terra Prime (Agricultural), Minerva Station (Mining), Luxuria Resort (Tourist)
- **Visual Map**: Interactive galaxy map with clickable planets
- **Ship Positioning**: Animated ship movement between locations
- **Distance-based Travel**: Fuel costs vary by route distance

#### Economic System
- **Dynamic Pricing**: Supply/demand affects buy/sell prices
- **Three Commodity Types**: Food, Minerals, Passengers
- **Market Differentiation**: Each planet has unique economic characteristics
- **Price Calculation**: Real-time price adjustments based on local conditions

#### Fleet Management (Basic)
- **Single Ship**: Stellar Hauler with basic stats
- **Cargo System**: 50-unit capacity with inventory tracking
- **Fuel Management**: 100-unit fuel tank with consumption per travel
- **Refueling**: Station-based refueling at market rates

#### User Interface
- **Game Header**: Credits, fuel, and cargo status display
- **Market Panel**: Buy/sell interface with current prices
- **Travel Panel**: Destination options with fuel costs
- **Location Panel**: Current planet information

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

#### Core Systems
- **GameManager**: Centralized game state with signal-based communication
- **Signal Architecture**: Decoupled UI updates via Godot signals
- **Scene Composition**: Modular UI panels and game components
- **Dynamic Content**: Runtime UI generation for market and travel options

## Planned Features (Future Development)

### Phase 1: Core Expansion
- [ ] **Ship Upgrades**: Speed, capacity, fuel efficiency improvements
- [ ] **Multiple Ships**: Fleet management with different vessel types
- [ ] **Contracts System**: Timed delivery missions with bonuses
- [ ] **Basic Events**: Random market fluctuations and opportunities

### Phase 2: Strategic Depth
- [ ] **Space Stations**: Player-owned infrastructure for trade hubs
- [ ] **Research Tree**: Technology upgrades and new capabilities
- [ ] **Competitor AI**: Rival transport companies
- [ ] **Risk Management**: Pirates, hazards, insurance systems

### Phase 3: Advanced Features
- [ ] **Galaxy Expansion**: Additional star systems and trade routes
- [ ] **Crew Management**: Specialists with unique abilities
- [ ] **Manufacturing**: Resource processing and value-added goods
- [ ] **Reputation System**: Faction relationships and exclusive contracts

## Game Balance Considerations

### Current Economic Model
- **Starting Capital**: $10,000 provides ~10-15 initial trades
- **Fuel Costs**: 12-18 units per trip (12-18% of tank capacity)
- **Cargo Capacity**: 50 units allows meaningful trade volumes
- **Price Spreads**: 20-40% profit margins on optimal routes

### Identified Balance Points
- **Terra → Minerva Food Trade**: ~100% profit margin (high-value route)
- **Minerva → Terra Minerals**: ~67% profit margin (solid return)
- **Luxuria Passenger Transport**: High-value but limited volume

## Technical Considerations

### Current Technology Stack of Prototype
- **Frontend**: Vanilla HTML5, CSS3, JavaScript (ES6+)
- **Styling**: CSS Grid, Flexbox, CSS animations
- **State Management**: Object-based game state
- **No Dependencies**: Pure web technologies for maximum compatibility

### Performance Notes
- **Lightweight**: ~15KB total file size
- **Responsive**: Mobile-friendly design patterns
- **Browser Compatibility**: Modern browsers (ES6+ support required)

## Next Development Priorities

1. **Ship Upgrade System**: Allow players to improve their vessel
2. **Fleet Expansion**: Multiple ships with different specializations
3. **Event System**: Random encounters and market changes
4. **Save/Load**: Persistent game state
5. **Tutorial System**: Guided introduction for new players

## Design Philosophy

- **Accessibility**: Simple controls, clear information display
- **Strategic Depth**: Multiple viable approaches to success
- **Progressive Complexity**: Start simple, unlock advanced features
- **Economic Realism**: Supply/demand drives meaningful decisions
- **Visual Clarity**: Space theme with functional, clean interface