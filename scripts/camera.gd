extends Camera2D
@export var drag_threshold: float = 2.0
@export var pan_speed: float = 1.0
@export var max_offset: float = 50.0
@onready var tiles_container: GridContainer = %GridContainer
var is_touching: bool = false
var last_touch_pos: Vector2
var initial_touch_pos: Vector2
var has_dragged: bool = false

func _ready():
	make_current()
	await get_tree().process_frame
	center_camera()
	set_process_input(true)
	
func center_camera():
	var grid_size = tiles_container.size
	var grid_position = tiles_container.global_position
	
	global_position = grid_position + grid_size / 2

func _input(event: InputEvent):
	if event is InputEventScreenTouch:
		is_touching = event.pressed
		if event.pressed:
			last_touch_pos = event.position
			initial_touch_pos = event.position
			has_dragged = false
		get_viewport().set_input_as_handled()
		
	elif event is InputEventScreenDrag and is_touching and check_can_move():
		var drag_distance = (event.position - initial_touch_pos).length()
		if drag_distance > drag_threshold:
			has_dragged = true
			var delta = get_screen_to_world(event.position) - get_screen_to_world(last_touch_pos)
			var new_position = global_position - delta * pan_speed
			
			# Appliquer les limites
			global_position = clamp_camera_position(new_position)
			
		last_touch_pos = event.position
		get_viewport().set_input_as_handled()

func check_can_move():
	var grid_size = tiles_container.size
	var screen_size = get_viewport_rect().size
	# Prendre en compte l'offset dans la vérification
	return (grid_size.x + 2 * max_offset) > screen_size.x or (grid_size.y + 2 * max_offset) > screen_size.y

func clamp_camera_position(new_pos: Vector2) -> Vector2:
	var grid_size = tiles_container.size
	var grid_position = tiles_container.global_position
	var screen_size = get_viewport_rect().size
	var half_screen = screen_size / 2
	
	var clamped_pos = new_pos
	
	# Gérer l'axe X
	if (grid_size.x + 2) > screen_size.x:
		# La grille + offset est plus grande que l'écran, on peut bouger avec offset
		var min_x = grid_position.x + half_screen.x - max_offset
		var max_x = grid_position.x + grid_size.x - half_screen.x + max_offset
		clamped_pos.x = clamp(new_pos.x, min_x, max_x)
	else:
		# La grille + offset est plus petite, on centre et on ne bouge pas
		clamped_pos.x = grid_position.x + grid_size.x / 2
	
	# Gérer l'axe Y
	if (grid_size.y + 2) > screen_size.y - 89:
		# La grille + offset est plus grande que l'écran, on peut bouger avec offset
		var min_y = grid_position.y + half_screen.y - max_offset
		var max_y = grid_position.y + grid_size.y - half_screen.y + max_offset
		clamped_pos.y = clamp(new_pos.y, min_y, max_y)
	else:
		# La grille + offset est plus petite, on centre et on ne bouge pas
		clamped_pos.y = grid_position.y + grid_size.y / 2
	
	return clamped_pos
	
func get_screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_pos
