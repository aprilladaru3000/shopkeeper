extends Node2D
class_name Shop

signal customer_order_completed(customer, payment)
signal all_customers_served

@export var customer_scene: PackedScene
@export var max_customers_per_day: int = 8
@export var customer_spawn_interval: float = 15.0

var item_storage: Node2D
var serving_area: Node2D
var customer_queue: Node2D
var drop_zones: Array[DropZone] = []
var current_customers: Array[Customer] = []
var customer_spawn_timer: Timer
var customers_spawned_today: int = 0

# Item data for generating orders
var available_items: Array[Dictionary] = [
	{"name": "Milk", "shape": "rectangle", "price": 5},
	{"name": "Chocolate", "shape": "square", "price": 3},
	{"name": "Candy", "shape": "circle", "price": 2},
	{"name": "Chips", "shape": "rectangle", "price": 4},
	{"name": "Soda", "shape": "circle", "price": 6}
]

func _ready():
	setup_references()
	setup_customer_spawner()
	connect_signals()

func setup_references():
	item_storage = $ItemStorage
	serving_area = $ServingArea
	customer_queue = $CustomerQueue
	
	# Get all drop zones
	for child in serving_area.get_children():
		if child is DropZone:
			drop_zones.append(child)

func setup_customer_spawner():
	customer_spawn_timer = Timer.new()
	customer_spawn_timer.wait_time = customer_spawn_interval
	customer_spawn_timer.timeout.connect(_on_spawn_customer)
	add_child(customer_spawn_timer)

func connect_signals():
	# Connect to GameManager signals
	if GameManager:
		GameManager.day_started.connect(_on_day_started)
		GameManager.day_ended.connect(_on_day_ended)

func _on_day_started():
	customers_spawned_today = 0
	start_customer_spawning()

func _on_day_ended():
	stop_customer_spawning()
	# Clear any remaining customers
	for customer in current_customers:
		if is_instance_valid(customer):
			customer.queue_free()
	current_customers.clear()

func start_customer_spawning():
	customer_spawn_timer.start()
	# Spawn first customer immediately
	spawn_customer()

func stop_customer_spawning():
	customer_spawn_timer.stop()

func _on_spawn_customer():
	if customers_spawned_today < max_customers_per_day:
		spawn_customer()

func spawn_customer():
	if not customer_scene:
		print("No customer scene assigned!")
		return
	
	var customer = customer_scene.instantiate() as Customer
	customer_queue.add_child(customer)
	
	# Position customer in queue
	var queue_position = Vector2(100, 50 + current_customers.size() * 80)
	customer.position = queue_position
	
	# Generate order based on current day difficulty
	var order = generate_customer_order()
	customer.set_order(order)
	
	# Connect customer signals
	customer.order_completed.connect(_on_customer_order_completed)
	customer.customer_left.connect(_on_customer_left)
	
	current_customers.append(customer)
	customers_spawned_today += 1
	
	print("Customer spawned with order: ", order)

func generate_customer_order() -> Dictionary:
	var order = {}
	var max_items = GameManager.get_max_order_items()
	var num_different_items = randi_range(1, min(6, available_items.size()))
	
	# Select random items
	var selected_items = available_items.duplicate()
	selected_items.shuffle()
	
	var total_items = 0
	for i in range(num_different_items):
		if total_items >= max_items:
			break
		
		var item = selected_items[i]
		var remaining_capacity = max_items - total_items
		var max_quantity = min(remaining_capacity, 7)  # Max 7 of any single item
		var quantity = randi_range(1, max_quantity)
		
		order[item.name] = quantity
		total_items += quantity
	
	return order

func _on_customer_order_completed(customer: Customer):
	# Check if order is actually fulfilled
	if check_customer_order(customer):
		# Calculate payment
		var payment = calculate_order_payment(customer.current_order)
		customer_order_completed.emit(customer, payment)
		
		# Clear the serving area
		clear_serving_area()
		
		print("Order completed! Payment: $", payment)
	else:
		print("Order not properly fulfilled!")

func check_customer_order(customer: Customer) -> bool:
	var order = customer.current_order
	
	for item_name in order:
		var required_quantity = order[item_name]
		var found_quantity = 0
		
		# Check all drop zones for this item
		for zone in drop_zones:
			if zone.has_item(item_name, 1):
				var item = zone.find_existing_item(item_name)
				if item:
					found_quantity += item.quantity
		
		if found_quantity < required_quantity:
			return false
	
	return true

func calculate_order_payment(order: Dictionary) -> int:
	var total = 0
	for item_name in order:
		var quantity = order[item_name]
		var item_data = find_item_data(item_name)
		if item_data:
			total += quantity * item_data.price
	return total

func find_item_data(item_name: String) -> Dictionary:
	for item in available_items:
		if item.name == item_name:
			return item
	return {}

func clear_serving_area():
	for zone in drop_zones:
		zone.clear_all_items()

func _on_customer_left(customer: Customer):
	if customer in current_customers:
		current_customers.erase(customer)
	
	# Check if all customers are served
	if current_customers.is_empty() and customers_spawned_today >= max_customers_per_day:
		all_customers_served.emit()

func add_new_item_type(item_data: Dictionary):
	available_items.append(item_data)
	print("New item added to shop: ", item_data.name)

func get_daily_stats() -> Dictionary:
	return {
		"customers_spawned": customers_spawned_today,
		"customers_remaining": current_customers.size()
	}
