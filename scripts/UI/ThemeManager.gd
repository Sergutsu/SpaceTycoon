extends Node
class_name ThemeManager

# Theme Manager - Centralized theme and visual styling
# Provides consistent colors, fonts, and styles across all UI panels

# Color palette
var colors = {
	"primary": Color(0.2, 0.6, 1.0),      # Blue
	"secondary": Color(0.8, 0.4, 0.8),    # Purple
	"accent": Color(0.0, 0.8, 0.9),       # Cyan
	"success": Color(0.2, 0.8, 0.2),      # Green
	"warning": Color(1.0, 0.6, 0.0),      # Orange
	"error": Color(0.8, 0.2, 0.2),        # Red
	"info": Color(0.4, 0.7, 1.0),         # Light Blue
	"background": Color(0.1, 0.1, 0.2),   # Dark Blue
	"surface": Color(0.15, 0.15, 0.25),   # Slightly lighter
	"text_primary": Color.WHITE,
	"text_secondary": Color(0.8, 0.8, 0.8),
	"text_disabled": Color(0.5, 0.5, 0.5)
}

# Font sizes
var font_sizes = {
	"title": 20,
	"heading": 16,
	"body": 12,
	"small": 10,
	"tiny": 8
}

# Common styles
var panel_style: StyleBoxFlat
var button_style: StyleBoxFlat
var button_hover_style: StyleBoxFlat
var input_style: StyleBoxFlat

func _ready():
	_create_common_styles()

func _create_common_styles():
	"""Create common UI styles"""
	# Panel style
	panel_style = StyleBoxFlat.new()
	panel_style.bg_color = colors.surface
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = colors.primary
	
	# Button style
	button_style = StyleBoxFlat.new()
	button_style.bg_color = colors.primary
	button_style.corner_radius_top_left = 5
	button_style.corner_radius_top_right = 5
	button_style.corner_radius_bottom_left = 5
	button_style.corner_radius_bottom_right = 5
	
	# Button hover style
	button_hover_style = StyleBoxFlat.new()
	button_hover_style.bg_color = colors.accent
	button_hover_style.corner_radius_top_left = 5
	button_hover_style.corner_radius_top_right = 5
	button_hover_style.corner_radius_bottom_left = 5
	button_hover_style.corner_radius_bottom_right = 5
	
	# Input style
	input_style = StyleBoxFlat.new()
	input_style.bg_color = colors.background
	input_style.corner_radius_top_left = 3
	input_style.corner_radius_top_right = 3
	input_style.corner_radius_bottom_left = 3
	input_style.corner_radius_bottom_right = 3
	input_style.border_width_left = 1
	input_style.border_width_right = 1
	input_style.border_width_top = 1
	input_style.border_width_bottom = 1
	input_style.border_color = colors.primary

func apply_panel_theme(panel: Panel):
	"""Apply theme to a panel"""
	panel.add_theme_stylebox_override("panel", panel_style)

func apply_button_theme(button: Button):
	"""Apply theme to a button"""
	button.add_theme_stylebox_override("normal", button_style)
	button.add_theme_stylebox_override("hover", button_hover_style)
	button.add_theme_color_override("font_color", colors.text_primary)

func apply_label_theme(label: Label, style: String = "body"):
	"""Apply theme to a label"""
	label.add_theme_font_size_override("font_size", font_sizes.get(style, font_sizes.body))
	label.add_theme_color_override("font_color", colors.text_primary)

func apply_title_theme(label: Label):
	"""Apply title theme to a label"""
	apply_label_theme(label, "title")
	label.add_theme_color_override("font_color", colors.accent)

func apply_heading_theme(label: Label):
	"""Apply heading theme to a label"""
	apply_label_theme(label, "heading")
	label.add_theme_color_override("font_color", colors.primary)

func get_color(color_name: String) -> Color:
	"""Get a color from the theme"""
	return colors.get(color_name, Color.WHITE)

func get_font_size(size_name: String) -> int:
	"""Get a font size from the theme"""
	return font_sizes.get(size_name, font_sizes.body)

# Utility methods for creating themed UI elements
func create_themed_panel() -> Panel:
	"""Create a panel with theme applied"""
	var panel = Panel.new()
	apply_panel_theme(panel)
	return panel

func create_themed_button(text: String) -> Button:
	"""Create a button with theme applied"""
	var button = Button.new()
	button.text = text
	apply_button_theme(button)
	return button

func create_themed_label(text: String, style: String = "body") -> Label:
	"""Create a label with theme applied"""
	var label = Label.new()
	label.text = text
	apply_label_theme(label, style)
	return label

func create_title_label(text: String) -> Label:
	"""Create a title label with theme applied"""
	var label = Label.new()
	label.text = text
	apply_title_theme(label)
	return label

func create_heading_label(text: String) -> Label:
	"""Create a heading label with theme applied"""
	var label = Label.new()
	label.text = text
	apply_heading_theme(label)
	return label