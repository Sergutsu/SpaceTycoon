# Design Document

## Overview

The UI refactor transforms the current static panel-based interface into a modern, flexible system with a full-screen galaxy map, detachable/foldable panels, and responsive design. The architecture leverages Godot's Control node system with custom components for panel management, drag-and-drop functionality, and responsive layout handling.

## Architecture

### Core Components

1. **ResponsiveUIManager** - Main controller managing layout states and panel coordination
2. **DetachablePanel** - Custom Control class for panels with fold/detach capabilities  
3. **GalaxyMapController** - Enhanced map with zoom/pan navigation
4. **TopNavigationBar** - Fixed header with responsive resource display
5. **PanelDockingSystem** - Handles panel attachment/detachment logic
6. **UIStateManager** - Persists and restores panel configurations

### Component Hierarchy

```
Main (Control)
├── ResponsiveUIManager (Control)
│   ├── TopNavigationBar (Control)
│   │   ├── GameLogo (TextureRect)
│   │   ├── ResourceDisplay (HBoxContainer)
│   │   └── SettingsButton (Button)
│   ├── GalaxyMapController (Control)
│   │   ├── MapViewport (SubViewport)
│   │   └── MapCamera (Camera2D)
│   ├── PanelContainer (Control)
│   │   ├── LocationPanel (DetachablePanel)
│   │   ├── MarketPanel (DetachablePanel)
│   │   ├── TravelPanel (DetachablePanel)
│   │   └── [Other Panels] (DetachablePanel)
│   └── FloatingPanels (Control)
└── GameManager (Node)
```

## Components and Interfaces

### ResponsiveUIManager

**Purpose:** Central coordinator for the entire UI system

**Key Methods:**
- `_ready()` - Initialize all UI components and connect signals
- `_on_window_resized()` - Handle responsive layout adjustments
- `dock_panel(panel: DetachablePanel, position: Vector2)` - Dock a floating panel
- `undock_panel(panel: DetachablePanel)` - Convert docked panel to floating
- `save_layout_state()` - Persist current panel configuration
- `restore_layout_state()` - Load saved panel configuration

**Signals:**
- `panel_docked(panel: DetachablePanel)`
- `panel_undocked(panel: DetachablePanel)`
- `layout_changed()`

### DetachablePanel

**Purpose:** Enhanced panel with fold/detach capabilities

**Properties:**
- `is_folded: bool` - Current fold state
- `is_detached: bool` - Current attachment state
- `original_position: Vector2` - Docked position for restoration
- `panel_title: String` - Display title for the panel
- `min_size: Vector2` - Minimum size when detached

**Key Methods:**
- `toggle_fold()` - Animate fold/unfold transition
- `detach()` - Convert to floating window
- `attach()` - Return to docked position
- `_on_title_bar_dragged(event: InputEvent)` - Handle drag initiation
- `_create_title_bar()` - Build interactive title bar with controls

**Signals:**
- `fold_toggled(is_folded: bool)`
- `detach_requested()`
- `attach_requested()`

### GalaxyMapController

**Purpose:** Full-screen interactive galaxy map with navigation

**Properties:**
- `zoom_level: float` - Current zoom scale (0.5 to 3.0)
- `pan_offset: Vector2` - Current pan position
- `zoom_speed: float` - Mouse wheel zoom sensitivity
- `pan_speed: float` - Drag pan sensitivity

**Key Methods:**
- `_input(event: InputEvent)` - Handle zoom/pan input
- `zoom_to_level(level: float)` - Animate zoom transition
- `pan_to_position(pos: Vector2)` - Animate pan transition
- `reset_view()` - Return to default zoom/pan state
- `_update_camera_transform()` - Apply zoom/pan to camera

**Signals:**
- `view_changed(zoom: float, pan: Vector2)`
- `system_clicked(system_id: String)`

### TopNavigationBar

**Purpose:** Fixed responsive header with game information

**Properties:**
- `resource_displays: Array[Control]` - Dynamic resource indicators
- `breakpoint_width: int` - Width threshold for layout changes

**Key Methods:**
- `_on_credits_changed(amount: int)` - Update credits display
- `_on_fuel_changed(amount: int)` - Update fuel display  
- `_on_cargo_changed(cargo: Dictionary)` - Update cargo display
- `_adapt_to_width(width: int)` - Responsive layout adjustment
- `_show_artifact_indicators()` - Display active bonus indicators

### PanelDockingSystem

**Purpose:** Manages panel attachment/detachment logic

**Properties:**
- `dock_zones: Array[Rect2]` - Valid docking areas
- `snap_distance: float` - Pixel threshold for docking hints
- `docking_preview: Control` - Visual feedback for docking

**Key Methods:**
- `check_docking_zones(position: Vector2)` - Find valid dock position
- `show_docking_hint(zone: Rect2)` - Display visual docking feedback
- `hide_docking_hint()` - Remove docking feedback
- `snap_to_dock(panel: DetachablePanel, zone: Rect2)` - Execute docking

## Data Models

### PanelState

```gdscript
class_name PanelState

var panel_id: String
var is_folded: bool = false
var is_detached: bool = false
var position: Vector2 = Vector2.ZERO
var size: Vector2 = Vector2.ZERO
var dock_index: int = -1
```

### UILayoutConfig

```gdscript
class_name UILayoutConfig

var panel_states: Dictionary = {}  # panel_id -> PanelState
var galaxy_map_zoom: float = 1.0
var galaxy_map_pan: Vector2 = Vector2.ZERO
var window_size: Vector2 = Vector2.ZERO
var top_bar_collapsed: bool = false
```

### ResponsiveBreakpoints

```gdscript
class_name ResponsiveBreakpoints

const MOBILE_WIDTH = 768
const TABLET_WIDTH = 1024
const DESKTOP_WIDTH = 1440

enum LayoutMode {
    MOBILE,
    TABLET, 
    DESKTOP
}
```

## Error Handling

### Panel Management Errors

- **Invalid Panel State:** Gracefully handle corrupted panel configurations by resetting to defaults
- **Docking Conflicts:** Prevent multiple panels from occupying the same dock position
- **Memory Leaks:** Ensure proper cleanup of detached panels when closed

### Map Navigation Errors

- **Zoom Limits:** Clamp zoom values to prevent rendering issues or performance problems
- **Pan Boundaries:** Implement soft boundaries to keep map content visible
- **Input Conflicts:** Handle simultaneous zoom/pan operations without interference

### Responsive Layout Errors

- **Overflow Handling:** Gracefully adapt when content exceeds available space
- **Minimum Size Enforcement:** Prevent panels from becoming unusably small
- **Aspect Ratio Preservation:** Maintain visual consistency across different screen sizes

## Testing Strategy

### Unit Tests

1. **DetachablePanel Tests**
   - Fold/unfold state transitions
   - Drag detection and handling
   - Size constraint validation
   - Signal emission verification

2. **GalaxyMapController Tests**
   - Zoom level clamping
   - Pan boundary enforcement
   - Input event processing
   - Camera transform calculations

3. **ResponsiveUIManager Tests**
   - Layout adaptation logic
   - Panel coordination
   - State persistence/restoration
   - Breakpoint handling

### Integration Tests

1. **Panel Interaction Tests**
   - Drag-and-drop between docked/floating states
   - Multiple panel management
   - Docking zone detection and snapping
   - Layout persistence across sessions

2. **Map Integration Tests**
   - Map interaction while panels are floating
   - Responsive behavior during window resize
   - Performance with multiple detached panels
   - State synchronization between components

3. **Responsive Design Tests**
   - Layout adaptation at different screen sizes
   - Panel stacking and overflow handling
   - Touch/mobile interaction compatibility
   - Accessibility compliance

### Performance Tests

1. **Rendering Performance**
   - Frame rate with multiple floating panels
   - Galaxy map zoom/pan smoothness
   - Animation performance during fold/unfold
   - Memory usage with detached panels

2. **Input Responsiveness**
   - Drag operation latency
   - Zoom/pan input lag
   - Panel interaction response time
   - Multi-touch gesture handling

### Visual Tests

1. **Layout Verification**
   - Panel positioning accuracy
   - Responsive breakpoint transitions
   - Animation smoothness and timing
   - Visual feedback consistency

2. **Cross-Platform Testing**
   - Windows desktop layout
   - Different screen resolutions
   - High DPI display compatibility
   - Window manager integration

## Implementation Notes

### Godot-Specific Considerations

- Use `Control.set_anchors_and_offsets_preset()` for responsive layouts
- Leverage `Tween` nodes for smooth panel animations
- Implement custom `_gui_input()` handlers for drag operations
- Use `SubViewport` for isolated galaxy map rendering
- Employ `Theme` resources for consistent styling

### Performance Optimizations

- Pool detached panel instances to reduce allocation overhead
- Use `CanvasLayer` for floating panels to optimize rendering
- Implement viewport culling for off-screen galaxy map elements
- Cache layout calculations to avoid redundant computations
- Use signals instead of polling for state changes

### Accessibility Features

- Keyboard navigation support for all panel operations
- Screen reader compatibility for panel states
- High contrast mode support
- Configurable animation speeds for motion sensitivity
- Focus management for detached panels