extends Node

var timer: Timer
var cooldown: float
@onready var helper_manager = %HelperManager

func _ready():
	timer = get_child(0)
	timer.timeout.connect(_on_timeout)
	
func update_timer(cooldown_to_set: float):
	stop()
	timer.wait_time = cooldown_to_set 
	cooldown = cooldown_to_set
	start()

func start():
	timer.start()

func stop():
	timer.stop()

func _on_timeout():
	helper_manager.helper_action(name)

func is_stopped():
	return timer.is_stopped()

func _process(delta):
	var elapsed: float = cooldown - timer.time_left
	var ratio: float = elapsed / cooldown
	helper_manager.update_progress_bar(name, ratio * 100)
