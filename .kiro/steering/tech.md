# Technology Stack

## Current Implementation
- **Game Engine**: Godot 4.4
- **Programming Language**: GDScript
- **Architecture**: Scene-based with signal-driven communication
- **Platform Target**: Desktop (Windows, Linux, macOS) with potential mobile export

## Technology Choices Rationale
- **Godot Engine**: Open source, lightweight, excellent 2D support
- **GDScript**: Native to Godot, Python-like syntax, optimized for game development
- **Scene System**: Modular, reusable components with clear hierarchy
- **Signal System**: Decoupled communication between game systems

## Development Workflow
```bash
# Open project in Godot Editor
godot project.godot

# Run project
F5 or Play button in editor

# Export builds
Project -> Export -> Select platform
```

## File Organization
```
SpaceTycoon/
├── project.godot           # Project configuration
├── scenes/                 # Scene files (.tscn)
│   └── Main.tscn          # Main game scene
├── scripts/               # GDScript files (.gd)
│   ├── GameManager.gd     # Core game logic and state
│   └── UI/                # UI-specific scripts
│       ├── MainUI.gd      # Main interface controller
│       └── GalaxyMap.gd   # Galaxy map visualization
└── JSPrototype/           # Original web prototype (reference)
```

## Code Standards
- **GDScript**: Follow Godot style guide, use snake_case for variables/functions
- **Signals**: Use for decoupled communication between nodes
- **Classes**: Use class_name for reusable components
- **Comments**: Document complex game logic and signal connections
- **Node Structure**: Keep scene hierarchy clean and logical

## Godot-Specific Patterns
- **MVC Architecture**: GameManager (Model), UI scripts (View/Controller)
- **Signal-Driven**: Game state changes emit signals to update UI
- **Scene Composition**: Modular scenes for different game components
- **Resource Management**: Use Godot's resource system for game data

## Performance Considerations
- **Node Optimization**: Minimize deep node hierarchies
- **Signal Efficiency**: Avoid excessive signal emissions
- **Memory Management**: Proper node cleanup with queue_free()
- **Rendering**: Use appropriate node types for visual elements

## Build and Export
- **Desktop Builds**: Windows, Linux, macOS executables
- **Mobile Potential**: Android/iOS export available
- **Web Export**: HTML5 build possible but with limitations
- **Distribution**: Standalone executables, no runtime dependencies

## Development Tools
- **Godot Editor**: Built-in scene editor, debugger, profiler
- **Version Control**: Git-friendly text-based scene format
- **Asset Pipeline**: Built-in import system for textures, audio
- **Debugging**: Integrated debugger with breakpoints and inspection