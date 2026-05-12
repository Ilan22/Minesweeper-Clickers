extends Node

var timer: Timer
var cooldown: float
var saved_cooldown: float
@onready var helper_manager = %HelperManager

func _ready():
	timer = get_child(0)
	timer.timeout.connect(_on_timeout)
	
func update_timer(cooldown_to_set: float):
	var ratio_elapsed: float = 0.0
	
	if not timer.is_stopped() and cooldown > 0:
		var elapsed = cooldown - timer.time_left
		ratio_elapsed = clamp(elapsed / cooldown, 0.0, 1.0)
		
	cooldown = cooldown_to_set
	
	var new_time_left = cooldown * (1.0 - ratio_elapsed)
	
	timer.stop()
	timer.wait_time = max(new_time_left, 0.05) # évite wait_time = 0
	timer.start()

func start():
	timer.start()

func stop():
	timer.stop()

func _on_timeout():
	timer.wait_time = cooldown
	timer.start()
	helper_manager.helper_action(name)

func is_stopped():
	return timer.is_stopped()

func _process(_delta):
	if timer.is_stopped() or cooldown <= 0:
		return
	var time_left_ratio = timer.time_left / cooldown
	var ratio = clamp(1.0 - time_left_ratio, 0.0, 1.0)
	helper_manager.update_progress_bar(name, ratio * 100)

func pause():
	timer.paused = true
	
func resume():
	timer.paused = false	
	
func apply_stun():
	saved_cooldown = cooldown
	update_timer(cooldown * 2)
	
func remove_stun():
	update_timer(saved_cooldown)

func set_time_left(time_left: float):
	timer.stop()
	timer.wait_time = max(time_left, 0.05)
	timer.start()
	
func get_time_left():
	return timer.time_left
