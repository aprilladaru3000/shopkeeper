extends Resource
class_name ItemData

# Static item database
static var items: Array[Dictionary] = [
	{
		"name": "Milk",
		"shape": "rectangle",
		"price": 5,
		"texture_path": "res://assets/images/milk.png"
	},
	{
		"name": "Chocolate",
		"shape": "square",
		"price": 3,
		"texture_path": "res://assets/images/chocolate.png"
	},
	{
		"name": "Candy",
		"shape": "circle",
		"price": 2,
		"texture_path": "res://assets/images/candy.png"
	},
	{
		"name": "Chips",
		"shape": "rectangle",
		"price": 4,
		"texture_path": "res://assets/images/chips.png"
	},
	{
		"name": "Soda",
		"shape": "circle",
		"price": 6,
		"texture_path": "res://assets/images/soda.png"
	}
]

static func get_item_data(item_name: String) -> Dictionary:
	for item in items:
		if item.name == item_name:
			return item
	return {}

static func get_all_items() -> Array[Dictionary]:
	return items

static func add_item(item_data: Dictionary):
	items.append(item_data)
