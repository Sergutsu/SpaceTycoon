# UI Scene Architecture Refactor - Design

## Overview

This design document outlines the architectural changes needed to convert the current programmatic UI creation system to a proper Godot scene-based architecture. The refactor will improve maintainability, debugging capabilities, and follow Godot best practices.

## Architecture

### Current Architecture Issues

1. **Programmatic UI Creation**: Many UI elements are created using `new()` in scripts
2. **Mixed Responsibilities**: Scripts handle both UI creation and business logic
3. **Hard to Debug**: Dynamic UI elements don't appear in scene tree
4. **Difficult to Modify**: UI changes require code modifications instead of visual editing

### Target Architecture

```
scenes/
├── UI/
│   ├── HUD/
│   │   ├── SimpleHUD.tscn          # Main HUD scene
│   │   ├── AlertItem.tscn          # Template for alert items
│   │   └── QuickNavButton.tscn     # Template for navigation buttons
│   ├── Panels/
│   │   ├── MainStatusPanel.tscn    # Already exists
│   │   ├── MarketScreen.tscn       # Already exists
│   │   ├── AssetManagementPanel.tscn # Already exists
│   │   └── NotificationCenter.tscn # Already exists
│   └── Components/
│       ├── MarketItem.tscn         # Template for market entries
│       ├── NotificationItem.tscn   # Template for notifications
│       └── MissionItem.tscn        # Template for mission entries

scripts/UI/
├── SimpleHUD.gd                    # Logic only, no UI creation
├── AlertItem.gd                    # Individual alert logic
├── QuickNavButton.gd               # Button behavior logic
└── Components/
    ├── MarketItem.gd               # Market item logic
    ├── NotificationItem.gd         # Notification logic
    └── MissionItem.gd              # Mission item logic
```

## Components and Interfaces

### 1. SimpleHUD Scene Structure

**SimpleHUD.tscn** will contain:
```
SimpleHUD (Control) [SimpleHUD.gd]
├── HeaderPanel (Panel)
│   └── HeaderContainer (HBoxContainer)
│       ├── TitleLabel (Label)
│       └── StatsContainer (HBoxContainer)
│           ├── CreditsLabel (Label)
│           ├── FuelLabel (Label)
│           ├── CargoLabel (Label)
│           └── LocationLabel (Label)
├── AlertBar (Panel)
│   └── AlertContainer (HBoxContainer)
├── MiniMapPlaceholder (Panel)
│   └── MiniMapLabel (Label)
├── PerformanceDisplay (Panel)
│   └── FPSLabel (Label)
├── TrendPanel (Panel)
│   └── TrendContainer (VBoxContainer)
│       └── TrendTitle (Label)
├── ArtifactPanel (Panel)
│   └── ArtifactContainer (HBoxContainer)
│       └── ArtifactTitle (Label)
├── NotificationIndicator (Button)
├── NavigationStatus (Panel)
│   └── NavigationLabel (Label)
└── QuickNavigation (HBoxContainer)
```

### 2. Alert System Components

**AlertItem.tscn**:
```
AlertItem (Panel) [AlertItem.gd]
└── ContentContainer (HBoxContainer)
    ├── AlertLabel (Label)
    └── TimeLabel (Label)
```

**AlertItem.gd**:
```gdscript
extends Panel
class_name AlertItem

@onready var alert_label: Label = $ContentContainer/AlertLabel
@onready var time_label: Label = $ContentContainer/TimeLabel

func setup_alert(alert_data: Dictionary):
    # Configure alert appearance and content
    
func set_alert_type(type: String):
    # Apply styling based on alert type
```

### 3. Quick Navigation Components

**QuickNavButton.tscn**:
```
QuickNavButton (Button) [QuickNavButton.gd]
```

**QuickNavButton.gd**:
```gdscript
extends Button
class_name QuickNavButton

signal panel_requested(panel_name: String)

var panel_name: String
var shortcut_key: String

func setup_button(key: String, label: String, target_panel: String):
    # Configure button appearance and behavior
```

### 4. Dynamic Content Templates

**MarketItem.tscn**, **NotificationItem.tscn**, **MissionItem.tscn** will follow similar patterns with dedicated scripts for their specific logic.

## Data Models

### UI Component Data Flow

```gdscript
# Instead of creating UI programmatically:
# OLD WAY:
func _create_alert_widget(alert_data: Dictionary) -> Control:
    var alert_panel = Panel.new()
    var alert_label = Label.new()
    # ... lots of setup code

# NEW WAY:
func add_alert(alert_data: Dictionary):
    var alert_item = preload("res://scenes/UI/HUD/AlertItem.tscn").instantiate()
    alert_item.setup_alert(alert_data)
    alert_container.add_child(alert_item)
```

### Scene Template System

```gdscript
# Template manager for dynamic content
class_name UITemplates

const ALERT_ITEM = preload("res://scenes/UI/HUD/AlertItem.tscn")
const MARKET_ITEM = preload("res://scenes/UI/Components/MarketItem.tscn")
const NOTIFICATION_ITEM = preload("res://scenes/UI/Components/NotificationItem.tscn")

static func create_alert_item() -> AlertItem:
    return ALERT_ITEM.instantiate()

static func create_market_item() -> MarketItem:
    return MARKET_ITEM.instantiate()
```

## Error Handling

### Scene Loading Validation

```gdscript
func _ready():
    # Validate all required UI elements exist
    assert(alert_container != null, "AlertContainer not found in scene")
    assert(stats_container != null, "StatsContainer not found in scene")
    
    # Initialize with scene-based elements
    _initialize_ui_elements()
```

### Template Instantiation Safety

```gdscript
func add_dynamic_item(template_path: String, setup_data: Dictionary):
    var template = load(template_path)
    if not template:
        push_error("Failed to load UI template: " + template_path)
        return null
    
    var instance = template.instantiate()
    if instance.has_method("setup"):
        instance.setup(setup_data)
    
    return instance
```

## Testing Strategy

### 1. Scene Validation Tests
- Verify all required nodes exist in scene files
- Test scene instantiation doesn't fail
- Validate node paths and references

### 2. UI Logic Tests
- Test UI updates work with scene-based elements
- Verify dynamic content creation using templates
- Test cleanup and memory management

### 3. Visual Regression Tests
- Compare before/after screenshots
- Verify all styling is preserved
- Test responsive behavior

### 4. Performance Tests
- Compare memory usage before/after
- Test instantiation performance
- Verify no performance regression

## Migration Strategy

### Phase 1: Create Scene Templates
1. Create AlertItem.tscn and AlertItem.gd
2. Create QuickNavButton.tscn and QuickNavButton.gd
3. Create other component templates

### Phase 2: Convert SimpleHUD
1. Create SimpleHUD.tscn with full structure
2. Modify SimpleHUD.gd to use scene elements
3. Remove all `_create_ui_elements()` code
4. Test functionality preservation

### Phase 3: Convert Dynamic Content
1. Replace programmatic alert creation with template instantiation
2. Convert market item creation to use templates
3. Update notification system to use templates

### Phase 4: Clean Up and Optimize
1. Remove all unused UI creation code
2. Optimize scene loading and instantiation
3. Add proper error handling
4. Update documentation

## Implementation Details

### SimpleHUD.gd Refactor

```gdscript
# BEFORE (programmatic creation):
func _create_ui_elements():
    var header_panel = Panel.new()
    var credits_label = Label.new()
    # ... hundreds of lines of UI creation

# AFTER (scene-based):
func _ready():
    # All UI elements already exist in scene
    _connect_signals()
    _initialize_displays()

func add_alert(alert_data: Dictionary):
    var alert_item = UITemplates.create_alert_item()
    alert_item.setup_alert(alert_data)
    alert_container.add_child(alert_item)
```

### Theme Integration

```gdscript
# Use Godot's built-in theme system instead of programmatic styling
func _ready():
    # Themes applied automatically through scene theme property
    # No need for programmatic StyleBox creation
```

## Benefits of New Architecture

1. **Visual Editing**: All UI can be modified in Godot editor
2. **Better Debugging**: UI elements visible in remote inspector
3. **Improved Performance**: Scene instantiation is optimized
4. **Maintainability**: Separation of concerns between UI and logic
5. **Reusability**: Component templates can be reused across panels
6. **Consistency**: Standardized approach across all UI elements

## Risk Mitigation

1. **Functionality Preservation**: Extensive testing to ensure no features are lost
2. **Performance Monitoring**: Benchmark before/after to ensure no regression
3. **Gradual Migration**: Phase-by-phase approach to minimize risk
4. **Rollback Plan**: Keep backup of working system until migration is complete