extends Resource
class_name CustomerOrderGenerator

# Order templates based on difficulty
static var easy_orders: Array[Dictionary] = [
	{"Milk": 1, "Candy": 1},
	{"Chocolate": 2},
	{"Soda": 1, "Chips": 1},
	{"Candy": 3},
	{"Milk": 1, "Chocolate": 1, "Candy": 1}
]

static var medium_orders: Array[Dictionary] = [
	{"Milk": 2, "Chocolate": 1, "Candy": 2},
	{"Soda": 2, "Chips": 1, "Milk": 1},
	{"Chocolate": 3, "Candy": 1, "Chips": 2},
	{"Milk": 1, "Soda": 1, "Candy": 3, "Chips": 1}
]

static var hard_orders: Array[Dictionary] = [
	{"Milk": 3, "Chocolate": 2, "Candy": 1, "Chips": 2, "Soda": 1},
	{"Chocolate": 4, "Candy": 3, "Chips": 1, "Soda": 2},
	{"Milk": 2, "Chocolate": 1, "Candy": 4, "Chips": 3, "Soda": 1}
]

static func generate_order(difficulty: int, available_items: Array[Dictionary]) -> Dictionary:
	var order = {}
	var max_total_items = min(6 + difficulty, 18)  # Progressive difficulty
	var max_item_types = min(6, available_items.size())
	
	# Select 1-6 different items
	var num_items = randi_range(1, max_item_types)
	var selected_items = available_items.duplicate()
	selected_items.shuffle()
	
	var total_items = 0
	for i in range(num_items):
		if total_items >= max_total_items:
			break
		
		var item = selected_items[i]
		var remaining_capacity = max_total_items - total_items
		var max_quantity = min(remaining_capacity, 7)  # Max 7 of any item
		var quantity = randi_range(1, max_quantity)
		
		order[item.name] = quantity
		total_items += quantity
	
	return order
