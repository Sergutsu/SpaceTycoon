# SpaceTycoon — Game Design Document

**Version:** 0.2.1 — Expanded Working Prototype  
**Platform:** Modern desktop and mobile browsers  
**Delivery:** Static HTML/CSS/JS, no backend or build step  
**Language:** Russian UI, English code identifiers  
**Status:** Implemented expanded prototype scope

---

## 1. High Concept

SpaceTycoon is an orbital shipyard tycoon. The player operates the station «Аврора», designs and builds ships, fulfills contracts, manages crew and station infrastructure, researches technologies, trades resources, and expands influence across the Solar System.

The procedural 3D ship builder remains the signature feature: ship geometry and equipment are not cosmetic only, they feed into economic stats and construction cost.

### Design pillars

1. **Design matters** — hull size, engines, weapons, sensors, and crew affect contract performance.
2. **Connected systems** — fuel, energy, wages, research, reputation, and market prices influence each other.
3. **Readable tycoon loop** — build → assign → resolve → reinvest → expand.
4. **Builder-first identity** — the same Earth/stars visual language is used across every view.
5. **Static web delivery** — no backend, no external runtime CDN, local saves.

---

## 2. Views

| View | Purpose |
|---|---|
| Обзор | KPIs, active missions, production, next objective, station log |
| Орбитальная карта | Sector unlock state, routes, active mission lines, sector contracts |
| Контракты | Generated contract board, filters, requirements, rewards, assignment |
| Флот | Ship cards, stats, condition, crew, repair, rename, sell, refit |
| Верфь | Quick-build catalog, custom builder, build/refit queue, drydock |
| Станция | Module levels, energy balance, production, upgrade drones |
| Экипаж | Roster, candidates, assignment, training, rest, morale, salaries |
| Исследования | Four tech branches, prerequisites, active research |
| Рынок | Alloy/fuel prices, buy/sell, daily limits, auto-supply |
| Финансы | Daily cashflow chart, ledger, CSV export, net worth |
| Репутация | Faction standing, perks, achievements, history |
| Настройки | Background quality, sound, notifications, autosave, import/export/reset |

All views share a persistent WebGL orbital background: Earth surface/normal/specular/cloud maps, atmospheric rim, star field, and subtle rotation. The background can be set to high, low, or off.

---

## 3. Core Loop

```text
Accept contract → assign ship + crew + fuel → mission timer
      ↓
Success/failure resolution → rewards, wear, reputation, faction standing
      ↓
Repair / build / refit / upgrade station / research / trade
      ↓
Unlock sectors, ship classes, and higher-tier contracts
```

### Secondary loops

- **Fleet:** build → specialize → crew → maintain → refit → sell/replace.
- **Station:** invest → improve capacity/production/energy → support larger operations.
- **Science:** research → unlock classes/sectors/bonuses → harder contracts.
- **Economy:** production + contracts + market → cashflow → wages/upkeep → reinvestment.
- **Diplomacy:** faction reputation → perks → better rewards/costs/intel.

---

## 4. Time and Simulation

- 1 real second at 1× = 10 orbital minutes.
- 1 orbital day = 144 real seconds at 1×.
- Speeds: pause, 1×, 2×, 4×.
- Production cycle: every 10 simulated seconds.
- Contract board refill: every 30 simulated seconds, up to 8 offers.
- Random events: every 150–240 simulated seconds.
- Daily reset: wages/upkeep, market prices/limits, idle crew morale recovery.
- Offline catch-up: capped at 8 hours, simulated in 5-second steps.

---

## 5. Resources

| Resource | Purpose | Sources |
|---|---|---|
| Credits | Construction, repairs, upgrades, hiring, market, research | Contracts, station trade, sales, events, achievements |
| Alloy | Ships, repairs, modules | Contracts, refinery, market |
| Fuel | Mission launch cost | Market, fuel synthesizer, some rewards |
| Research | Technologies, training, advanced modules | Science contracts, laboratory, achievements |
| Reputation | Sector unlocks, contract quality, achievements | Successful contracts |

Starting resources: 4,200 credits, 180 alloy, 100 fuel, 20 research, 0 reputation. Starter ship «Пионер» and one captain.

---

## 6. Ships

### Presets

| Preset | Role | Unlock |
|---|---|---|
| Исследователь | Science/utility | Start |
| Грузовоз | Freight | Start |
| Перехватчик | Escort/rapid response | Start |
| Дредноут | Heavy combat | Военная доктрина |
| Био-корабль | Exotic science | Ксенобиология |
| Рейдер | Irregular operations | Нестандартные операции |

### Stats

Cargo, Science, Combat, Speed, Durability. Derived from builder parameters:

- Cargo: hull volume, wingspan.
- Combat: turrets, engines.
- Science: scanners, antennas, surface detail.
- Speed: engines, plasma glow, hull size penalties.
- Durability: segments, metalness, cross-section.

Effective stats include technology multipliers and crew role bonuses.

### Ship lifecycle

- Statuses: idle, mission, repair, refit.
- Condition 0–100%; below 25% cannot launch.
- Success wear: light; failure wear: heavy; engineer crew reduces wear.
- Repair: queued in drydock, cost scales with missing condition and ship value.
- Sale: 35% of value scaled by condition; crew returns to station.
- Refit: opens builder with existing design, costs 35% of full custom build, preserves ship identity/crew/history.

### Construction

- Quick-build: fixed preset cost/time.
- Custom: cost from derived stats, hull volume, turrets, triangle count.
- Build queue slots: `1 + floor(yard / 2)`.
- Completed ship waits if hangar is full.
- Cancel build/refit: 70% refund.

---

## 7. Contracts and Missions

Types: cargo, science, combat/escort, survey, rescue. Each contract has:

- Tier, sector, faction, primary stat requirement, speed requirement.
- Duration, risk, fuel requirement, rewards, expiration.

Success chance:

```text
0.55
+ (primaryStat - req) * 0.009
+ (speed - speedReq) * 0.004
+ controlLevel * 0.04
+ captainBonus
+ tech/event bonuses
- risk
+ (condition - 100) * 0.002
```

Clamped to 15–95%. No captain gives −8%.

Mission resolution:

- Success: rewards, ship experience/earnings, global reputation, faction standing, crew morale loss.
- Failure: heavier wear, −1 reputation, −1 faction standing, larger morale loss.
- Fuel is consumed at launch.

---

## 8. Sectors

| Sector | Unlock |
|---|---|
| Орбита Земли | Start |
| Лунная верфь | Yard 1, reputation 8 |
| Марсианский коридор | Yard 2, Дальняя навигация |
| Пояс астероидов | Yard 3, reputation 35 |
| Юпитерианская система | Yard 4, Дальний космос |
| Дальний рубеж | Yard 5, Слипстрим, reputation 90 |

Distance multiplies duration, fuel, and rewards. Relay modules and navigation technologies reduce mission time.

---

## 9. Station Modules

| Module | Effect |
|---|---|
| Верфь | Contract tier, build speed, queue slots |
| Ангар | Fleet capacity: `2 + level*2` |
| Сухой док | Repair/build discount, repair slots/speed |
| Центр управления | Mission success chance |
| Переработчик | Alloy production |
| Лаборатория | Research production, research speed |
| Торговый узел | Passive credits |
| Солнечные панели | Energy supply |
| Жилой модуль | Crew capacity |
| Топливный синтезатор | Fuel production |
| Навигационный релей | Mission duration reduction |

Energy:

- Supply: `20 + solar*18`.
- Demand: sum of module energy costs × levels.
- Efficiency: `min(1, supply/demand)`, applied to production.

Module upgrades are queued and handled by construction drones. Max level 5, except hangar/solar/habitat max 8. Level 4+ requires yard level 2.

---

## 10. Crew

Roles:

| Role | Main bonus |
|---|---|
| Капитан | Mission chance, speed |
| Инженер | Durability, wear reduction |
| Пилот | Speed, combat |
| Учёный | Science |

Crew have skill, morale, salary, status, and ship assignment.

- Hiring costs credits; candidates refresh after hire.
- Training costs credits + research, increases skill.
- Rest restores morale.
- Morale scales role bonuses.
- Salaries are paid daily.
- Ships have preset crew slots.

---

## 11. Research

Four branches: Engineering, Logistics, Science, Economy. Twelve technologies with prerequisites. Research consumes credits/research, takes time, and only one project runs at a time. Cancel refunds 50%.

Technology effects include stat multipliers, build speed, fuel use, mission time, income, production, rewards, and unlocks for ship classes/sectors.

---

## 12. Market and Finance

Market resources: alloy and fuel.

- Prices fluctuate daily via deterministic wave.
- Buy/sell spread.
- Daily trade limit: 150 units per resource.
- Lunar faction discount reduces alloy buy price.
- Industrial boom event raises alloy sell price.
- Auto-supply buys fuel when stock < 20 and credits > 600.

Finance:

- Every resource delta is recorded in a ledger.
- Daily aggregates: income, expenses, missions, production.
- Net worth includes credits, stock, fleet condition-adjusted value, and module residual value.
- CSV export for ledger.

Daily upkeep:

- Crew salaries.
- Station upkeep: `sum(moduleLevels)*2 + ships*3`.

---

## 13. Factions, Events, Achievements

Factions: Terran Alliance, Lunar Consortium, Helios Corp, Frontier Coalition. Standing 0–200; every 25 points grants a perk level, capped at 20%.

Perks:

- Terran: contract credit rewards.
- Lunar: alloy purchase discount.
- Helios: research production.
- Frontier: mission duration reduction.

Events: solar flare, market boom, distress call, grant, quiet shift. Events can modify production/chance/prices, add special contracts, or grant credits.

Achievements reward first contract, fleet size, custom build, earnings, research, station development, exploration, and reputation. Rewards are claimed once.

---

## 14. Save System

- Save key: `spacetycoon-save-v2`.
- Legacy key `spacetycoon-wp-v1` migrates automatically.
- Autosave every 15 seconds; manual save; JSON export/import.
- Import validates and sanitizes known IDs, numeric ranges, arrays, and references.
- Offline catch-up resolves missions, queues, production, events, and daily upkeep.

Save schema v2 includes:

```text
version, time, speed, rng, lastSaved
resources, modules, settings, metrics, factions, market
ships, crew, candidates
contracts, missions, history
buildQueue, repairQueue, moduleQueue, research, techs
events, ledger, daily, log, claimed
```

---

## 15. Architecture

Static modules loaded by `index.html`:

```text
data.js            Static definitions and balance
engine.js          Simulation/economy/save logic, no DOM rendering
ui.js              Icons, schematics, formatters, charts
views.js           View renderers and modal content
app.js             Shell, navigation, lifecycle, input, builder bridge
morphdom.min.js    Local MIT DOM patching library
orbit-background.js Persistent WebGL background
builder.html       Embedded procedural ship builder
```

### UI update strategy

The simulation tick runs every 250 ms, but it does not redraw the whole screen. High-frequency values (clock, top-bar resources, mission/queue timers, progress bars) are updated in place through `data-time` / `data-progress` hooks. A lightweight state signature detects structural or economic changes; only then is the current view re-rendered, and the new HTML is applied with `morphdom` so existing DOM nodes, focus, scroll position, and uncontrolled input values are preserved. The view entrance animation runs only when navigating to a different view, not on live updates.

Builder bridge:

- Game opens `builder.html?embed=1` in an iframe.
- Builder posts `spacetycoon:builder-ready` and `spacetycoon:ship-design`.
- Game can post `spacetycoon:load-design` for refit.
- Messages are accepted only from the expected iframe window and origin.
- Design payload includes preset, params, statistics, bounds, and name.

---

## 16. Acceptance Criteria

Implemented and verified:

- All navigation views render without errors.
- Shared orbital background loads local Earth textures.
- Contracts can be assigned and resolved.
- Quick build, custom build, refit, repair, and sale work.
- Module upgrades and research complete.
- Crew hire/assign/move/train works without duplicate assignment.
- Market buy/sell and daily limits work.
- Achievements can be claimed once.
- Save/reload persists expanded state.
- Legacy v1 saves migrate.
- Invalid imports are rejected/sanitized.
- Offline catch-up produces a summary.
- Mobile layout has no horizontal overflow at 390px.
- Zero external runtime requests in browser smoke test.

---

## 17. Roadmap

Possible next steps:

- Persistent mission routes with intermediate waypoints.
- Deeper manufacturing chains and resource deposits.
- Ship insurance, loans, and company milestones.
- Tactical contract mini-resolutions.
- More sectors, faction quest chains, and rare blueprints.
- Cloud saves and achievements backend.
- Balance pass based on longer play sessions.
