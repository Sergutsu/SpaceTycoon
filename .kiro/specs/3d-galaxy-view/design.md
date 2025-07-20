# Design Document

## Overview

The 3D Galaxy View will replace the current 2D galaxy map with an immersive 3D space environment using Godot's 3D capabilities. The design focuses on simplicity and clarity, using only primitive shapes (spheres, cubes, cylinders) with solid colors to represent celestial objects and the player's ship. This approach maintains visual clarity while providing a more engaging spatial experience for trade route planning.

## Architecture

### Scene Structure
```
Main (Control) - Existing 2D UI root
├── GameManager (Node) - Existing game logic
├── MainUI (Control) - Existing 2D UI panels
└── Galaxy3DViewport (SubViewport) - New 3D container
    └── Galaxy3DScene (Node3D) - 3D galaxy root
        ├── Camera3D - Player camera with orbit controls
        ├── Environment - Lighting and space background
        ├── PlanetContainer (Node3D) - Container for all planets
        │   ├── Planet_TerraPreime (Node3D) - Individual planet nodes
        │   ├── Planet_MinervaStation (Node3D)
        │   └── ... (other planets)
        ├── ShipContainer (Node3D) - Container for ship
        │   └── PlayerShip (Node3D) - Player ship representation
        └── EffectsContainer (Node3D) - Travel lines, particles, etc.
```

### Integration Strategy
The 3D galaxy view will be embedded within the existing 2D UI structure using a SubViewport, allowing seamless integration with current UI panels while providing 3D visualization. The GameManager will continue to handle all game logic, with the 3D view acting as a visual representation layer.

## Components and Interfaces

### Galaxy3DController
**Purpose**: Main controller for the 3D galaxy scene
**Responsibilities**:
- Initialize 3D scene with planet positions
- Handle camera controls (orbit, zoom, pan)
- Manage planet selection and interaction
- Coordinate with GameManager for state updates
- Handle ship movement animations

**Key Methods**:
```gdscript
func initialize_galaxy() -> void
func update_planet_data(system_id: String, data: Dictionary) -> void
func select_planet(system_id: String) -> void
func animate_ship_travel(from: String, to: String) -> void
func update_camera_controls(delta: float) -> void
```

### Planet3D
**Purpose**: Individual planet representation in 3D space
**Responsibilities**:
- Visual representation using primitive shapes
- Handle mouse interaction (click, hover)
- Display visual states (current location, visited, unexplored)
- Show selection and hover effects

**Key Properties**:
```gdscript
var system_id: String
var planet_data: Dictionary
var mesh_instance: MeshInstance3D
var collision_area: Area3D
var is_selected: bool = false
var is_hovered: bool = false
```

### Ship3D
**Purpose**: Player ship representation and movement
**Responsibilities**:
- Visual ship representation using primitives
- Smooth movement animations between planets
- Position tracking and updates
- Visual effects (engine glow, travel trail)

### CameraController3D
**Purpose**: 3D camera control system
**Responsibilities**:
- Orbit camera around galaxy center
- Zoom in/out with mouse wheel
- Pan camera with mouse drag
- Smooth camera transitions
- Maintain camera bounds

**Control Scheme**:
- **Mouse Drag**: Orbit camera around galaxy center
- **Mouse Wheel**: Zoom in/out
- **Middle Mouse Drag**: Pan camera
- **Automatic Bounds**: Keep planets visible

## Data Models

### Galaxy3DData
```gdscript
class_name Galaxy3DData

var planets: Dictionary = {}  # system_id -> Planet3DData
var ship_position: Vector3
var camera_position: Vector3
var camera_target: Vector3
var selected_planet: String = ""
```

### Planet3DData
```gdscript
class_name Planet3DData

var system_id: String
var position: Vector3
var color: Color
var size: float
var planet_type: String  # "agricultural", "mining", "luxury", etc.
var is_visited: bool = false
var is_current_location: bool = false
```

### Visual Design Specifications

#### Planet Representation
- **Shape**: Sphere primitive (SphereMesh)
- **Size**: Varies by planet type (0.8 - 1.5 scale)
- **Colors**:
  - Terra Prime: Green (#00FF00)
  - Minerva Station: Orange (#FFA500)
  - Luxuria Resort: Purple (#800080)
  - Frontier Outpost: Red (#FF0000)
  - Nexus Station: Cyan (#00FFFF)

#### Ship Representation
- **Shape**: Elongated cube or custom primitive
- **Color**: White (#FFFFFF) with gold trim
- **Size**: Small relative to planets (0.3 scale)
- **Effects**: Subtle glow shader for engine

#### Visual States
- **Unexplored Planets**: 50% opacity, no glow
- **Visited Planets**: Full opacity, subtle glow
- **Current Location**: Bright glow, pulsing effect
- **Selected Planet**: Highlighted outline, increased glow
- **Hovered Planet**: Subtle scale increase (1.1x)

## Error Handling

### 3D Scene Loading
- **Fallback**: If 3D scene fails to load, maintain 2D galaxy view
- **Error Detection**: Monitor SubViewport initialization
- **User Notification**: Display message if 3D features unavailable

### Performance Considerations
- **LOD System**: Reduce planet detail at distance
- **Culling**: Hide planets outside camera view
- **Frame Rate Monitoring**: Detect performance issues
- **Automatic Fallback**: Switch to 2D if FPS drops below threshold

### Input Handling
- **Mouse Capture**: Ensure 3D viewport receives input correctly
- **Touch Support**: Basic touch controls for mobile compatibility
- **Keyboard Shortcuts**: Alternative selection methods

## Testing Strategy

### Unit Testing
- **Planet3D Component**: Test planet creation, state changes, interactions
- **CameraController3D**: Test camera movement, bounds checking, input handling
- **Ship3D Component**: Test ship positioning, movement animations
- **Galaxy3DController**: Test scene initialization, data synchronization

### Integration Testing
- **GameManager Integration**: Verify 3D view updates with game state changes
- **UI Panel Integration**: Test planet selection updates UI panels correctly
- **Travel System**: Test ship movement animations match travel actions
- **Performance Testing**: Verify smooth operation with all planets visible

### Visual Testing
- **Planet Positioning**: Verify planets appear in correct 3D positions
- **Color Accuracy**: Confirm planet colors match design specifications
- **Animation Smoothness**: Test ship travel and camera movement fluidity
- **State Visualization**: Verify visual states (selected, visited, etc.) display correctly

### User Experience Testing
- **Camera Controls**: Test intuitive camera movement and bounds
- **Planet Selection**: Verify easy planet clicking and selection feedback
- **Information Display**: Test tooltip and panel integration
- **Performance**: Ensure smooth interaction on target hardware

## Implementation Phases

### Phase 1: Core 3D Scene Setup
- Create Galaxy3DScene with basic camera and lighting
- Implement planet positioning using primitive spheres
- Basic camera orbit controls
- Integration with existing UI structure

### Phase 2: Planet Interaction System
- Implement planet selection and hover detection
- Add visual state management (visited, selected, etc.)
- Connect planet selection to UI panel updates
- Add planet tooltips and information display

### Phase 3: Ship Representation and Movement
- Create ship 3D model using primitives
- Implement ship positioning at current location
- Add smooth ship movement animations for travel
- Visual effects for ship (glow, trail)

### Phase 4: Polish and Optimization
- Add visual effects (planet glow, space particles)
- Optimize performance and add fallback systems
- Enhanced camera controls and bounds
- Final visual polish and testing

## Technical Considerations

### Godot 3D Integration
- **SubViewport Usage**: Embed 3D scene within 2D UI structure
- **Input Handling**: Ensure proper mouse event routing to 3D viewport
- **Rendering Pipeline**: Maintain good performance with 3D rendering
- **Resource Management**: Proper cleanup of 3D resources

### Coordinate System
- **3D Positioning**: Convert 2D galaxy positions to 3D space
- **Scale Considerations**: Maintain readable planet spacing
- **Camera Distance**: Optimal viewing distance for all planets
- **Depth Management**: Ensure proper depth sorting and visibility

### Performance Optimization
- **Primitive Meshes**: Use built-in Godot primitives for efficiency
- **Minimal Shaders**: Simple materials without complex shading
- **Culling**: Implement frustum culling for off-screen planets
- **LOD**: Reduce detail for distant objects if needed