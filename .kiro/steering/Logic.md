

## 3. Core Logic Systems  

### 3.1 Ownership & Hierarchies  
- Single Owner → Tree Ownership (e.g., Corporation owns Stations → Stations own Modules)  
- Permission Levels (Admin, Manager, Operator)
- **Ownership Controller**: Assign ownership, manage permissions, audit logs


### 3.2 Universal Transaction Engine  
- **Transaction Types**: Buy, Sell, Lease, Barter, Contract Fulfillment  
- **Tax & Fees**: Station Fees, Tariffs, Broker Fees  
- **Composite Transactions**: Trade Route Settlement, Resource Transfer Bundles  
- **Eventual Consistency**: Rollbacks on failure, Audit Logs
- **Transaction History**: Order Book, Trade History, Contract History


### 3.3 Movement & Navigation  
- Local Movement (thrusters, waypoints)  
- FTL / Jump Drives (cooldowns, coordinates lookup)  
- Traffic Control (docking queues, clearances)

### 3.4 Construction & Manufacturing  
- **Blueprint System**: unlocks, resource requirements, build time  
- **Assembly Logic**: factory throughput, module integration, maintenance cycles

### 3.5 Research & Technology  
- Branching Tech Trees (dependencies, tier unlocks)  
- Research Facilities (speed modifiers, upgrade slots)  
- Random Breakthroughs & Experimental Risks
- Research & Development (R&D) Projects

### 3.6 Economy Simulation  
- Supply & Demand Curves  
- Price Elasticity (commodity-specific sensitivity)  
- Dynamic Market Events (scarcity events, embargoes, pirate blockades)
- Resource & Commodity Prices controller (e.g., random events, market volatility)


### 3.7 Reputation & Diplomacy  
- Faction Standings (–100 to +100)  
- Opinion Modifiers (contracts completed, trade volume)  
- Treaty & Alliance Logic (shared defenses, market privileges)

### 3.8 AI Decision-Making  
- State-Machine & Utility-Based Controllers  
- Role-Specific Behaviors: Trader AI (profit focus), Pirate AI (hit-and-run), Explorer AI (data gathering)

### 3.9 Event & Mission Flow  
- Trigger Conditions (time, location, reputation)  
- Branching Outcomes (reward, penalty, new mission spawns)  
- Global vs. Personal Events

---