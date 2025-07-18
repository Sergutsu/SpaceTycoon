extends Control
class_name GalaxyMap

# Game Manager reference
var game_manager: GameManager

# Visual elements
var planet_nodes: Dictionary = {}
var ship_node: Control
var current_planet_id: String = "terra"

# Planet colors
var planet_colors: Dictionary = {
	"terra": Color.GREEN,
	"minerva": Color.ORANGE,
	"luxuria": Color.PURPLE
}

func _ready():
	# Get game manager reference
	game_manager = get_node("../../../GameManager")
	
	# Connect to location changes
	game_manager.location_changed.connect(_on_location_changed)
	
	# Create visual elements
	_create_planets()
	_create_ship()

func _create_planets():
	for planet_id in game_manager.planets.keys():
		var planet_data = game_manager.planets[planet_id]
		var planet_node = _create_planet_node(planet_id, planet_data)
		add_child(planet_node)
		planet_nodes[planet_id] = planet_node

func _create_planet_node(planet_id: String, planet_data: Dictionary) -> Control:
	var planet_container = Control.new()
	planet_container.name = "Planet_" + planet_id
	
	# Position the planet
	var pos = planet_data["position"]
	planet_container.position = pos
	planet_container.size = Vector2(120, 100)
	planet_container.pivot_offset = Vector2(60, 50)
	
	# Planet visual (circle)
	var planet_visual = ColorRect.new()
	planet_visual.size = Vector2(60, 60)
	planet_visual.position = Vector2(30, 10)
	planet_visual.color = planet_colors[planet_id]
	
	# Make it circular (approximate with border radius)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = planet_colors[planet_id]
	style_box.corner_radius_top_left = 30
	style_box.corner_radius_top_right = 30
	style_box.corner_radius_bottom_left = 30
	style_box.corner_radius_bottom_right = 30
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.CYAN
	
	var planet_panel = Panel.new()
	planet_panel.size = Vector2(60, 60)
	planet_panel.position = Vector2(30, 10)
	planet_panel.add_theme_stylebox_override("panel", style_box)
	
	# Planet name
	var name_label = Label.new()
	name_label.text = planet_data["name"]
	name_label.position = Vector2(0, 75)
	name_label.size = Vector2(120, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color.CYAN)
	
	# Make planet clickable
	var button = Button.new()
	button.size = Vector2(120, 100)
	button.flat = true
	button.pressed.connect(_on_planet_clicked.bind(planet_id))
	
	planet_container.add_child(planet_panel)
	planet_container.add_child(name_label)
	planet_container.add_child(button)
	
	return planet_container

func _create_ship():
	ship_node = Control.new()
	ship_node.name = "PlayerShip"
	ship_node.size = Vector2(30, 30)
	
	# Ship visual (triangle)
	var ship_visual = ColorRect.new()
	ship_visual.size = Vector2(20, 20)
	ship_visual.position = Vector2(5, 5)
	ship_visual.color = Color.RED
	
	# Create triangle shape (approximate)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.RED
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color.WHITE
	
	var ship_panel = Panel.new()
	ship_panel.size = Vector2(20, 20)
	ship_panel.position = Vector2(5, 5)
	ship_panel.add_theme_stylebox_override("panel", style_box)
	
	ship_node.add_child(ship_panel)
	add_child(ship_node)
	
	# Position ship at starting planet
	_position_ship_at_planet(current_planet_id)

func _position_ship_at_planet(planet_id: String):
	if planet_nodes.has(planet_id):
		var planet_pos = game_manager.planets[planet_id]["position"]
		# Position ship slightly offset from planet center
		ship_node.position = planet_pos + Vector2(70, 35)

func _on_planet_clicked(planet_id: String):
	if planet_id != current_planet_id:
		# Check if we can travel (enough fuel)
		var fuel_cost = game_manager.travel_distances[current_planet_id][planet_id]
		if game_manager.fuel >= fuel_cost:
			game_manager.travel_to_planet(planet_id)

func _on_location_changed(planet_id: String):
	current_planet_id = planet_id
	
	# Animate ship movement
	var tween = create_tween()
	var target_pos = game_manager.planets[planet_id]["position"] + Vector2(70, 35)
	tween.tween_property(ship_node, "position", target_pos, 1.0)
	tween.tween_callback(_on_ship_movement_complete)

func _on_ship_movement_complete():
	# Ship has arrived at destination
	pass
