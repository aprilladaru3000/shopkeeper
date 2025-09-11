extends Node
class_name GameManager

signal day_started
signal day_ended
signal money_changed(amount)
signal customer_served

var current_day: int = 1
var money: int = 50
var day_duration: float = 180.0  # 3 minutes
var day_timer: Timer
var customers_served: int = 0
var daily_earnings: int = 0

enum GameState {
	PLAYING,
	PAUSED,
	SHOP_UPGRADE,
	GAME_OVER
}

var game_state: GameState = GameState.PLAYING

func _ready():
	setup_day_timer()
	start_day()

func setup_day_timer():
	day_timer = Timer.new()
	day_timer.wait_time = day_duration
	day_timer.one_shot = true
	day_timer.timeout.connect(_on_day_ended)
	add_child(day_timer)

func start_day():
	day_started.emit()
	customers_served = 0
	daily_earnings = 0
	day_timer.start()
	print("Day ", current_day, " started!")

func _on_day_ended():
	day_ended.emit()
	game_state = GameState.SHOP_UPGRADE
	show_day_summary()

func show_day_summary():
	# Show summary screen with earnings and upgrade options
	print("Day ", current_day, " ended!")
	print("Customers served: ", customers_served)
	print("Daily earnings: $", daily_earnings)

func add_money(amount: int):
	money += amount
	daily_earnings += amount
	money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	return false

func serve_customer():
	customers_served += 1
	customer_served.emit()

func next_day():
	current_day += 1
	game_state = GameState.PLAYING
	start_day()

func get_max_order_items() -> int:
	# Progressive difficulty: more items each day
	return min(6, 2 + current_day)
