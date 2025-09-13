extends Control
class_name UpgradeMenu

signal upgrade_purchased(upgrade_type, cost)
signal menu_closed

@onready var money_label: Label = $Background/VBoxContainer/MoneyLabel
@onready var day_label: Label = $Background/VBoxContainer/DayLabel
@onready var earnings_label: Label = $Background/VBoxContainer/EarningsLabel
@onready var upgrade_list: VBoxContainer = $Background/VBoxContainer/ScrollContainer/UpgradeList
@onready var continue_button: Button = $Background/VBoxContainer/ContinueButton

const AVAILABLE_UPGRADES: Array[Dictionary] = [
	{"name": "Extra Drop Zone", "description": "Add one more drop zone for serving customers", "cost": 50, "type": "drop_zone", "max_purchases": 3},
	{"name": "Faster Service", "description": "Customers wait 10 seconds longer before leaving", "cost": 30, "type": "patience", "max_purchases": 5},
	{"name": "New Item: Banana", "description": "Unlock banana for your shop (Circle shape)", "cost": 25, "type": "new_item", "item_data": {"name": "Banana", "shape": "circle", "price": 4}, "max_purchases": 1},
	{"name": "New Item: Apple", "description": "Unlock apple for your shop (Circle shape)", "cost": 25, "type": "new_item", "item_data": {"name": "Apple", "shape": "circle", "price": 4}, "max_purchases": 1},
	{"name": "New Item: Bread", "description": "Unlock bread for your shop (Rectangle shape)", "cost": 30, "type": "new_item", "item_data": {"name": "Bread", "shape": "rectangle", "price": 6}, "max_purchases": 1},
	{"name": "New Item: Cookies", "description": "Unlock cookies for your shop (Square shape)", "cost": 20, "type": "new_item", "item_data": {"name": "Cookies", "shape": "square", "price": 3}, "max_purchases": 1},
	{"name": "More Customers", "description": "2 more customers visit your shop each day", "cost": 40, "type": "more_customers", "max_purchases": 3},
	{"name": "Price Boost", "description": "All items sell for 1 more coin", "cost": 60, "type": "price_boost", "max_purchases": 2}
]

var available_upgrades: Array[Dictionary] = [] # For tracking purchases

func _ready():
	setup_upgrades()
	continue_button.pressed.connect(_on_continue_pressed)
	visible = false

func setup_upgrades() -> void:
	# Deep copy to allow tracking purchases
	available_upgrades = []
	for upgrade in AVAILABLE_UPGRADES:
		available_upgrades.append(upgrade.duplicate(true))

func show_menu(day: int, daily_earnings: int, total_money: int) -> void:
	day_label.text = "Day " + str(day) + " Complete!"
	earnings_label.text = "Today's Earnings: $" + str(daily_earnings)
	money_label.text = "Total Money: $" + str(total_money)
	
	create_upgrade_buttons()
	visible = true

func create_upgrade_buttons() -> void:
	# Clear existing buttons
	for child in upgrade_list.get_children():
		child.queue_free()
	
	# Create upgrade buttons
	for upgrade in available_upgrades:
		if upgrade.get("purchased_count", 0) < upgrade.max_purchases:
			create_upgrade_button(upgrade)

func create_upgrade_button(upgrade: Dictionary) -> void:
	var button_container = HBoxContainer.new()
	upgrade_list.add_child(button_container)
	
	# Upgrade info
	var info_container = VBoxContainer.new()
	button_container.add_child(info_container)
	
	var name_label = Label.new()
	name_label.text = upgrade.name
	name_label.add_theme_font_size_override("font_size", 16)
	info_container.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = upgrade.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color.GRAY
	info_container.add_child(desc_label)
	
	# Purchase button
	var purchase_button = Button.new()
	purchase_button.text = "Buy - $" + str(upgrade.cost)
	purchase_button.custom_minimum_size = Vector2(100, 40)
	
	# Check if player can afford
	if GameManager.money < upgrade.cost:
		purchase_button.disabled = true
		purchase_button.text = "Can't Afford"
	
	purchase_button.pressed.connect(_on_upgrade_purchased.bind(upgrade))
	button_container.add_child(purchase_button)
	
	# Add spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	upgrade_list.add_child(spacer)

func _on_upgrade_purchased(upgrade: Dictionary) -> void:
	if GameManager.spend_money(upgrade.cost):
		apply_upgrade(upgrade)
		upgrade["purchased_count"] = upgrade.get("purchased_count", 0) + 1
		upgrade_purchased.emit(upgrade.type, upgrade.cost)
		
		# Refresh the menu
		show_menu(GameManager.current_day, GameManager.daily_earnings, GameManager.money)
		
		print("Purchased upgrade: ", upgrade.name)
	else:
		print("Not enough money for upgrade: ", upgrade.name)

func apply_upgrade(upgrade: Dictionary) -> void:
	var shop = get_tree().get_first_node_in_group("shop")
	match upgrade.type:
		"drop_zone":
			# Add new drop zone (would need to modify shop scene)
			if shop:
				# shop.add_drop_zone() # Uncomment if implemented
				pass
		"patience":
			Customer.patience_time += 10.0
		"new_item":
			if shop:
				shop.add_new_item_type(upgrade.item_data)
		"more_customers":
			if shop:
				shop.max_customers_per_day += 2
		"price_boost":
			if shop:
				for item in shop.available_items:
					item.price += 1

func _on_continue_pressed() -> void:
	visible = false
	menu_closed.emit()
	GameManager.next_day()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_continue_pressed()
