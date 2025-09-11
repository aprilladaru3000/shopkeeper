extends CharacterBody2D
class_name Customer

signal order_completed(customer)
signal customer_left(customer)

@export var customer_textures: Array[Texture2D] = []
@export var patience_time: float = 30.0

var current_order: Dictionary = {}
var is_waiting: bool = false
var patience_timer: Timer

@onready var sprite: Sprite2D = $Sprite
@onready var order_bubble: Control = $OrderBubble
@onready var order_list: VBoxContainer = $OrderBubble/OrderList

func _ready():
	setup_patience_timer()
	setup_appearance()

func setup_patience_timer():
	patience_timer = Timer.new()
	patience_timer.wait_time = patience_time
	patience_timer.one_shot = true
	patience_timer.timeout.connect(_on_patience_timeout)
	add_child(patience_timer)

func setup_appearance():
	if customer_textures.size() > 0:
		sprite.texture = customer_textures[randi() % customer_textures.size()]

func set_order(order: Dictionary):
	current_order = order
	display_order()
	is_waiting = true
	patience_timer.start()

func display_order():
	# Clear previous order display
	for child in order_list.get_children():
		child.queue_free()
	
	# Create order display
	for item_name in current_order:
		var order_item = Label.new()
		order_item.text = item_name + " x" + str(current_order[item_name])
		order_list.add_child(order_item)
	
	order_bubble.visible = true

func check_order_completion(drop_zones: Array[DropZone]) -> bool:
	var order_fulfilled = true
	
	for item_name in current_order:
		var required_quantity = current_order[item_name]
		var found_quantity = 0
		
		for zone in drop_zones:
			if zone.has_item(item_name, 1):
				var item = zone.find_existing_item(item_name)
				found_quantity += item.quantity
		
		if found_quantity < required_quantity:
			order_fulfilled = false
			break
	
	if order_fulfilled:
		complete_order()
	
	return order_fulfilled

func complete_order():
	is_waiting = false
	patience_timer.stop()
	order_bubble.visible = false
	order_completed.emit(self)
	
	# Calculate payment
	var payment = calculate_payment()
	GameManager.add_money(payment)
	GameManager.serve_customer()
	
	# Leave the shop
	leave_shop()

func calculate_payment() -> int:
	var total = 0
	for item_name in current_order:
		var quantity = current_order[item_name]
		total += quantity * 5  # Base price per item
	return total

func leave_shop():
	# Animate leaving
	var tween = create_tween()
	tween.tween_position(self, position + Vector2(200, 0), 1.0)
	tween.tween_callback(func(): queue_free())
	customer_left.emit(self)

func _on_patience_timeout():
	# Customer leaves without buying
	print("Customer left due to impatience!")
	leave_shop()
