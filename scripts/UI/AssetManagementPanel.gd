extends Control
class_name AssetManagementPanel

# Asset Management Panel - Ship and fleet management
# Based on views.md: "Detailed ship stats, upgrades, module management, upgrade purchase system"

# References
var game_manager: GameManager

# UI References
var ship_info_panel: Panel
var upgrades_panel: Panel
var modules_panel: Panel
var comparison_panel: Panel

# Current ship data
var current_ship_stats: Dictionary = {}
var available_upgrades: Dictionary = {}

func _ready():
	print("AssetManagementPanel: Initializing...")
	_create_ui_elements()

func initialize(gm: GameManager):
	"""Initialize asset management panel with game manager reference"""
	game_manager = gm
	
	# Connect to ship system signals
	if game_manager.ship_system:
		game_manager.ship_system.ship_upgraded.connect(_on_ship_upgraded)
		game_manager.ship_system.upgrade_purchased.connect(_on_upgrade_purchased)
	
	# Connect to game manager signals
	game_manager.ship_stats_updated.connect(_on_ship_stats_updated)
	
	# Initial data load
	_refresh_ship_data()
	_update_all_displays()
	
	print("AssetManagementPanel: Initialized with GameManager")

func _create_ui_elements():
	"""Create the asset management UI dynamically"""
	# Main container
	var main_container = VBoxContainer.new()
	main_container.anchors_preset = Control.PRESET_FULL_RECT
	main_container.offset_left = 10
	main_container.offset_right = -10
	main_container.offset_top = 10
	main_container.offset_bottom = -10
	add_child(main_container)
	
	# Title
	var title_label = Label.new()
	title_label.text = "Fleet & Asset Management"
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color.ORANGE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title_label)
	
	# Main content area
	var content_area = HSplitContainer.new()
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(content_area)
	
	# Left side - Ship info and modules
	var left_panel = VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(400, 0)
	content_area.add_child(left_panel)
	
	_create_ship_info_panel(left_panel)
	_create_modules_panel(left_panel)
	
	# Right side - Upgrades and comparison
	var right_panel = VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.add_child(right_panel)
	
	_create_upgrades_panel(right_panel)
	_create_comparison_panel(right_panel)

func _create_ship_info_panel(parent: Control):
	"""Create ship information display"""
	var ship_title = Label.new()
	ship_title.text = "Ship Information"
	ship_title.add_theme_font_size_override("font_size", 16)
	ship_title.add_theme_color_override("font_color", Color.CYAN)
	parent.add_child(ship_title)
	
	ship_info_panel = Panel.new()
	ship_info_panel.custom_minimum_size = Vector2(0, 200)
	parent.add_child(ship_info_panel)
	
	var ship_scroll = ScrollContainer.new()
	ship_scroll.anchors_preset = Control.PRESET_FULL_RECT
	ship_scroll.offset_left = 10
	ship_scroll.offset_right = -10
	ship_scroll.offset_top = 10
	ship_scroll.offset_bottom = -10
	ship_info_panel.add_child(ship_scroll)
	
	var ship_container = VBoxContainer.new()
	ship_container.name = "ShipInfoContainer"
	ship_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ship_scroll.add_child(ship_container)

func _create_modules_panel(parent: Control):
	"""Create ship modules display"""
	var modules_title = Label.new()
	modules_title.text = "Ship Modules"
	modules_title.add_theme_font_size_override("font_size", 16)
	modules_title.add_theme_color_override("font_color", Color.GREEN)
	parent.add_child(modules_title)
	
	modules_panel = Panel.new()
	modules_panel.custom_minimum_size = Vector2(0, 150)
	parent.add_child(modules_panel)
	
	var modules_scroll = ScrollContainer.new()
	modules_scroll.anchors_preset = Control.PRESET_FULL_RECT
	modules_scroll.offset_left = 10
	modules_scroll.offset_right = -10
	modules_scroll.offset_top = 10
	modules_scroll.offset_bottom = -10
	modules_panel.add_child(modules_scroll)
	
	var modules_container = VBoxContainer.new()
	modules_container.name = "ModulesContainer"
	modules_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modules_scroll.add_child(modules_container)

func _create_upgrades_panel(parent: Control):
	"""Create upgrades purchase panel"""
	var upgrades_title = Label.new()
	upgrades_title.text = "Available Upgrades"
	upgrades_title.add_theme_font_size_override("font_size", 16)
	upgrades_title.add_theme_color_override("font_color", Color.PURPLE)
	parent.add_child(upgrades_title)
	
	upgrades_panel = Panel.new()
	upgrades_panel.custom_minimum_size = Vector2(0, 250)
	parent.add_child(upgrades_panel)
	
	var upgrades_scroll = ScrollContainer.new()
	upgrades_scroll.anchors_preset = Control.PRESET_FULL_RECT
	upgrades_scroll.offset_left = 10
	upgrades_scroll.offset_right = -10
	upgrades_scroll.offset_top = 10
	upgrades_scroll.offset_bottom = -10
	upgrades_panel.add_child(upgrades_scroll)
	
	var upgrades_container = VBoxContainer.new()
	upgrades_container.name = "UpgradesContainer"
	upgrades_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades_scroll.add_child(upgrades_container)

func _create_comparison_panel(parent: Control):
	"""Create ship comparison tools"""
	var comparison_title = Label.new()
	comparison_title.text = "Upgrade Comparison"
	comparison_title.add_theme_font_size_override("font_size", 16)
	comparison_title.add_theme_color_override("font_color", Color.YELLOW)
	parent.add_child(comparison_title)
	
	comparison_panel = Panel.new()
	comparison_panel.custom_minimum_size = Vector2(0, 100)
	parent.add_child(comparison_panel)
	
	var comparison_scroll = ScrollContainer.new()
	comparison_scroll.anchors_preset = Control.PRESET_FULL_RECT
	comparison_scroll.offset_left = 10
	comparison_scroll.offset_right = -10
	comparison_scroll.offset_top = 10
	comparison_scroll.offset_bottom = -10
	comparison_panel.add_child(comparison_scroll)
	
	var comparison_container = VBoxContainer.new()
	comparison_container.name = "ComparisonContainer"
	comparison_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comparison_scroll.add_child(comparison_container)

func _refresh_ship_data():
	"""Refresh ship data from game manager"""
	if not game_manager:
		return
	
	current_ship_stats = game_manager._get_current_ship_stats()
	available_upgrades = _get_available_upgrades()

func _get_available_upgrades() -> Dictionary:
	"""Get available upgrades from ship system"""
	if not game_manager or not game_manager.ship_system:
		return {}
	
	var upgrades = {}
	var upgrade_types = ["cargo_hold", "engine", "scanner", "ai_core"]
	
	for upgrade_type in upgrade_types:
		var current_level = game_manager.player_data.ship.upgrades[upgrade_type]
		var upgrade_info = game_manager.ship_system.get_upgrade_info(upgrade_type, current_level)
		upgrades[upgrade_type] = upgrade_info
	
	return upgrades

func _update_all_displays():
	"""Update all asset management displays"""
	_update_ship_info()
	_update_modules_display()
	_update_upgrades_display()
	_update_comparison_display()

func _update_ship_info():
	"""Update ship information display"""
	var container = get_node_or_null("VBoxContainer/HSplitContainer/VBoxContainer/Panel/ScrollContainer/ShipInfoContainer")
	if not container or not game_manager:
		return
	
	# Clear existing info
	for child in container.get_children():
		child.queue_free()
	
	var ship_data = game_manager.player_data.ship
	
	# Ship name and basic info
	var name_label = Label.new()
	name_label.text = "Ship Name: " + ship_data.name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.CYAN)
	container.add_child(name_label)
	
	# Ship stats
	var stats_to_show = [
		["Cargo Capacity", str(ship_data.cargo_capacity) + " units"],
		["Fuel Capacity", str(ship_data.fuel_capacity) + " units"],
		["Current Fuel", str(ship_data.current_fuel) + " units"],
		["Fuel Efficiency", str(int(ship_data.bonuses.fuel_efficiency * 100)) + "%"],
		["Travel Speed", str(int(ship_data.bonuses.travel_speed * 100)) + "%"]
	]
	
	for stat_pair in stats_to_show:
		var stat_container = HBoxContainer.new()
		container.add_child(stat_container)
		
		var stat_label = Label.new()
		stat_label.text = stat_pair[0] + ":"
		stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_container.add_child(stat_label)
		
		var value_label = Label.new()
		value_label.text = stat_pair[1]
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_color_override("font_color", Color.GREEN)
		stat_container.add_child(value_label)
	
	# Ship value
	var separator = HSeparator.new()
	container.add_child(separator)
	
	var value_container = HBoxContainer.new()
	container.add_child(value_container)
	
	var value_label = Label.new()
	value_label.text = "Estimated Value:"
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_container.add_child(value_label)
	
	var ship_value = _calculate_ship_value()
	var value_amount = Label.new()
	value_amount.text = "$" + _format_number(ship_value)
	value_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_amount.add_theme_color_override("font_color", Color.YELLOW)
	value_container.add_child(value_amount)

func _update_modules_display():
	"""Update ship modules display"""
	var container = get_node_or_null("VBoxContainer/HSplitContainer/VBoxContainer/Panel2/ScrollContainer/ModulesContainer")
	if not container or not game_manager:
		return
	
	# Clear existing modules
	for child in container.get_children():
		child.queue_free()
	
	var upgrades = game_manager.player_data.ship.upgrades
	
	# Display current upgrade levels
	var upgrade_info = {
		"cargo_hold": {"name": "Cargo Hold", "icon": "📦", "description": "Increases cargo capacity"},
		"engine": {"name": "Engine", "icon": "🚀", "description": "Improves fuel efficiency and speed"},
		"scanner": {"name": "Scanner", "icon": "🔍", "description": "Increases artifact detection range"},
		"ai_core": {"name": "AI Core", "icon": "🤖", "description": "Enables automation and market analysis"}
	}
	
	for upgrade_type in upgrades.keys():
		var level = upgrades[upgrade_type]
		var info = upgrade_info.get(upgrade_type, {})
		
		var module_container = HBoxContainer.new()
		container.add_child(module_container)
		
		# Module icon and name
		var module_label = Label.new()
		module_label.text = info.get("icon", "⚙") + " " + info.get("name", upgrade_type.capitalize())
		module_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		module_container.add_child(module_label)
		
		# Level display
		var level_label = Label.new()
		level_label.text = "Level " + str(level)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if level > 0:
			level_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			level_label.add_theme_color_override("font_color", Color.GRAY)
		module_container.add_child(level_label)
		
		# Description
		var desc_label = Label.new()
		desc_label.text = "  " + info.get("description", "No description")
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.modulate = Color(0.8, 0.8, 0.8)
		container.add_child(desc_label)

func _update_upgrades_display():
	"""Update available upgrades display"""
	var container = get_node_or_null("VBoxContainer/HSplitContainer/VBoxContainer2/Panel/ScrollContainer/UpgradesContainer")
	if not container or not game_manager:
		return
	
	# Clear existing upgrades
	for child in container.get_children():
		child.queue_free()
	
	# Display available upgrades
	for upgrade_type in available_upgrades.keys():
		var upgrade_info = available_upgrades[upgrade_type]
		
		if not upgrade_info.get("available", false):
			continue
		
		var upgrade_panel = Panel.new()
		upgrade_panel.custom_minimum_size = Vector2(0, 80)
		container.add_child(upgrade_panel)
		
		var upgrade_container = VBoxContainer.new()
		upgrade_container.anchors_preset = Control.PRESET_FULL_RECT
		upgrade_container.offset_left = 10
		upgrade_container.offset_right = -10
		upgrade_container.offset_top = 5
		upgrade_container.offset_bottom = -5
		upgrade_panel.add_child(upgrade_container)
		
		# Upgrade header
		var header_container = HBoxContainer.new()
		upgrade_container.add_child(header_container)
		
		var upgrade_name = Label.new()
		upgrade_name.text = upgrade_type.replace("_", " ").capitalize() + " (Level " + str(upgrade_info.get("next_level", 1)) + ")"
		upgrade_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		upgrade_name.add_theme_color_override("font_color", Color.CYAN)
		header_container.add_child(upgrade_name)
		
		var cost_label = Label.new()
		cost_label.text = "$" + _format_number(upgrade_info.get("cost", 0))
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cost_label.add_theme_color_override("font_color", Color.YELLOW)
		header_container.add_child(cost_label)
		
		# Upgrade effects
		var effects_text = ""
		var effects = upgrade_info.get("effects", {})
		for effect_name in effects.keys():
			var effect_value = effects[effect_name]
			effects_text += effect_name.replace("_", " ").capitalize() + ": +" + str(effect_value) + " "
		
		if effects_text != "":
			var effects_label = Label.new()
			effects_label.text = effects_text
			effects_label.add_theme_font_size_override("font_size", 10)
			effects_label.add_theme_color_override("font_color", Color.GREEN)
			upgrade_container.add_child(effects_label)
		
		# Purchase button
		var button_container = HBoxContainer.new()
		upgrade_container.add_child(button_container)
		
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button_container.add_child(spacer)
		
		var purchase_button = Button.new()
		purchase_button.text = "Purchase"
		purchase_button.custom_minimum_size = Vector2(80, 25)
		purchase_button.pressed.connect(_purchase_upgrade.bind(upgrade_type))
		
		# Check if player can afford
		var can_afford = game_manager.player_data.credits >= upgrade_info.get("cost", 0)
		purchase_button.disabled = not can_afford
		if not can_afford:
			purchase_button.text = "Can't Afford"
		
		button_container.add_child(purchase_button)

func _update_comparison_display():
	"""Update upgrade comparison display"""
	var container = get_node_or_null("VBoxContainer/HSplitContainer/VBoxContainer2/Panel2/ScrollContainer/ComparisonContainer")
	if not container:
		return
	
	# Clear existing comparison
	for child in container.get_children():
		child.queue_free()
	
	# Show upgrade impact summary
	var summary_label = Label.new()
	summary_label.text = "Upgrade Impact Summary"
	summary_label.add_theme_color_override("font_color", Color.YELLOW)
	container.add_child(summary_label)
	
	var impact_text = "Next upgrade will provide:\n"
	var has_upgrades = false
	
	for upgrade_type in available_upgrades.keys():
		var upgrade_info = available_upgrades[upgrade_type]
		if upgrade_info.get("available", false):
			has_upgrades = true
			var effects = upgrade_info.get("effects", {})
			impact_text += "• " + upgrade_type.replace("_", " ").capitalize() + ": "
			for effect_name in effects.keys():
				impact_text += effect_name.replace("_", " ") + " +" + str(effects[effect_name]) + " "
			impact_text += "\n"
	
	if not has_upgrades:
		impact_text = "No upgrades available at current level."
	
	var impact_label = Label.new()
	impact_label.text = impact_text
	impact_label.add_theme_font_size_override("font_size", 10)
	impact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(impact_label)

func _purchase_upgrade(upgrade_type: String):
	"""Purchase a ship upgrade"""
	if not game_manager:
		return
	
	var result = game_manager.purchase_ship_upgrade(upgrade_type)
	
	# Show result
	var hud = get_node("../../SimpleHUD")
	if hud and hud.has_method("add_alert"):
		if result.success:
			hud.add_alert("success", "Purchased " + upgrade_type.replace("_", " ") + " upgrade!", 3.0)
		else:
			hud.add_alert("error", "Upgrade failed: " + result.error, 4.0)
	
	# Refresh displays
	_refresh_ship_data()
	_update_all_displays()

func _calculate_ship_value() -> int:
	"""Calculate current ship value"""
	if not game_manager:
		return 10000
	
	var base_value = 10000
	var upgrade_value = 0
	
	var upgrades = game_manager.player_data.ship.upgrades
	upgrade_value += upgrades.cargo_hold * 2000
	upgrade_value += upgrades.engine * 3000
	upgrade_value += upgrades.scanner * 1500
	upgrade_value += upgrades.ai_core * 5000
	
	return base_value + upgrade_value

func _format_number(number: int) -> String:
	"""Format large numbers with commas"""
	var str_number = str(number)
	var formatted = ""
	var count = 0
	
	for i in range(str_number.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = str_number[i] + formatted
		count += 1
	
	return formatted

# Signal handlers
func _on_ship_upgraded(upgrade_type: String, new_level: int, effects: Dictionary):
	"""Handle ship upgrade completion"""
	_refresh_ship_data()
	_update_all_displays()

func _on_upgrade_purchased(upgrade_type: String, cost: int):
	"""Handle upgrade purchase"""
	# This is handled by the GameManager
	pass

func _on_ship_stats_updated(stats: Dictionary):
	"""Handle ship stats update"""
	current_ship_stats = stats
	_update_ship_info()

# Public API
func update_cargo(cargo_dict: Dictionary):
	"""Update cargo display when cargo changes"""
	# Could show cargo breakdown here if needed
	pass

func update_ship_stats(stats: Dictionary):
	"""Update ship stats display"""
	current_ship_stats = stats
	_update_ship_info()