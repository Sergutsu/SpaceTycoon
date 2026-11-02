# SpaceTycoon — Orbital Shipyard Working Prototype

SpaceTycoon is a browser-based orbital shipyard tycoon. This repository has been reset to a clean HTML working prototype built around the existing procedural 3D ship builder.

## Files

| File | Purpose |
|---|---|
| `index.html` | SpaceTycoon working prototype: contracts, fleet, missions, upgrades, saves |
| `builder.html` | Preserved standalone 3D procedural spaceship builder |
| `docs/GDD.md` | Game design document for the working prototype |

## Run

Serve the repository root with any static server:

```bash
python -m http.server 8000 --bind 0.0.0.0
```

Then open:

- Game: `http://localhost:8000/`
- Standalone builder: `http://localhost:8000/builder.html`

The game also works from local files in most modern browsers, but a local server is recommended for iframe builder integration.

## Working prototype loop

1. Select a ship in the hangar.
2. Assign it to a contract.
3. Wait for the mission to resolve.
4. Earn credits, alloy, research, and reputation.
5. Repair, build, or design ships.
6. Upgrade the station to unlock harder contracts.

## Builder integration

The game opens `builder.html?embed=1` in a modal. In embedded mode the builder shows **Сохранить в ангар**. The design is sent to the game with `postMessage`, converted into gameplay stats, and built if the player has enough resources and hangar capacity.

## Saves

Progress is stored in `localStorage`. The game supports manual save, autosave, JSON export/import, and reset.

## Scope

This is a working prototype, not the old Godot project. The previous Godot/JS prototype files were removed. WordPress packaging is not part of this milestone; “WP” means working prototype.
