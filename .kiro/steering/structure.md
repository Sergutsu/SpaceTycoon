# Project Structure

## Current Organization
```
SpaceTycoon/
├── .git/                   # Git version control
├── .kiro/                  # Kiro AI assistant configuration
│   └── steering/           # AI guidance documents
├── docs/                   # Design documentation
│   └── design-document.md  # Comprehensive design doc
├── scenes/                 # Godot scene files (.tscn)
│   └── Main.tscn          # Main game scene with UI layout
├── scripts/                # GDScript source code (.gd)
│   ├── GameManager.gd     # Core game logic and state management
│   └── UI/                # User interface controllers
│       ├── MainUI.gd      # Main interface and panel management
│       └── GalaxyMap.gd   # Galaxy map visualization
├── JSPrototype/            # Original web prototype (reference)
│   ├── index.html         # Web version interface
│   ├── styles.css         # Web version styling
│   └── game.js            # Web version logic
├── project.godot           # Godot project configuration
└── README.md              # Project overview
```

## Godot Project Structure Principles

### scenes/ - Game Scenes
- **Main.tscn**: Primary game scene containing all UI panels and game manager
- **Modular Design**: Each major component as separate scene nodes
- **Hierarchical Layout**: Logical parent-child relationships for UI elements

### scripts/ - Game Logic
- **GameManager.gd**: Centralized game state and business logic
- **UI/ Directory**: Specialized UI controllers for different interface sections
- **Class-based**: Each script defines a class with clear responsibilities

## Naming Conventions
- **GDScript**: snake_case for variables/functions, PascalCase for classes
- **Scenes**: PascalCase for scene names (Main.tscn, GalaxyMap.tscn)
- **Nodes**: Descriptive names reflecting their purpose (GameManager, MainUI)
- **Signals**: Past tense verbs (credits_changed, location_changed)
- **Game Elements**: Space-themed names (stellar, cosmic, galactic, etc.)

## Code Organization Patterns

### GDScript Structure (GameManager.gd)
```gdscript
# 1. Class declaration and signals
extends Node
class_name GameManager
signal credits_changed(new_credits: int)

# 2. Game state variables
var credits: int = 10000
var planets: Dictionary = { ... }

# 3. Core game functions
func _ready():
func calculate_price():
func buy_good():

# 4. Signal handlers and utilities
func _on_location_changed():
```

### Scene Organization (Main.tscn)
```
Main (Control)
├── GameManager (Node) - Game logic
├── Background (ColorRect) - Visual background
└── MainUI (Control) - Interface controller
    ├── Header (Panel) - Game stats display
    └── GameArea (HSplitContainer)
        ├── GalaxyMap (Control) - Visual map
        └── Panels (VBoxContainer) - Info panels
```

## Development Workflow
1. **Design in Godot Editor**: Use visual scene editor for UI layout
2. **Script in External Editor**: Write GDScript in preferred text editor
3. **Test with F5**: Quick play testing in Godot editor
4. **Version Control**: Commit scenes and scripts together
5. **Document in docs/**: Keep design doc updated with new features

## Godot-Specific Best Practices
- **Signal-Driven Architecture**: Use signals for loose coupling between systems
- **Scene Composition**: Break complex UIs into reusable scene components
- **Node References**: Use @onready var for node references
- **Resource Management**: Properly free nodes with queue_free()
- **Performance**: Minimize _process() usage, prefer signals for updates

## Next Development Priorities
Based on the design document and Godot capabilities:
1. Ship upgrade system with visual feedback
2. Enhanced galaxy map with animations
3. Save/load system using Godot's resource system
4. Audio integration for space ambiance
5. Particle effects for ship travel