# SpaceTycoon — Game Design Document

**Version:** 0.1 — Working Prototype (WP)  
**Platform:** Modern desktop and mobile browsers  
**Delivery:** Static HTML/CSS/JS, no backend required  
**Language:** Russian UI, English code and documentation  
**Status:** Implemented prototype scope described in this document

---

## 1. High Concept

SpaceTycoon is a compact orbital shipyard tycoon. The player runs a small commercial space station, designs and builds ships, accepts orbital contracts, manages a fleet, and reinvests revenue into station upgrades.

The existing procedural ship builder is preserved as the visual and technical centerpiece. Instead of being only a sandbox, generated ships become functional economic units with cargo, science, combat, speed, and durability ratings.

### Design pillars

1. **Design matters** — ship geometry and equipment choices influence contract performance.
2. **Readable tycoon loop** — build, assign, wait, resolve, upgrade.
3. **Fast prototype sessions** — missions resolve in seconds/minutes, not hours.
4. **Self-contained web delivery** — the prototype runs from a static server or local files.
5. **Builder-first identity** — the 3D ship builder remains the signature feature.

---

## 2. Target Experience

The player should feel like the operator of a growing orbital shipyard:

- Start with one utility ship and a small budget.
- Accept low-risk transport or survey contracts.
- Build specialized ships for better-paying contracts.
- Balance fleet condition, contract risk, and station upgrades.
- Unlock higher-tier contracts by upgrading the shipyard.

The prototype is not a full simulation. It is a playable economic loop built around the ship builder.

---

## 3. Core Loop

```text
Accept contract
      ↓
Assign suitable ship
      ↓
Mission runs in real time
      ↓
Success / failure resolution
      ↓
Earn credits, alloy, research, reputation
      ↓
Repair, build, upgrade
      ↓
Harder contracts
```

### Secondary loops

- **Fleet loop:** build → specialize → maintain → sell/replace.
- **Station loop:** invest resources → improve income, success chance, capacity, and contract tier.
- **Design loop:** open builder → customize ship → save design to hangar → use it in contracts.

---

## 4. Working Prototype Scope

### Included

- Single-page HTML game shell.
- Russian UI with dark glassmorphism styling.
- Resources: credits, alloy, research, reputation.
- Starter ship and quick-build preset ships.
- Custom ship construction through the embedded 3D builder.
- Contract board with generated contracts.
- Mission assignment, progress, and resolution.
- Ship condition, repair, and sale.
- Station upgrades.
- Passive station production.
- Local save/load, autosave, export/import, and reset.
- Offline progress catch-up, capped to avoid excessive simulation.
- Event log and toast notifications.
- Pause and simulation speed controls.

### Not included in WP

- Real-time tactical combat.
- Multiplayer or backend accounts.
- Persistent galaxy map.
- Complex crew management.
- Fuel, oxygen, or life-support simulation.
- Full manufacturing chains.
- WordPress packaging. “WP” in this milestone means **working prototype**.

---

## 5. Resources

| Resource | Purpose | Sources |
|---|---|---|
| Credits | Build ships, repairs, upgrades, contract refresh | Contracts, station income, ship sales |
| Alloy | Ship construction and repairs | Contracts, refinery, salvage |
| Research | Advanced upgrades and higher-tier progression | Science contracts, laboratory |
| Reputation | Contract quality and progression gating | Successful contracts |

### Starting resources

- Credits: 3,000
- Alloy: 150
- Research: 0
- Reputation: 0
- Shipyard level: 1
- One starter utility ship

---

## 6. Ships

### Ship attributes

Each ship has:

- Name
- Class/preset
- Seed and design parameters
- Cargo rating
- Science rating
- Combat rating
- Speed rating
- Durability rating
- Condition, 0–100%
- Status: idle, mission, or repair
- Lifetime missions and earnings

### Preset roles

| Preset | Role | Strengths | Weaknesses |
|---|---|---|---|
| Исследователь | Science / utility | Science, balanced speed | Low combat and cargo |
| Грузовоз | Freight | Cargo, durability | Low speed and combat |
| Перехватчик | Escort / rapid response | Speed, combat | Low cargo |
| Дредноут | Heavy combat | Combat, durability | Expensive, slow |
| Био-корабль | Exotic research | Science, speed | Fragile, expensive |
| Рейдер | Irregular operations | Speed, combat | Low cargo and science |

### Derived stats

Custom ships derive ratings from builder parameters:

- Cargo increases with hull volume and wingspan.
- Combat increases with turrets and engine count.
- Science increases with scanners, antennas, and surface detail.
- Speed increases with engines and plasma intensity, but decreases with hull size.
- Durability increases with segments, metalness, and hull cross-section.

Stats are clamped to a readable range and combined with preset role bonuses.

### Construction cost

Custom ship cost is based on:

- Base shipyard fee
- Total derived rating
- Hull volume
- Weapon count
- Model complexity

Quick-build presets use fixed costs for prototype readability.

### Condition and repair

- Successful missions cause minor wear.
- Failed missions cause heavier wear.
- Ships below 20% condition must be repaired before assignment.
- Repair cost scales with missing condition and ship value.
- Drydock upgrades reduce repair cost.

---

## 7. Contracts

### Contract types

| Type | Primary stat | Typical rewards |
|---|---|---|
| Грузоперевозка | Cargo | Credits, alloy |
| Научная миссия | Science | Credits, research |
| Патруль / escort | Combat | Credits, reputation |
| Разведка | Speed + science | Credits, research, reputation |
| Спасательные работы | Durability + cargo | Credits, alloy, reputation |

### Contract fields

- Title
- Type
- Tier
- Primary requirement
- Speed requirement
- Duration
- Risk
- Rewards
- Expiration/refresh behavior

### Success chance

The prototype uses a transparent heuristic:

```text
chance = base
       + primaryStatAdvantage
       + speedAdvantage
       + missionControlBonus
       - contractRisk
```

Clamped between 15% and 95%.

The UI shows the estimated chance for the currently selected ship before assignment.

### Resolution

On success:

- Full rewards
- Reputation gain
- Minor condition loss
- Ship experience/earnings tracked

On failure:

- No full reward
- Small reputation penalty
- Heavy condition loss
- Log entry explaining the outcome

---

## 8. Station Upgrades

| Upgrade | Effect |
|---|---|
| Верфь | Increases fleet capacity and unlocks higher contract tiers |
| Сухой док | Reduces repair costs and construction costs |
| Центр управления | Increases mission success chance |
| Переработчик | Produces alloy over time |
| Лаборатория | Produces research over time |
| Торговый модуль | Produces credits over time |

Upgrade costs increase with level. Most upgrades cap at level 5 in the prototype.

---

## 9. Time and Simulation

- The game advances in real time.
- Speed controls: pause, 1×, 2×, 4×.
- Mission durations are prototype-scale, usually 30–150 seconds at 1×.
- Passive production is accumulated continuously.
- Contract board refreshes periodically and can be refreshed manually for credits.
- Offline progress is simulated on load, capped at 8 hours.

---

## 10. User Interface

### Layout

Desktop:

- Top bar: brand, resources, station clock, speed controls, save/menu actions.
- Left column: contract board.
- Center column: hangar and active missions.
- Right column: station upgrades and event log.

Mobile:

- Stacked sections.
- Compact resource bar.
- Full-screen builder modal.

### Builder integration

The builder is preserved as `builder.html`.

The game opens it in an iframe with `?embed=1`. In embedded mode the builder shows a **“Сохранить в ангар”** action. The builder sends a `postMessage` payload containing:

- Ship name
- Preset/class
- Seed
- Design parameters
- Model statistics
- Bounding dimensions

The game validates the message, derives gameplay stats, checks capacity and resources, then adds the ship to the hangar.

### Feedback

- Toasts for construction, mission results, upgrades, errors, and saves.
- Event log for recent station history.
- Progress bars for active missions.
- Condition bars for ships.
- Disabled states with reasons where practical.

---

## 11. Save System

Save data is stored in `localStorage` under a versioned key.

Saved state includes:

- Resources
- Station time
- Ships
- Contracts
- Active missions
- Upgrade levels
- Event log
- Selected ship
- Simulation speed
- Last saved timestamp

The prototype supports:

- Autosave
- Manual save
- Export save as JSON
- Import save from JSON
- Reset with confirmation

Save migration is versioned. Invalid or incompatible saves fall back to a new game with a warning.

---

## 12. Technical Architecture

### Files

```text
index.html     SpaceTycoon working prototype
builder.html   Preserved procedural 3D ship builder
docs/GDD.md    This design document
README.md      Run instructions and project overview
```

### Game shell

- Vanilla HTML/CSS/JS.
- No framework or build step.
- State object plus render functions.
- Interval-based simulation tick.
- DOM rendering with escaped user-facing strings.
- localStorage persistence.

### Builder

- Existing Three.js r128 single-file app.
- Embedded distributions and Earth textures.
- Added minimal embedded-mode bridge for sending ship designs to the parent game.

### Security and robustness

- Builder messages are validated by type and schema.
- Imported saves are validated before replacing state.
- User-visible strings are escaped.
- No backend, credentials, or network APIs are required.

---

## 13. Balancing Targets

Prototype targets:

- First contract completes within 1 minute.
- Player can afford a second cheap ship after 2–3 successful contracts.
- Shipyard level 2 is reachable within 5–10 minutes.
- Failures are punishing but not run-ending.
- Higher-tier contracts require specialized ships or upgrades.

Balancing constants are centralized in the game script for easy iteration.

---

## 14. Acceptance Criteria

The working prototype is complete when:

1. Old Godot/JS prototype files are removed.
2. The ship builder remains usable as `builder.html`.
3. `index.html` launches a playable SpaceTycoon prototype.
4. The player can build or design a ship.
5. The player can accept and complete a contract.
6. Rewards, condition, and resources update correctly.
7. Upgrades can be purchased and affect gameplay.
8. The game saves and loads locally.
9. The builder can send a custom ship into the game.
10. The UI is Russian and visually consistent with the builder.

---

## 15. Future Roadmap

### Next milestone

- Ship refitting from saved designs.
- More contract chains and faction reputation.
- Shipyard construction queue.
- Better offline summary.
- Sound and music toggles.

### Later

- Sector map and route planning.
- Crew and module slots.
- Manufacturing chains.
- Fleet combat simulation.
- Cloud saves.
- WordPress embedding, if requested later.
