extends Area2D
class_name DropZone

@export var accepted_shape: String = ""  # "circle", "square", "rectangle"
@export var max_items: int = 10

var contained_items: Array[Item] = []
var is_highlighted: bool = false

@onready var background: ColorRect = $Background
@onready var shape_indicator: Sprite2D = $ShapeIndicator
@onready var items_container: Node2D = $ItemsContainer

signal item_accepted(item)
signal item_removed(item)

func _ready():
	# Set up visual indicators
	update_visual_state()
	
	# Connect area signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func can_accept_item(item: Item) -> bool:
	if accepted_shape != "" and item.item_shape != accepted_shape:
		return false
	
	return contained_items.size() < max_items

func accept_item(item: Item):
	if not can_accept_item(item):
		return false
	
	# Position item in the zone
	item.reparent(items_container)
	item.position = Vector2.ZERO
	
	# Stack items if multiple of same type
	var existing_item = find_existing_item(item.item_name)
	if existing_item:
		existing_item.set_quantity(existing_item.quantity + item.quantity)
		item.queue_free()
	else:
		contained_items.append(item)
	
	item_accepted.emit(item)
	update_visual_state()
	return true

func find_existing_item(item_name: String) -> Item:
	for item in contained_items:
		if item.item_name == item_name:
			return item
	return null

func remove_item(item: Item):
	if item in contained_items:
		contained_items.erase(item)
		item_removed.emit(item)
		update_visual_state()

func clear_all_items():
	for item in contained_items:
		item.queue_free()
	contained_items.clear()
	update_visual_state()

func get_total_items() -> int:
	var total = 0
	for item in contained_items:
		total += item.quantity
	return total

func has_item(item_name: String, quantity: int) -> bool:
	var item = find_existing_item(item_name)
	return item != null and item.quantity >= quantity

func _on_area_entered(area: Area2D):
	if area is Item:
		highlight(true)

func _on_area_exited(area: Area2D):
	if area is Item:
		highlight(false)

func highlight(enabled: bool):
	is_highlighted = enabled
	update_visual_state()

func update_visual_state():
	if is_highlighted:
		background.color = Color.YELLOW
		background.color.a = 0.5
	else:
		background.color = Color.WHITE
		background.color.a = 0.3
