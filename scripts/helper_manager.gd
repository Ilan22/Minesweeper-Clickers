extends Node

var helpers = {}
@onready var game_manager = %GameManager
@onready var progress_bar_pickaxe: ProgressBar = %ProgressBarPickaxeUpgrade

func _ready():
	for child in get_children():
		helpers[child.name] = child

func update_timer(helper_name: String, cooldown: float):
	helpers[helper_name].update_timer(cooldown)

func is_stopped(helper_name: String):
	return helpers[helper_name].is_stopped()
	
func helper_action(helper_name: String):
	game_manager.helper_action(helper_name)
	
func update_progress_bar(helper_name: String, value: float):
	match helper_name:
		"Pickaxe":
			progress_bar_pickaxe.value = value
