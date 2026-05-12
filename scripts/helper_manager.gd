extends Node

var helpers = {}
@onready var game_manager = %GameManager
@onready var pickaxe_progress_bar: ProgressBar = %ProgressBarPickaxeUpgrade
@onready var drill_progress_bar: ProgressBar = %ProgressBarDrillUpgrade
@onready var dynamite_progress_bar: ProgressBar = %ProgressBarDynamiteUpgrade
@onready var laser_progress_bar: ProgressBar = %ProgressBarLaserUpgrade
@onready var atomizer_progress_bar: ProgressBar = %ProgressBarAtomizerUpgrade

func _ready():
	for child in get_children():
		helpers[child.name] = child

func update_timer(helper_name: String, cooldown: float):
	helpers[helper_name].update_timer(cooldown)
	
func set_timer_time_left(helper_name: String, time_left: float):
	helpers[helper_name].set_time_left(time_left)

func is_stopped(helper_name: String):
	return helpers[helper_name].is_stopped()
	
func helper_action(helper_name: String):
	game_manager.helper_action(helper_name)
	
func update_progress_bar(helper_name: String, value: float):
	match helper_name:
		"Pickaxe":
			pickaxe_progress_bar.value = value
		"Drill":
			drill_progress_bar.value = value
		"Dynamite":
			dynamite_progress_bar.value = value
		"Laser":
			laser_progress_bar.value = value
		"Atomizer":
			atomizer_progress_bar.value = value
			
func get_timer_time_left(helper_name: String):
	return helpers[helper_name].get_time_left()

func pause_helpers():
	for helper in helpers.values():
		helper.pause()
		
func resume_helpers():
	for helper in helpers.values():
		helper.resume()

func apply_stun(helper_name: String):
	helpers[helper_name].apply_stun()
	
func remove_stun(helper_name: String):
	helpers[helper_name].remove_stun()
