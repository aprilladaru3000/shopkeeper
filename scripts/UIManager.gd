extends CanvasLayer
class_name UIManager

@onready var money_label: Label = $TopBar/MoneyLabel
@onready var day_label: Label = $TopBar/DayLabel
@onready var time_label: Label = $TopBar/TimeLabel
@onready var pause_menu: Control = $PauseMenu

var time_remaining: float = 0.0

func _ready():
	# Connect to GameManager signals
	if GameManager:
		GameManager.money_changed.connect(_on_money_changed)
		GameManager.day_started.connect(_on_day_started)
		GameManager.day_ended.connect(_on_day_ended)
	
	update_display()

func _process(delta):
	if GameManager and GameManager.game_state == GameManager.GameState.PLAYING:
		time_remaining = GameManager.day_timer.time_left
		update_time_display()

func _on_money_changed(new_amount: int):
	money_label.text = "Money: $" + str(new_amount)

func _on_day_started():
	day_label.text = "Day " + str(GameManager.current_day)
	time_remaining = GameManager.day_duration

func _on_day_ended():
	time_label.text = "Day Complete!"

func update_time_display():
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	time_label.text = "Time: %02d:%02d" % [minutes, seconds]
	
	# Change color when time is running out
	if time_remaining < 30:
		time_label.modulate = Color.RED
	elif time_remaining < 60:
		time_label.modulate = Color.YELLOW
	else:
		time_label.modulate = Color.WHITE

func update_display():
	if GameManager:
		money_label.text = "Money: $" + str(GameManager.money)
		day_label.text = "Day " + str(GameManager.current_day)

func show_pause_menu():
	pause_menu.visible = true
	get_tree().paused = true

func hide_pause_menu():
	pause_menu.visible = false
	get_tree().paused = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if pause_menu.visible:
			hide_pause_menu()
		else:
			show_pause_menu()
