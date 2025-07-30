## 1. Models  

### 1.1 Core Entities  
- **Player**  
- **Corporation / Clan / Faction**  
- **NPC** (Trader, Pirate, Diplomat, Engineer, Scientist)  
- **AI System** (Broker AI, Combat AI, Production AI, Explorer AI)  
- **Message** (Trade Order, System Alert, Chat Message, Mission Brief)

### 1.2 Assets & Goods  
- **Ship**  
  - Types: Fighter, Freighter, Explorer, Colony Ship, Mining Ship, Transport Ship, Battlecruiser, Cruiser, Destroyer, Frigate, Cruiser, Battleship, Carrier, Dreadnought 
  - Modules: Engine, Hull Plating, Shield Generator, Cargo Bay, Sensor Array  
- **Weapon**  
  - Types: Laser, Missile Launcher, Railgun, Plasma Cannon, Ion Cannon, Beam Cannon, Particle Cannon, Plasma Torpedo, Ion Torpedo, Beam Torpedo, Particle Torpedo, Plasma Missile, Ion Missile, Beam Missile, Particle Missile
  - Modules: Power Cell, Guidance System, Cooling Unit,  Shield Generator, Hull Plating, Cargo Bay, Sensor Array
- **Drone** (Attributes: type, size, security)
- **Commodity** (Fuel, Ore, Food, Technology Components, Medical Supplies, Consumables, Drones)
- **Currency** (Galactic Credits, CryptoTokens, Barter Items, Specialized Resources)
- **Artifact**  (Attributes: rarity, quality, security)
- **Relic** (Attributes: rarity, quality)
- **Remnant**   (Attributes: rarity, quality)

### 1.3 Celestial & Infrastructure  
- **Star** (Attributes: temperature, luminosity, habitability)
- **Planet** (Attributes: atmosphere, gravity, habitability)  
- **Gas Giant** (Attributes: atmosphere, gravity, habitability)
- **Moon** (Attributes: atmosphere, gravity, habitability)
- **Asteroid**  (Attributes: composition, size, security)
- **Wormhole** (Attributes: type, size, security)
- **Ring** (Attributes: type, size, security)
- **Orbital Station** (Trading Post, Shipyard, Research Hub, Defense Platform)  
- **Structure** (Attributes: type, size, security)
  - Outpost, Colony Dome, Mining Station, Research Facility  
  - Mega-structure: Orbital Ring, Dyson Sphere  
- **City** (Attributes: population, infrastructure, services)
- **Building** (Factory, Habitat Module, Market, Power Plant)

### 1.4 Systems & Others  
- **Market** (Order Book, Price Index, Volatility)  
- **Technology Blueprint** (Research Tree Node)  
- **Quest / Contract** (Objectives, Timers, Rewards)  
- **Event** (Random, Scheduled, Global Crisis)  
- **Fleet** (Grouped Ships with Shared Orders)

---

## 2. Model Attributes  

| Attribute        | Description                                 | Example Values                        |
|------------------|---------------------------------------------|---------------------------------------|
| energy_value     | Energy output or storage                    | 500 MJ, 2 GJ                          |
| monetary_value   | Base price in credits                       | 1 200 cr, 50 000 cr                   |
| mass             | Physical mass                               | 10 t, 5 000 t                         |
| state            | Whether item is “Mass” or “Energy”          | Mass, Energy                          |
| type             | Virtual (digital) or Real (physical)        | Virtual, Real                         |
| rarity           | Scale of scarcity                           | Common to Legendary                   |
| durability       | Hit points or decay rate                    | 1 000 HP, 5% / day                    |
| quality          | Production or research quality rating       | 0–100                                 |
| efficiency       | Performance multiplier                      | 0.5×–2.0×                             |
| supply_index     | Current market supply level                 | 0–100                                 |
| demand_index     | Current market demand level                 | 0–100                                 |
| price_elasticity | Price sensitivity to commodity quantity     | 0.0–1.0                               |
