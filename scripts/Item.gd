extends Area2D
class_name Item

signal item_dropped(item, drop_zone)
signal item_returned(item)

@export var item_name: String = ""
@export var item_shape: String = ""  # "circle", "square", "rectangle"
@export var item_price: int = 5
@export var item_texture: Texture2D

var is_dragging: bool = false
var original_position: Vector2
var original_parent: Node
var mouse_offset: Vector2
var quantity: int = 1

@onready var sprite: Sprite2D = $Sprite
@onready var quantity_label: Label = $QuantityLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	if item_texture:
		sprite.texture = item_texture
	
	original_position = global_position
	original_parent = get_parent()
	
	input_event.connect(_on_input_event)
	update_quantity_display()

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drag(event.global_position)
			else:
				stop_drag()

func start_drag(mouse_pos: Vector2):
	is_dragging = true
	mouse_offset = global_position - mouse_pos
	z_index = 100  # Bring to front
	
	# Move to root for global dragging
	var global_pos = global_position
	reparent(get_tree().current_scene)
	global_position = global_pos

func stop_drag():
	if not is_dragging:
		return
	
	is_dragging = false
	z_index = 0
	
	# Check for valid drop zone
	var drop_zone = find_valid_drop_zone()
	if drop_zone:
		drop_on_zone(drop_zone)
	else:
		return_to_original_position()

func find_valid_drop_zone() -> DropZone:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collision_mask = 2  # DropZone layer
	
	var result = space_state.intersect_point(query)
	
	for collision in result:
		var drop_zone = collision.collider as DropZone
		if drop_zone and drop_zone.can_accept_item(self):
			return drop_zone
	
	return null

func drop_on_zone(drop_zone: DropZone):
	drop_zone.accept_item(self)
	item_dropped.emit(self, drop_zone)

func return_to_original_position():
	# Animate back to original position
	var tween = create_tween()
	tween.tween_global_position(self, original_position, 0.3)
	tween.tween_callback(func(): reparent(original_parent))
	item_returned.emit(self)

func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() + mouse_offset

func set_quantity(new_quantity: int):
	quantity = new_quantity
	update_quantity_display()

func update_quantity_display():
	if quantity > 1:
		quantity_label.text = str(quantity)
		quantity_label.visible = true
	else:
		quantity_label.visible = false

func duplicate_item() -> Item:
	var new_item = duplicate() as Item
	new_item.quantity = 1
	return new_item
