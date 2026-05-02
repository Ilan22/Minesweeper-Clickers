extends Node

@onready var grid_container: GridContainer = %GridContainer
@onready var camera: Camera2D = %Camera
@onready var helper_manager = $HelperManager
const TILE = preload("uid://cbctdxy3ecxmn")

var grid_size: int = 5
var table_nb_bombs = {
	5: 4,
	6: 5,
	7: 6,
	9: 10
}
var nbTilesLeftToDiscover: int
var tiles: Array[Tile] = []
var gameStarted: bool = false
var win: bool = false
var hps_of_level: int
var coins_reward: int

var rng = RandomNumberGenerator.new()

# Miners stats
var pickaxe_dps: int = 0
var explosive_dps: int = 0

# Player stats
var level: int = 1
var next_level_in: int = 10
var coins: int = 0

var clicker_upgrade_level: int = 0
var pickaxe_level: int = 0
var explosive_level: int = 0

# UI
@onready var prior_level_panel: Panel = %PriorLevelPanel
@onready var current_level_panel: Panel = %CurrentLevelPanel
@onready var next_level_panel: Panel = %NextLevelPanel
@onready var next_level_in_label: Label = %LevelRemainingLabel
@onready var coins_label: Label = %CoinsLabel
@onready var pickaxe_upgrade_label: RichTextLabel = %LabelPickaxeUpgrade
#DEV
@onready var level_hp_label: Label = %LevelHP
@onready var coins_reward_label: Label = %CoinsReward
@onready var click_button_label: Label = %ClickButtonLabel
@onready var explosive_button_label: Label = %ExplosiveButtonLabel

func _ready() -> void:
	reset_game()
	
	# Init UI
	# click upgrade
	var next_cost = int(ceil(10 * pow(1.5, clicker_upgrade_level)))
	click_button_label.text = "C : " + str(clicker_upgrade_level) + "\n" + str(next_cost) + " c\n" + str(1 + clicker_upgrade_level)
	# pickaxe
	pickaxe_dps = int(ceil(0.7 * pow(pickaxe_level, 1.4)))
	next_cost = int(ceil(50 * pow(1.6, pickaxe_level)))
	pickaxe_upgrade_label.text = "[color=gray]Pickaxe[/color] - lvl " + str(pickaxe_level) + "\n[color=yellow]" + str(next_cost) + " c[/color]\n" + str(pickaxe_dps) + " dps"
	
	# miner two
	explosive_dps = int(ceil(1.8 * pow(explosive_level, 1.5)))
	next_cost = int(ceil(200 * pow(1.7, explosive_level)))
	explosive_button_label.text = "M2 : " + str(explosive_level) + "\n" + str(next_cost) + " c\n" + str(explosive_dps)
	
	# pickaxe upgrade panel
			
func place_bombs(tileClicked: Tile):
	var nbBombLeftToPlace: int = 0
	
	while nbBombLeftToPlace < table_nb_bombs[grid_size]:
		var randomX = rng.randi_range(0, grid_size - 1)
		var randomY = rng.randi_range(0, grid_size - 1)
		
		var tile: Tile = get_tile_by_coords(randomX, randomY)
		
		if tile.isBomb:
			continue
			
		if abs(tile.x - tileClicked.x) <= 1 and abs(tile.y - tileClicked.y) <= 1:
			continue
			
		tile.isBomb = true
		nbBombLeftToPlace += 1

func reset_game(level_changed: bool = false):
	for children in grid_container.get_children():
		children.queue_free()
	tiles = []
	gameStarted = false
	win = false
	if (level == 1 and next_level_in == 10):
		grid_size = 9
	else:
		grid_size = randi_range(5, 7)
	update_level_display(level_changed)
	
	# Stats calcul
	hps_of_level = ceil(9 + 0.5 * pow(level, 1.5))
	level_hp_label.text = str(hps_of_level)
	
	coins_reward = ceil(1 + 0.6 * pow(level, 1.5)) + 50000000000000000
	coins_reward_label.text = str(coins_reward)
	
	grid_container.columns = grid_size;
	nbTilesLeftToDiscover = grid_size * grid_size - table_nb_bombs[grid_size]
	for x in grid_size:
		for y in grid_size:
			var tile: Tile = TILE.instantiate()
			tile.initialize(x, y, hps_of_level)
			if (x + y) % 2 == 0:
				tile.change_texture(Tile.DARK_UNREVEALED)
				tile.isDark = true
			else:
				tile.change_texture(Tile.LIGHT_UNREVEALED)
			tile.pressed.connect(click_tile.bind(tile))
			grid_container.add_child(tile)
			tiles.append(tile)
			
func click_tile(tile: Tile):
	check_tile(tile, 1 + clicker_upgrade_level)

func check_tile(tile: Tile, dps: int):
	if !camera.has_dragged:
		if win:
			return
			
		if !gameStarted:
			place_bombs(tile)
			gameStarted = true
			
		if tile.isRevealed:
			return
		
		tile.hp -= dps
		var breaking_panel_size: int = ceil((16 - ((tile.hp * 16.0) / tile.max_hp)) / 2 * 2)
		var vector_breaking_panel_size: Vector2 = Vector2(breaking_panel_size, breaking_panel_size)
		var breaking_panel_position: int = int((16.0 - breaking_panel_size) / 2)
		var vector_breaking_panel_position: Vector2 = Vector2(breaking_panel_position, breaking_panel_position)
		(tile.dark_breaking_panel if (tile.isDark) else tile.light_breaking_panel).size = vector_breaking_panel_size
		(tile.dark_breaking_panel if (tile.isDark) else tile.light_breaking_panel).position = vector_breaking_panel_position
		
		if (tile.hp <= 0):	
			tile.isRevealed = true
			(tile.dark_breaking_panel if (tile.isDark) else tile.light_breaking_panel).visible = false
			
			if tile.isBomb:
				tile.change_texture(Tile.BOMB)
				return
			
			var nbBombsAround: int = 0
			
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
						
					var neighbor = get_tile_by_coords(tile.x + dx, tile.y + dy)
					
					if neighbor != null and neighbor.isBomb:
						nbBombsAround += 1
						
			if (tile.x + tile.y) % 2 == 0:
				tile.change_dark_texture(nbBombsAround)
			else:
				tile.change_light_texture(nbBombsAround)
				
			coins += coins_reward
			coins_label.text = str(coins)
				
			if nbBombsAround == 0:
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
							
						var neighbor = get_tile_by_coords(tile.x + dx, tile.y + dy)
						
						if neighbor != null and !neighbor.isRevealed:
							check_tile(neighbor, dps)
				
			nbTilesLeftToDiscover -= 1
			if nbTilesLeftToDiscover == 0:
				win = true
				var level_changed: bool = false
				if (next_level_in - 1 == 0):
					level += 1
					next_level_in = 10
					level_changed = true
				else:
					next_level_in -= 1
					
				for t in tiles:
					if t.isBomb:
						t.change_texture(Tile.GREEN_FLAG)
						(t.dark_breaking_panel if (t.isDark) else t.light_breaking_panel).visible = false
				await get_tree().create_timer(1.0).timeout
				reset_game(level_changed)

func get_tile_by_coords(x: int, y: int) -> Tile:
	for tile in tiles:
			if tile.x == x && tile.y == y:
				return tile
	return null
	
func update_level_display(level_changed: bool):
	if (level_changed):
		if (level != 1):
			prior_level_panel.visible = true
			var prior_level_panel_label: Label = prior_level_panel.get_child(0) as Label
			prior_level_panel_label.text = str(level - 1)
			if ((level - 1) % 10 == 5):
				prior_level_panel_label.label_settings.font_color = Color.YELLOW
			elif ((level - 1) % 10 == 0):
				prior_level_panel_label.label_settings.font_color = Color.RED
			else:
				prior_level_panel_label.label_settings.font_color = Color.WHITE
		
		var current_level_panel_label: Label = current_level_panel.get_child(0) as Label
		current_level_panel_label.text = str(level)
		if ((level) % 10 == 5):
			current_level_panel_label.label_settings.font_color = Color.YELLOW
		elif ((level) % 10 == 0):
			current_level_panel_label.label_settings.font_color = Color.RED
		else:
			current_level_panel_label.label_settings.font_color = Color.WHITE
			
		var next_level_panel_label: Label = next_level_panel.get_child(0) as Label
		next_level_panel_label.text = str(level + 1)
		if ((level + 1) % 10 == 5):
			next_level_panel_label.label_settings.font_color = Color.YELLOW
		elif ((level + 1) % 10 == 0):
			next_level_panel_label.label_settings.font_color = Color.RED
		else:
			next_level_panel_label.label_settings.font_color = Color.WHITE
		
	next_level_in_label.text = "(" + str(next_level_in) + ")"
	
func clicker_upgrade_button() -> void:
	var cost = int(ceil(10 * pow(1.5, clicker_upgrade_level)))
	if (coins > cost):
		coins -= cost
		coins_label.text = str(coins)
		clicker_upgrade_level += 1
		var next_cost = int(ceil(10 * pow(1.5, clicker_upgrade_level)))
		click_button_label.text = "C : " + str(clicker_upgrade_level) + "\n" + str(next_cost) + " c\n" + str(1 + clicker_upgrade_level)
		
func pickaxe_upgrade_button() -> void:
	var cost = int(ceil(50 * pow(1.6, pickaxe_level)))
	if (coins > cost):
		coins -= cost
		coins_label.text = str(coins)
		pickaxe_level += 1
		pickaxe_dps = int(ceil(0.7 * pow(pickaxe_level, 1.4)))
		var next_cost = int(ceil(50 * pow(1.6, pickaxe_level)))
		pickaxe_upgrade_label.text = "[color=gray]Pickaxe[/color] - lvl " + str(pickaxe_level) + "\n[color=gold]" + str(next_cost) + " coins[/color]\n" + str(pickaxe_dps) + " dps"
		
		if (helper_manager.is_stopped("Pickaxe") or pickaxe_level == 1 or pickaxe_level == 25 or pickaxe_level == 50 or pickaxe_level == 100):
			if (pickaxe_level >= 1 && pickaxe_level <= 24):
				helper_manager.update_timer("Pickaxe", 2)
			elif (pickaxe_level >= 25 && pickaxe_level <= 49):
				helper_manager.update_timer("Pickaxe", 1)
			elif (pickaxe_level >= 50 && pickaxe_level <= 99):
				helper_manager.update_timer("Pickaxe", 0.5)
			elif (pickaxe_level >= 100):
				helper_manager.update_timer("Pickaxe", 0.1)
		
func explosive_upgrade_button() -> void:
	var cost = int(ceil(200 * pow(1.7, explosive_level)))
	if (coins > cost):
		coins -= cost
		coins_label.text = str(coins)
		explosive_level += 1
		explosive_dps = int(ceil(1.8 * pow(explosive_level, 1.5)))
		var next_cost = int(ceil(200 * pow(1.7, explosive_level)))
		explosive_button_label.text = "M2 : " + str(explosive_level) + "\n" + str(next_cost) + " c\n" + str(explosive_dps)
		
		if (helper_manager.is_stopped("Explosive") or explosive_level == 1 or explosive_level == 25 or explosive_level == 50 or explosive_level == 100):
			if (explosive_level >= 1 && explosive_level <= 24):
				helper_manager.update_timer("Explosive", 2)
			elif (explosive_level >= 25 && explosive_level <= 49):
				helper_manager.update_timer("Explosive", 1)
			elif (explosive_level >= 50 && explosive_level <= 99):
				helper_manager.update_timer("Explosive", 0.5)
			elif (explosive_level >= 100):
				helper_manager.update_timer("Explosive", 0.1)

func helper_action(helper_name: String) -> void:
	if (!win):
		var action_done: bool = false
		while (!action_done):
			var randomX = rng.randi_range(0, grid_size - 1)
			var randomY = rng.randi_range(0, grid_size - 1)
			
			var tile: Tile = get_tile_by_coords(randomX, randomY)
			
			if (tile.isRevealed or tile.isBomb):
				continue
			
			match helper_name:
				"Pickaxe":
					check_tile(tile, pickaxe_dps)
				"Explosive":
					check_tile(tile, explosive_dps)
			
			action_done = true
