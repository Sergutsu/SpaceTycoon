extends Control
class_name MarketScreen

# Market Screen - Comprehensive trading interface
# Based on views.md: "Live order book, historical charts, trade filters, profit calculations"

# References
var game_manager: GameManager

# UI References
@onready var market_container: VBoxContainer = get_node_or_null("MarketContainer")
@onready var order_book_panel: Panel = get_node_or_null("OrderBookPanel")
@onready var price_chart_panel: Panel = get_node_or_null("PriceChartPanel")
@onready var trade_controls_panel: Panel = get_node_or_null("TradeControlsPanel")

# Market data
var current_system: String = ""
var selected_good: String = "food"
var market_data: Dictionary = {}
var price_history: Array = []

# Trading state
var trade_quantity: int = 1
var trade_mode: String = "buy"  # "buy" or "sell"

func _ready():
	print("MarketScreen: Initializing...")
	_create_ui_elements()

func initialize(gm: GameManager):
	"""Initialize market screen with game manager reference"""
	game_manager = gm
	current_system = game_manager.player_data.current_system
	
	# Connect to market signals
	if game_manager.economy_system:
		game_manager.economy_system.market_prices_updated.connect(_on_market_prices_updated)
		game_manager.economy_system.trade_executed.connect(_on_trade_executed)
	
	# Initial data load
	_refresh_market_data()
	_update_all_displays()
	
	print("MarketScreen: Initialized with GameManager")

func _create_ui_elements():
	"""Create the market screen UI dynamically"""
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
	title_label.text = "Galactic Market Exchange"
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color.CYAN)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title_label)
	
	# Market selector
	_create_market_selector(main_container)
	
	# Main trading area
	var trading_area = HSplitContainer.new()
	trading_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(trading_area)
	
	# Left side - Order book and controls
	var left_panel = VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(400, 0)
	trading_area.add_child(left_panel)
	
	_create_order_book(left_panel)
	_create_trade_controls(left_panel)
	
	# Right side - Price chart and analysis
	var right_panel = VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trading_area.add_child(right_panel)
	
	_create_price_chart(right_panel)
	_create_market_analysis(right_panel)

func _create_market_selector(parent: Control):
	"""Create market/system selector"""
	var selector_container = HBoxContainer.new()
	parent.add_child(selector_container)
	
	# System selector
	var system_label = Label.new()
	system_label.text = "System: "
	selector_container.add_child(system_label)
	
	var system_option = OptionButton.new()
	system_option.name = "SystemSelector"
	system_option.custom_minimum_size = Vector2(150, 30)
	selector_container.add_child(system_option)
	
	# Good selector
	var good_label = Label.new()
	good_label.text = "  Commodity: "
	selector_container.add_child(good_label)
	
	var good_option = OptionButton.new()
	good_option.name = "GoodSelector"
	good_option.custom_minimum_size = Vector2(120, 30)
	good_option.add_item("Food")
	good_option.add_item("Minerals")
	good_option.add_item("Technology")
	good_option.add_item("Passengers")
	good_option.item_selected.connect(_on_good_selected)
	selector_container.add_child(good_option)
	
	# Refresh button
	var refresh_button = Button.new()
	refresh_button.text = "Refresh"
	refresh_button.custom_minimum_size = Vector2(80, 30)
	refresh_button.pressed.connect(_refresh_market_data)
	selector_container.add_child(refresh_button)

func _create_order_book(parent: Control):
	"""Create live order book display"""
	var order_book_title = Label.new()
	order_book_title.text = "Live Order Book"
	order_book_title.add_theme_font_size_override("font_size", 16)
	order_book_title.add_theme_color_override("font_color", Color.GREEN)
	parent.add_child(order_book_title)
	
	order_book_panel = Panel.new()
	order_book_panel.custom_minimum_size = Vector2(0, 200)
	parent.add_child(order_book_panel)
	
	var order_book_scroll = ScrollContainer.new()
	order_book_scroll.anchors_preset = Control.PRESET_FULL_RECT
	order_book_scroll.offset_left = 5
	order_book_scroll.offset_right = -5
	order_book_scroll.offset_top = 5
	order_book_scroll.offset_bottom = -5
	order_book_panel.add_child(order_book_scroll)
	
	var order_book_container = VBoxContainer.new()
	order_book_container.name = "OrderBookContainer"
	order_book_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	order_book_scroll.add_child(order_book_container)

func _create_trade_controls(parent: Control):
	"""Create trading controls"""
	var controls_title = Label.new()
	controls_title.text = "Trade Controls"
	controls_title.add_theme_font_size_override("font_size", 16)
	controls_title.add_theme_color_override("font_color", Color.ORANGE)
	parent.add_child(controls_title)
	
	trade_controls_panel = Panel.new()
	trade_controls_panel.custom_minimum_size = Vector2(0, 150)
	parent.add_child(trade_controls_panel)
	
	var controls_container = VBoxContainer.new()
	controls_container.anchors_preset = Control.PRESET_FULL_RECT
	controls_container.offset_left = 10
	controls_container.offset_right = -10
	controls_container.offset_top = 10
	controls_container.offset_bottom = -10
	trade_controls_panel.add_child(controls_container)
	
	# Trade mode selector
	var mode_container = HBoxContainer.new()
	controls_container.add_child(mode_container)
	
	var buy_button = Button.new()
	buy_button.text = "Buy"
	buy_button.toggle_mode = true
	buy_button.button_pressed = true
	buy_button.custom_minimum_size = Vector2(60, 30)
	buy_button.pressed.connect(func(): _set_trade_mode("buy"))
	mode_container.add_child(buy_button)
	
	var sell_button = Button.new()
	sell_button.text = "Sell"
	sell_button.toggle_mode = true
	sell_button.custom_minimum_size = Vector2(60, 30)
	sell_button.pressed.connect(func(): _set_trade_mode("sell"))
	mode_container.add_child(sell_button)
	
	# Quantity controls
	var quantity_container = HBoxContainer.new()
	controls_container.add_child(quantity_container)
	
	var quantity_label = Label.new()
	quantity_label.text = "Quantity: "
	quantity_container.add_child(quantity_label)
	
	var quantity_spinbox = SpinBox.new()
	quantity_spinbox.name = "QuantitySpinBox"
	quantity_spinbox.min_value = 1
	quantity_spinbox.max_value = 1000
	quantity_spinbox.value = 1
	quantity_spinbox.value_changed.connect(_on_quantity_changed)
	quantity_container.add_child(quantity_spinbox)
	
	# Price and total display
	var price_label = Label.new()
	price_label.name = "PriceLabel"
	price_label.text = "Price: $0"
	controls_container.add_child(price_label)
	
	var total_label = Label.new()
	total_label.name = "TotalLabel"
	total_label.text = "Total: $0"
	controls_container.add_child(total_label)
	
	# Execute trade button
	var execute_button = Button.new()
	execute_button.name = "ExecuteButton"
	execute_button.text = "Execute Trade"
	execute_button.custom_minimum_size = Vector2(0, 40)
	execute_button.pressed.connect(_execute_trade)
	controls_container.add_child(execute_button)

func _create_price_chart(parent: Control):
	"""Create price chart display"""
	var chart_title = Label.new()
	chart_title.text = "Price History"
	chart_title.add_theme_font_size_override("font_size", 16)
	chart_title.add_theme_color_override("font_color", Color.PURPLE)
	parent.add_child(chart_title)
	
	price_chart_panel = Panel.new()
	price_chart_panel.custom_minimum_size = Vector2(0, 200)
	price_chart_panel.name = "PriceChartPanel"
	parent.add_child(price_chart_panel)
	
	# Chart will be drawn in _draw method

func _create_market_analysis(parent: Control):
	"""Create market analysis display"""
	var analysis_title = Label.new()
	analysis_title.text = "Market Analysis"
	analysis_title.add_theme_font_size_override("font_size", 16)
	analysis_title.add_theme_color_override("font_color", Color.YELLOW)
	parent.add_child(analysis_title)
	
	var analysis_panel = Panel.new()
	analysis_panel.custom_minimum_size = Vector2(0, 150)
	parent.add_child(analysis_panel)
	
	var analysis_scroll = ScrollContainer.new()
	analysis_scroll.anchors_preset = Control.PRESET_FULL_RECT
	analysis_scroll.offset_left = 5
	analysis_scroll.offset_right = -5
	analysis_scroll.offset_top = 5
	analysis_scroll.offset_bottom = -5
	analysis_panel.add_child(analysis_scroll)
	
	var analysis_container = VBoxContainer.new()
	analysis_container.name = "AnalysisContainer"
	analysis_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	analysis_scroll.add_child(analysis_container)

func _refresh_market_data():
	"""Refresh market data from game manager"""
	if not game_manager:
		return
	
	current_system = game_manager.player_data.current_system
	market_data = game_manager.get_market_analysis(current_system)
	price_history = game_manager.get_market_history(selected_good, current_system, 50)
	
	_update_all_displays()

func _update_all_displays():
	"""Update all market displays"""
	_update_order_book()
	_update_trade_controls()
	_update_price_chart()
	_update_market_analysis()

func _update_order_book():
	"""Update the order book display"""
	var container = get_node_or_null("MarketContainer/HSplitContainer/VBoxContainer/OrderBookPanel/ScrollContainer/OrderBookContainer")
	if not container:
		return
	
	# Clear existing orders
	for child in container.get_children():
		child.queue_free()
	
	# Add header
	var header = Label.new()
	header.text = "Current Market Orders - " + selected_good.capitalize()
	header.add_theme_color_override("font_color", Color.CYAN)
	container.add_child(header)
	
	# Add current price
	if game_manager:
		var current_price = game_manager.economy_system.calculate_dynamic_price(current_system, selected_good)
		var price_label = Label.new()
		price_label.text = "Current Price: $" + str(current_price)
		price_label.add_theme_color_override("font_color", Color.GREEN)
		container.add_child(price_label)
		
		# Add supply/demand info
		var supply_demand = game_manager.get_supply_demand_indicators(current_system)
		var sd_info = supply_demand.get(selected_good, {})
		
		var supply_label = Label.new()
		supply_label.text = "Supply: " + str(sd_info.get("supply_level", "Unknown"))
		container.add_child(supply_label)
		
		var demand_label = Label.new()
		demand_label.text = "Demand: " + str(sd_info.get("demand_level", "Unknown"))
		container.add_child(demand_label)

func _update_trade_controls():
	"""Update trade control displays"""
	if not game_manager:
		return
	
	var price_label = get_node_or_null("MarketContainer/HSplitContainer/VBoxContainer/TradeControlsPanel/VBoxContainer/PriceLabel")
	var total_label = get_node_or_null("MarketContainer/HSplitContainer/VBoxContainer/TradeControlsPanel/VBoxContainer/TotalLabel")
	
	if price_label and total_label:
		var current_price = game_manager.economy_system.calculate_dynamic_price(current_system, selected_good)
		var total_cost = current_price * trade_quantity
		
		price_label.text = "Price: $" + str(current_price)
		total_label.text = "Total: $" + str(total_cost)
		
		# Update button text and availability
		var execute_button = get_node_or_null("MarketContainer/HSplitContainer/VBoxContainer/TradeControlsPanel/VBoxContainer/ExecuteButton")
		if execute_button:
			execute_button.text = trade_mode.capitalize() + " " + str(trade_quantity) + " " + selected_good.capitalize()
			
			# Check if trade is possible
			if trade_mode == "buy":
				execute_button.disabled = game_manager.player_data.credits < total_cost
			else:
				var available = game_manager.player_data.inventory.get(selected_good, 0)
				execute_button.disabled = available < trade_quantity

func _update_price_chart():
	"""Update price chart"""
	if not price_chart_panel:
		return
	
	# Clear existing chart
	for child in price_chart_panel.get_children():
		if child.name == "ChartCanvas":
			child.queue_free()
	
	# Create chart canvas
	var chart_canvas = Control.new()
	chart_canvas.name = "ChartCanvas"
	chart_canvas.anchors_preset = Control.PRESET_FULL_RECT
	chart_canvas.offset_left = 10
	chart_canvas.offset_right = -10
	chart_canvas.offset_top = 10
	chart_canvas.offset_bottom = -10
	chart_canvas.draw.connect(_draw_price_chart.bind(chart_canvas))
	price_chart_panel.add_child(chart_canvas)
	
	chart_canvas.queue_redraw()

func _draw_price_chart(canvas: Control):
	"""Draw the price chart"""
	if not game_manager or price_history.is_empty():
		# Draw placeholder
		canvas.draw_string(get_theme_default_font(), Vector2(10, 30), "No price data available", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GRAY)
		return
	
	var chart_rect = canvas.get_rect()
	var margin = 20
	var draw_rect = Rect2(margin, margin, chart_rect.size.x - margin * 2, chart_rect.size.y - margin * 2)
	
	if draw_rect.size.x <= 0 or draw_rect.size.y <= 0:
		return
	
	# Get price data
	var prices = []
	for entry in price_history:
		prices.append(entry.get("price", 0))
	
	if prices.is_empty():
		return
	
	# Find min/max prices for scaling
	var min_price = prices[0]
	var max_price = prices[0]
	for price in prices:
		min_price = min(min_price, price)
		max_price = max(max_price, price)
	
	if max_price == min_price:
		max_price = min_price + 1  # Avoid division by zero
	
	# Draw chart background
	canvas.draw_rect(draw_rect, Color(0.2, 0.2, 0.3, 0.5))
	
	# Draw price line
	var points = PackedVector2Array()
	for i in range(prices.size()):
		var x = draw_rect.position.x + (float(i) / float(prices.size() - 1)) * draw_rect.size.x
		var y = draw_rect.position.y + draw_rect.size.y - ((prices[i] - min_price) / (max_price - min_price)) * draw_rect.size.y
		points.append(Vector2(x, y))
	
	# Draw the price line
	for i in range(points.size() - 1):
		canvas.draw_line(points[i], points[i + 1], Color.GREEN, 2.0)
	
	# Draw price points
	for point in points:
		canvas.draw_circle(point, 3, Color.YELLOW)
	
	# Draw labels
	canvas.draw_string(get_theme_default_font(), Vector2(draw_rect.position.x, draw_rect.position.y - 5), "Max: $" + str(max_price), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	canvas.draw_string(get_theme_default_font(), Vector2(draw_rect.position.x, draw_rect.position.y + draw_rect.size.y + 15), "Min: $" + str(min_price), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
	
	# Draw current price indicator
	if not prices.is_empty():
		var current_price = prices[-1]
		var current_y = draw_rect.position.y + draw_rect.size.y - ((current_price - min_price) / (max_price - min_price)) * draw_rect.size.y
		canvas.draw_line(Vector2(draw_rect.position.x, current_y), Vector2(draw_rect.position.x + draw_rect.size.x, current_y), Color.RED, 1.0, true)
		canvas.draw_string(get_theme_default_font(), Vector2(draw_rect.position.x + draw_rect.size.x - 80, current_y - 5), "Current: $" + str(current_price), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.RED)

func _update_market_analysis():
	"""Update market analysis display"""
	var container = get_node_or_null("MarketContainer/HSplitContainer/VBoxContainer2/Panel/ScrollContainer/AnalysisContainer")
	if not container or not game_manager:
		return
	
	# Clear existing analysis
	for child in container.get_children():
		child.queue_free()
	
	# Add market prediction
	var prediction = game_manager.get_market_prediction(selected_good)
	
	var prediction_label = Label.new()
	prediction_label.text = "Price Prediction: " + prediction.get("trend", "Unknown")
	prediction_label.add_theme_color_override("font_color", Color.YELLOW)
	container.add_child(prediction_label)
	
	var confidence_label = Label.new()
	confidence_label.text = "Confidence: " + str(prediction.get("confidence", 0)) + "%"
	container.add_child(confidence_label)
	
	# Add profit calculation
	var profit_info = _calculate_profit_potential()
	var profit_label = Label.new()
	profit_label.text = "Profit Potential: " + profit_info
	profit_label.add_theme_color_override("font_color", Color.GREEN)
	container.add_child(profit_label)

func _calculate_profit_potential() -> String:
	"""Calculate potential profit from trading"""
	if not game_manager:
		return "Unknown"
	
	var current_price = game_manager.economy_system.calculate_dynamic_price(current_system, selected_good)
	var destinations = game_manager.get_available_destinations()
	
	var best_profit = 0
	var best_destination = ""
	
	for dest in destinations:
		var dest_price = game_manager.economy_system.calculate_dynamic_price(dest["id"], selected_good)
		var profit = dest_price - current_price - dest["fuel_cost"] * 2  # Rough fuel cost
		
		if profit > best_profit:
			best_profit = profit
			best_destination = dest["id"]
	
	if best_profit > 0:
		return "$" + str(best_profit) + " per unit to " + best_destination.capitalize()
	else:
		return "No profitable routes found"

# Event handlers
func _on_good_selected(index: int):
	"""Handle good selection change"""
	var goods = ["food", "minerals", "tech", "passengers"]
	selected_good = goods[index]
	_refresh_market_data()

func _on_quantity_changed(value: float):
	"""Handle quantity change"""
	trade_quantity = int(value)
	_update_trade_controls()

func _set_trade_mode(mode: String):
	"""Set trading mode"""
	trade_mode = mode
	_update_trade_controls()

func _execute_trade():
	"""Execute the current trade"""
	if not game_manager:
		return
	
	var result: Dictionary
	if trade_mode == "buy":
		result = game_manager.buy_good(selected_good, trade_quantity)
	else:
		result = game_manager.sell_good(selected_good, trade_quantity)
	
	# Show result
	var hud = get_node("../../SimpleHUD")
	if hud and hud.has_method("add_alert"):
		if result.success:
			var action = "Bought" if trade_mode == "buy" else "Sold"
			var amount = result.get("cost", result.get("revenue", 0))
			hud.add_alert("trade", action + " " + str(trade_quantity) + " " + selected_good + " for $" + str(amount), 3.0)
		else:
			hud.add_alert("error", "Trade failed: " + result.error, 4.0)
	
	# Refresh displays
	_refresh_market_data()

# Signal handlers
func _on_market_prices_updated(system_id: String, prices: Dictionary):
	"""Handle market price updates"""
	if system_id == current_system:
		_update_all_displays()

func _on_trade_executed(system_id: String, good_type: String, quantity: int, is_buying: bool, profit: int):
	"""Handle trade execution"""
	if system_id == current_system and good_type == selected_good:
		_refresh_market_data()

# Public API
func update_location(system_id: String):
	"""Update market screen when location changes"""
	current_system = system_id
	_refresh_market_data()

func set_selected_good(good_type: String):
	"""Set the selected commodity"""
	selected_good = good_type
	_refresh_market_data()
