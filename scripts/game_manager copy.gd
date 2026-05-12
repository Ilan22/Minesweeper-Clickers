extends Node

@onready var grid_container: GridContainer = %GridContainer
@onready var camera: Camera2D = %Camera
@onready var helper_manager = $HelperManager
@onready var boss_timer: Timer = %BossTimer
const TILE = preload("uid://cbctdxy3ecxmn")
var autosave_timer: Timer

var grid_size: int = 5
var table_nb_bombs = {
	5: 3,
	6: 8,
	7: 12,
	10: 18,
	12: 22
}
var nb_total_tiles: int
var nb_tiles_left_to_discover: int
var tiles: Array[Tile] = []
var gameStarted: bool = false
var win: bool = false
var hps_of_tile: BigNumber
var coins_reward: BigNumber
var boss_level: bool = false
var game_over: bool = false
var apply_stun: bool = false
var stun_timer: float
var clicker_next_cost: BigNumber
var pickaxe_next_cost: BigNumber
var drill_next_cost: BigNumber
var dynamite_next_cost: BigNumber
var laser_next_cost: BigNumber
var atomizer_next_cost: BigNumber

var rng = RandomNumberGenerator.new()

# Miners stats
var pickaxe_damage: BigNumber = BigNumber.new()
var drill_damage: BigNumber = BigNumber.new()
var dynamite_damage: BigNumber = BigNumber.new()
var laser_damage: BigNumber = BigNumber.new()
var atomizer_damage: BigNumber = BigNumber.new()

# Player stats
var level: int = 1
var next_level_in: int = 10
var coins: BigNumber = BigNumber.new()
var infinite_level: bool = false

var clicker_upgrade_level: int = 0
var pickaxe_level: int = 0
var pickaxe_cooldown: float = 0
var pickaxe_dps: BigNumber = BigNumber.new()
var drill_level: int = 0
var drill_cooldown: float = 0
var drill_dps: BigNumber = BigNumber.new()
var dynamite_level: int = 0
var dynamite_cooldown: float = 0
var dynamite_dps: BigNumber = BigNumber.new()
var laser_level: int = 0
var laser_cooldown: float = 0
var laser_dps: BigNumber = BigNumber.new()
var atomizer_level: int = 0
var atomizer_cooldown: float = 0
var atomizer_dps: BigNumber = BigNumber.new()

# UI
@onready var prior_level_panel: Button = %PriorLevelPanel
@onready var current_level_panel: Panel = %CurrentLevelPanel
@onready var next_level_panel: Button = %NextLevelPanel
@onready var next_level_in_label: RichTextLabel = %LevelRemainingLabel
@onready var coins_label: Label = %CoinsLabel
@onready var coins_reward_label: RichTextLabel = %CoinsReward
@onready var clicker_upgrade_label: RichTextLabel = %LabelClickerUpgrade
@onready var clicker_upgrade_button_label: RichTextLabel = %LabelClickerUpgradeButton
@onready var clicker_upgrade_button_color: Panel = %LabelClickerUpgradeButtonColor
@onready var clicker_upgrade_block_panel: Panel = %BlockPanelClicker
@onready var pickaxe_upgrade_label: RichTextLabel = %LabelPickaxeUpgrade
@onready var pickaxe_upgrade_button_label: RichTextLabel = %LabelPickaxeUpgradeButton
@onready var pickaxe_upgrade_button_color: Panel = %LabelPickaxeUpgradeButtonPanel
@onready var pickaxe_upgrade_block_panel: Panel = %BlockPanelPickaxe
@onready var pickaxe_locked_panel: Panel = %LockedPickaxe
@onready var drill_upgrade_label: RichTextLabel = %LabelDrillUpgrade
@onready var drill_upgrade_button_label: RichTextLabel = %LabelDrillUpgradeButton
@onready var drill_upgrade_button_color: Panel = %LabelDrillUpgradeButtonPanel
@onready var drill_upgrade_block_panel: Panel = %BlockPanelDrill
@onready var drill_locked_panel: Panel = %LockedDrill
@onready var dynamite_upgrade_label: RichTextLabel = %LabelDynamiteUpgrade
@onready var dynamite_upgrade_button_label: RichTextLabel = %LabelDynamiteUpgradeButton
@onready var dynamite_upgrade_button_color: Panel = %LabelDynamiteUpgradeButtonColor
@onready var dynamite_upgrade_block_panel: Panel = %BlockPanelDynamite
@onready var dynamite_locked_panel: Panel = %LockedDynamite
@onready var laser_upgrade_label: RichTextLabel = %LabelLaserUpgrade
@onready var laser_upgrade_button_label: RichTextLabel = %LabelLaserUpgradeButton
@onready var laser_upgrade_button_color: Panel = %LabelLaserUpgradeButtonColor
@onready var laser_upgrade_block_panel: Panel = %BlockPanelLaser
@onready var laser_locked_panel: Panel = %LockedLaser
@onready var atomizer_upgrade_label: RichTextLabel = %LabelAtomizerUpgrade
@onready var atomizer_upgrade_button_label: RichTextLabel = %LabelAtomizerUpgradeButton
@onready var atomizer_upgrade_button_color: Panel = %LabelAtomizerUpgradeButtonColor
@onready var atomizer_upgrade_block_panel: Panel = %BlockPanelAtomizer
@onready var atomizer_locked_panel: Panel = %LockedAtomizer
@onready var hp_label: Label = %HPsLabel
@onready var hp_progress_bar: ProgressBar = %HPsProgressbar
@onready var boss_panel: Panel = %Boss
@onready var boss_label: Label = %BossLabel
@onready var boss_progress_bar: ProgressBar = %BossProgressbar
@onready var stun_progress_panel: Panel = %StunProgress
@onready var stun_progress_bar: ProgressBar = %StunProgressBar

func _ready() -> void:
	# Déclenchement autosave toutes les 30 secondes
	autosave_timer = Timer.new()
	autosave_timer.wait_time = 30.0
	autosave_timer.timeout.connect(save_game)
	autosave_timer.autostart = true
	add_child(autosave_timer)

	load_game()
	
	boss_timer.timeout.connect(on_boss_timer_timeout)
	
	reset_game(true)
			
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
	game_over = false
	helper_manager.resume_helpers()
	
	hps_of_tile = big_number_calcul_fixed_exponent(9, 0.5, level, 1.5)
	coins_reward = big_number_calcul_fixed_exponent(1 + 5000000000, 0.6, level, 1.5)
	boss_label.text = "BOSS ! " + str(round(boss_timer.wait_time * 10) / 10.0).rstrip("0").rstrip(".") + "s"
		
	next_level_in_label.visible = true
	if (level == 1):
		grid_size = 5
		boss_panel.visible = false
		boss_level = false
		boss_progress_bar.value = 100
	elif (level == 2):
		grid_size = 6
		boss_panel.visible = false
		boss_level = false
		boss_progress_bar.value = 100
	elif (level == 3):
		grid_size = 7
		boss_panel.visible = false
		boss_level = false
		boss_progress_bar.value = 100
	elif ((level) % 10 == 5):
		grid_size = 10
		hps_of_tile.multiply_equals(5)
		coins_reward.multiply_equals(5)
		boss_panel.visible = true
		boss_level = true
		boss_progress_bar.value = 100
		next_level_in_label.visible = false
	elif ((level) % 10 == 0):
		grid_size = 12
		hps_of_tile.multiply_equals(10)
		coins_reward.multiply_equals(10)
		boss_panel.visible = true
		boss_level = true
		boss_progress_bar.value = 100
		next_level_in_label.visible = false
	else:
		var values = [5, 6, 7]
		var weights = [0.5, 0.3, 0.2]
		
		var r = randf()
		var cumulative = 0.0
		
		for i in range(values.size()):
			cumulative += weights[i]
			if r < cumulative:
				grid_size = values[i]
				break
				
		boss_panel.visible = false
		boss_level = false
		boss_progress_bar.value = 100
	update_level_display(level_changed)
	
	update_coins_per_second()
	
	grid_container.columns = grid_size;
	nb_total_tiles = grid_size * grid_size - table_nb_bombs[grid_size]
	nb_tiles_left_to_discover = nb_total_tiles
	
	var level_total_hps: BigNumber = hps_of_tile.multiply(nb_tiles_left_to_discover)
	hp_label.text = big_numbers_to_string(level_total_hps) + " HP"
	hp_progress_bar.value = (float(nb_tiles_left_to_discover) / nb_total_tiles) * 100.0
	
	for x in grid_size:
		for y in grid_size:
			var tile: Tile = TILE.instantiate()
			tile.initialize(x, y, hps_of_tile)
			if (x + y) % 2 == 0:
				tile.change_texture(Tile.DARK_UNREVEALED)
				tile.isDark = true
			else:
				tile.change_texture(Tile.LIGHT_UNREVEALED)
			tile.pressed.connect(click_tile.bind(tile))
			grid_container.add_child(tile)
			tiles.append(tile)
			
	grid_container.queue_sort()
	await get_tree().process_frame
	camera.center_camera()
			
func click_tile(tile: Tile):
	var clicker_damage: BigNumber = BigNumber.new()
	clicker_damage.mantissa = 1
	clicker_damage.plus_equals(clicker_upgrade_level)
	check_tile(tile, clicker_damage)

func check_tile(tile: Tile, dps: BigNumber, from_helper: bool = false):
	if !camera.has_dragged or from_helper:
		if win or game_over or (apply_stun and !from_helper):
			return
			
		if !gameStarted:
			place_bombs(tile)
			gameStarted = true
			if boss_level:
				start_boss_timer()
			
		if tile.isRevealed:
			return
				
		var tile_is_destroyed: bool = false
		if dps.is_greater_than_or_equal_to(tile.hp):
			tile.hp.mantissa = 0.0
			tile.hp.exponent = 0
			tile_is_destroyed = true
		else:
			tile.hp.minus_equals(dps)
		
		var hp_ratio: float = tile.hp.divide(tile.max_hp).to_float()
		var breaking_panel_size: int = int(ceil((16.0 - hp_ratio * 16.0) / 2.0)) * 2
		var vector_breaking_panel_size: Vector2 = Vector2(breaking_panel_size, breaking_panel_size)
		var breaking_panel_position: int = int((16.0 - breaking_panel_size) / 2)
		var vector_breaking_panel_position: Vector2 = Vector2(breaking_panel_position, breaking_panel_position)
		(tile.dark_breaking_panel if (tile.isDark) else tile.light_breaking_panel).size = vector_breaking_panel_size
		(tile.dark_breaking_panel if (tile.isDark) else tile.light_breaking_panel).position = vector_breaking_panel_position
		
		if (tile_is_destroyed):				
			tile.isRevealed = true
			(tile.dark_breaking_panel if (tile.isDark) else tile.light_breaking_panel).visible = false
			
			if tile.isBomb:
				tile.change_texture(Tile.BOMB)
				apply_stun_action()
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
				
			coins.plus_equals(coins_reward)
			# Triche pour arrondir a l'entier supérieur (éviter les 1.99 par exemple)
			coins.plus_equals(0.5)
			coins.floor_value()
			coins_label.text = big_numbers_to_string(coins)
			check_if_player_can_buy()
				
			if nbBombsAround == 0:
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						if dx == 0 and dy == 0:
							continue
							
						var neighbor = get_tile_by_coords(tile.x + dx, tile.y + dy)
						
						if neighbor != null and !neighbor.isRevealed:
							check_tile(neighbor, dps, from_helper)
				
			nb_tiles_left_to_discover -= 1
			var level_total_hps: BigNumber = hps_of_tile.multiply(nb_tiles_left_to_discover)
			hp_label.text = big_numbers_to_string(level_total_hps) + " HP"
			hp_progress_bar.value = (float(nb_tiles_left_to_discover) / nb_total_tiles) * 100.0
			if nb_tiles_left_to_discover == 0:
				win = true
				if boss_level:
					stop_boss_timer()
					
				helper_manager.pause_helpers()
				var level_changed: bool = false
				if !infinite_level && !boss_level:
					if (next_level_in - 1 == 0):
						level += 1
						next_level_in = 10
						level_changed = true
					else:
						next_level_in -= 1
				elif boss_level:
					level += 1
					level_changed = true
					
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
		
	if infinite_level:
		next_level_in_label.text = "[font=res://fonts/Pix32.ttf][font_size=12]∞[/font_size][/font]"
	else:
		next_level_in_label.text = str(next_level_in)
	
func clicker_upgrade_button() -> void:
	if !apply_stun:
		var cost = big_number_calcul_fixed_base(0, 10, 1.5, clicker_upgrade_level)
		if (coins.is_greater_than(cost)):
			coins.minus_equals(cost)
			coins_label.text = big_numbers_to_string(coins)
			clicker_upgrade_level += 1
			clicker_next_cost = big_number_calcul_fixed_base(0, 10, 1.5, clicker_upgrade_level)
			
			if (clicker_upgrade_level == 24 or clicker_upgrade_level == 49 or clicker_upgrade_level == 99):
				clicker_upgrade_button_color.modulate = Color("ffde00")
				clicker_next_cost.multiply_equals(10)
			else:
				clicker_upgrade_button_color.modulate = Color("ffffff")
				
			var clicker_damage: BigNumber = BigNumber.new()
			clicker_damage.mantissa = 1
			clicker_damage.plus_equals(clicker_upgrade_level)
			clicker_upgrade_label.text = "Clicker - lvl " + str(clicker_upgrade_level) + "\n" + big_numbers_to_string(clicker_damage) + " per click"
			clicker_upgrade_button_label.text = "[color=gold]" + big_numbers_to_string(clicker_next_cost) + "\ncoins[/color]"
			check_if_player_can_buy()
		
func pickaxe_upgrade_button() -> void:
	if !apply_stun:
		var cost = big_number_calcul_fixed_base(0, 50, 1.6, pickaxe_level)
		if (coins.is_greater_than_or_equal_to(cost)):
			coins.minus_equals(cost)
			coins_label.text = big_numbers_to_string(coins)
			pickaxe_level += 1
			pickaxe_damage = big_number_calcul_fixed_exponent(0, 0.7, pickaxe_level, 1.4)
			
			if (helper_manager.is_stopped("Pickaxe") or pickaxe_level == 1 or pickaxe_level == 25 or pickaxe_level == 50 or pickaxe_level == 100):
				if (pickaxe_level >= 1 && pickaxe_level <= 24):
					helper_manager.update_timer("Pickaxe", 2)
					pickaxe_cooldown = 2
				elif (pickaxe_level >= 25 && pickaxe_level <= 49):
					helper_manager.update_timer("Pickaxe", 1)
					pickaxe_cooldown = 1
				elif (pickaxe_level >= 50 && pickaxe_level <= 99):
					helper_manager.update_timer("Pickaxe", 0.5)
					pickaxe_cooldown = 0.5
				elif (pickaxe_level >= 100):
					helper_manager.update_timer("Pickaxe", 0.1)
					pickaxe_cooldown = 0.1
			
			pickaxe_next_cost = big_number_calcul_fixed_base(0, 50, 1.6, pickaxe_level)
			
			if (pickaxe_level == 24 or pickaxe_level == 49 or pickaxe_level == 99):
				pickaxe_upgrade_button_color.modulate = Color("ffde00")
				pickaxe_next_cost.multiply_equals(10)
			else:
				pickaxe_upgrade_button_color.modulate = Color("929191")
				
			pickaxe_dps = pickaxe_damage.divide(pickaxe_cooldown)
			update_coins_per_second()
			pickaxe_upgrade_label.text = "[color=gray]Pickaxe[/color] - lvl " + str(pickaxe_level) + "\n" + big_numbers_to_string(pickaxe_dps) + " dps\nEvery " + float_to_str(pickaxe_cooldown) + "s"
			pickaxe_upgrade_button_label.text = "[color=gold]" + big_numbers_to_string(pickaxe_next_cost) + "\ncoins[/color]"
			check_if_player_can_buy()

func drill_upgrade_button() -> void:
	if !apply_stun:
		var cost = big_number_calcul_fixed_base(0, 200, 1.7, drill_level)
		if (coins.is_greater_than_or_equal_to(cost)):
			coins.minus_equals(cost)
			coins_label.text = big_numbers_to_string(coins)
			drill_level += 1
			drill_damage = big_number_calcul_fixed_exponent(0, 1.8, drill_level, 1.5)
			
			if (helper_manager.is_stopped("Drill") or drill_level == 1 or drill_level == 25 or drill_level == 50 or drill_level == 100):
				if (drill_level >= 1 && drill_level <= 24):
					helper_manager.update_timer("Drill", 2)
					drill_cooldown = 2
				elif (drill_level >= 25 && drill_level <= 49):
					helper_manager.update_timer("Drill", 1)
					drill_cooldown = 1
				elif (drill_level >= 50 && drill_level <= 99):
					helper_manager.update_timer("Drill", 0.5)
					drill_cooldown = 0.5
				elif (drill_level >= 100):
					helper_manager.update_timer("Drill", 0.1)
					drill_cooldown = 0.1
					
			drill_next_cost = big_number_calcul_fixed_base(0, 200, 1.7, drill_level)
			
			if (drill_level == 24 or drill_level == 49 or drill_level == 99):
				drill_upgrade_button_color.modulate = Color("ffde00")
				drill_next_cost.multiply_equals(10)
			else:
				drill_upgrade_button_color.modulate = Color("c46a2d")
					
			drill_dps = drill_damage.divide_equals(drill_cooldown)
			update_coins_per_second()
			drill_upgrade_label.text = "[color=c46a2d]Drill[/color] - lvl " + str(drill_level) + "\n" + big_numbers_to_string(drill_dps) + " dps\nEvery " + float_to_str(drill_cooldown) + "s"
			drill_upgrade_button_label.text = "[color=gold]" + big_numbers_to_string(drill_next_cost) + "\ncoins[/color]"
			check_if_player_can_buy()
			
func dynamite_upgrade_button() -> void:
	if !apply_stun:
		var cost = big_number_calcul_fixed_base(0, 200, 1.7, dynamite_level)
		if (coins.is_greater_than_or_equal_to(cost)):
			coins.minus_equals(cost)
			coins_label.text = big_numbers_to_string(coins)
			dynamite_level += 1
			dynamite_damage = big_number_calcul_fixed_exponent(0, 1.8, dynamite_level, 1.5)
			
			if (helper_manager.is_stopped("Dynamite") or dynamite_level == 1 or dynamite_level == 25 or dynamite_level == 50 or dynamite_level == 100):
				if (dynamite_level >= 1 && dynamite_level <= 24):
					helper_manager.update_timer("Dynamite", 2)
					dynamite_cooldown = 2
				elif (dynamite_level >= 25 && dynamite_level <= 49):
					helper_manager.update_timer("Dynamite", 1)
					dynamite_cooldown = 1
				elif (dynamite_level >= 50 && dynamite_level <= 99):
					helper_manager.update_timer("Dynamite", 0.5)
					dynamite_cooldown = 0.5
				elif (dynamite_level >= 100):
					helper_manager.update_timer("Dynamite", 0.1)
					dynamite_cooldown = 0.1
					
			dynamite_next_cost = big_number_calcul_fixed_base(0, 200, 1.7, dynamite_level)
			
			if (dynamite_level == 24 or dynamite_level == 49 or dynamite_level == 99):
				dynamite_upgrade_button_color.modulate = Color("ffde00")
				dynamite_next_cost.multiply_equals(10)
			else:
				dynamite_upgrade_button_color.modulate = Color("ff0000")
					
			dynamite_dps = dynamite_damage.divide_equals(dynamite_cooldown)
			update_coins_per_second()
			dynamite_upgrade_label.text = "[color=red]Dynamite[/color] - lvl " + str(dynamite_level) + "\n" + big_numbers_to_string(dynamite_dps) + " dps\nEvery " + float_to_str(dynamite_cooldown) + "s"
			dynamite_upgrade_button_label.text = "[color=gold]" + big_numbers_to_string(dynamite_next_cost) + "\ncoins[/color]"
			check_if_player_can_buy()
			
func laser_upgrade_button() -> void:
	if !apply_stun:
		var cost = big_number_calcul_fixed_base(0, 200, 1.7, laser_level)
		if (coins.is_greater_than_or_equal_to(cost)):
			coins.minus_equals(cost)
			coins_label.text = big_numbers_to_string(coins)
			laser_level += 1
			laser_damage = big_number_calcul_fixed_exponent(0, 1.8, laser_level, 1.5)
			
			if (helper_manager.is_stopped("Laser") or laser_level == 1 or laser_level == 25 or laser_level == 50 or laser_level == 100):
				if (laser_level >= 1 && laser_level <= 24):
					helper_manager.update_timer("Laser", 2)
					laser_cooldown = 2
				elif (laser_level >= 25 && laser_level <= 49):
					helper_manager.update_timer("Laser", 1)
					laser_cooldown = 1
				elif (laser_level >= 50 && laser_level <= 99):
					helper_manager.update_timer("Laser", 0.5)
					laser_cooldown = 0.5
				elif (laser_level >= 100):
					helper_manager.update_timer("Laser", 0.1)
					laser_cooldown = 0.1
					
			laser_next_cost = big_number_calcul_fixed_base(0, 200, 1.7, laser_level)
			
			if (laser_level == 24 or laser_level == 49 or laser_level == 99):
				laser_upgrade_button_color.modulate = Color("ffde00")
				laser_next_cost.multiply_equals(10)
			else:
				laser_upgrade_button_color.modulate = Color("2d92fd")
					
			laser_dps = laser_damage.divide_equals(laser_cooldown)
			update_coins_per_second()
			laser_upgrade_label.text = "[color=2d92fd]Laser[/color] - lvl " + str(laser_level) + "\n" + big_numbers_to_string(laser_dps) + " dps\nEvery " + float_to_str(laser_cooldown) + "s"
			laser_upgrade_button_label.text = "[color=gold]" + big_numbers_to_string(laser_next_cost) + "\ncoins[/color]"
			check_if_player_can_buy()
			
func atomizer_upgrade_button() -> void:
	if !apply_stun:
		var cost = big_number_calcul_fixed_base(0, 200, 1.7, atomizer_level)
		if (coins.is_greater_than_or_equal_to(cost)):
			coins.minus_equals(cost)
			coins_label.text = big_numbers_to_string(coins)
			atomizer_level += 1
			atomizer_damage = big_number_calcul_fixed_exponent(0, 1.8, atomizer_level, 1.5)
			
			if (helper_manager.is_stopped("Atomizer") or atomizer_level == 1 or atomizer_level == 25 or atomizer_level == 50 or atomizer_level == 100):
				if (atomizer_level >= 1 && atomizer_level <= 24):
					helper_manager.update_timer("Atomizer", 2)
					atomizer_cooldown = 2
				elif (atomizer_level >= 25 && atomizer_level <= 49):
					helper_manager.update_timer("Atomizer", 1)
					atomizer_cooldown = 1
				elif (atomizer_level >= 50 && atomizer_level <= 99):
					helper_manager.update_timer("Atomizer", 0.5)
					atomizer_cooldown = 0.5
				elif (atomizer_level >= 100):
					helper_manager.update_timer("Atomizer", 0.1)
					atomizer_cooldown = 0.1
					
			atomizer_next_cost = big_number_calcul_fixed_base(0, 200, 1.7, atomizer_level)
			
			if (atomizer_level == 24 or atomizer_level == 49 or atomizer_level == 99):
				atomizer_upgrade_button_color.modulate = Color("ffde00")
				atomizer_next_cost.multiply_equals(10)
			else:
				atomizer_upgrade_button_color.modulate = Color("a8f16e")
					
			atomizer_dps = atomizer_damage.divide_equals(atomizer_cooldown)
			update_coins_per_second()
			atomizer_upgrade_label.text = "[color=a8f16e]Atomizer[/color] - lvl " + str(atomizer_level) + "\n" + big_numbers_to_string(atomizer_dps) + " dps\nEvery " + float_to_str(atomizer_cooldown) + "s"
			atomizer_upgrade_button_label.text = "[color=gold]" + big_numbers_to_string(atomizer_next_cost) + "\ncoins[/color]"
			check_if_player_can_buy()
		
func update_coins_per_second():
	var total_dps: BigNumber = BigNumber.new()
	total_dps.mantissa = 0
	total_dps.plus_equals(pickaxe_dps).plus_equals(drill_dps).plus_equals(dynamite_dps).plus_equals(laser_dps).plus_equals(atomizer_dps)
	
	var coins_per_second: BigNumber = coins_reward.multiply(total_dps).divide(hps_of_tile)
	coins_reward_label.text = "[color=gold]+" + big_numbers_to_string(coins_per_second) + "/s[/color]"

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
					check_tile(tile, pickaxe_damage, true)
				"Drill":
					check_tile(tile, drill_damage, true)
				"Dynamite":
					check_tile(tile, dynamite_damage, true)
				"Laser":
					check_tile(tile, laser_damage, true)
				"Atomizer":
					check_tile(tile, atomizer_damage, true)
			
			action_done = true
			
func float_to_str(value: float) -> String:
	if value == floor(value):
		return str(int(value))
	return str(value)
	
func big_numbers_to_string(value: BigNumber) -> String:
	var s = value.to_aa() if value.is_greater_than(999) else value.to_string()
	
	var regex = RegEx.new()
	regex.compile("^(\\d+)(\\.\\d+)?([a-zA-Z]*)$")
	
	var result = regex.search(s)
	if not result:
		return s
	
	var digits_before = result.get_string(1)
	var decimal_part  = result.get_string(2)
	var suffix        = result.get_string(3)
	
	var count = digits_before.length()
	
	if digits_before == "0":
		if decimal_part == "" or decimal_part.trim_prefix(".").to_int() == 0:
			decimal_part = ""
		return digits_before + decimal_part + suffix
		
	match count:
		1:
			if decimal_part.length() > 3:
				decimal_part = decimal_part.substr(0, 3)
		2:
			if decimal_part.length() > 2:
				decimal_part = decimal_part.substr(0, 2)
		_:
			decimal_part = ""
	
	if decimal_part in [".0", ".00"]:
		decimal_part = ""
	
	return digits_before + decimal_part + suffix

# pow(base_fixe, level) → ex: pow(1.5, clicker_level)
func big_number_calcul_fixed_base(value1, value2, value3, value4) -> BigNumber:
	var base = BigNumber.new()
	base.mantissa = 1.0
	base.exponent = 0
	base.multiply_equals(value3)
	
	var powered = base.power(value4)
	var result = powered.multiply(value2).plus(value1)
	
	var floored = result.multiply(1.0)
	floored.floor_value()
	if not floored.is_equal_to(result):
		floored.plus_equals(1)
	return floored

# pow(level, exposant_fixe) → ex: pow(pickaxe_level, 1.4)
func big_number_calcul_fixed_exponent(value1, value2, value3, value4) -> BigNumber:
	var base = BigNumber.new()
	base.mantissa = 1.0
	base.exponent = 0
	base.multiply_equals(value3)
	
	var powered = base.power(value4)
	var result = powered.multiply(value2).plus(value1)
	
	var floored = result.multiply(1.0)
	floored.floor_value()
	if not floored.is_equal_to(result):
		floored.plus_equals(1)
	return floored
	
func start_boss_timer():
	boss_timer.start()
	
func stop_boss_timer():
	boss_timer.stop()
	
func on_boss_timer_timeout():
	helper_manager.pause_helpers()
	game_over = true
	boss_label.text = "BOSS ! 0s"
	for t in tiles:
		if t.isBomb:
			t.change_texture(Tile.BOMB)
			(t.dark_breaking_panel if (t.isDark) else t.light_breaking_panel).visible = false
	await get_tree().create_timer(1.0).timeout
	reset_game()
	pass
	
func _process(_delta):
	if (!boss_timer.is_stopped()):
		var elapsed: float = boss_timer.wait_time - boss_timer.time_left
		var ratio: float = elapsed / boss_timer.wait_time
		boss_progress_bar.value = (1.0 - ratio) * 100.0
		boss_label.text = "BOSS ! " + str(round(boss_timer.time_left * 10) / 10.0).rstrip("0").rstrip(".") + "s"
		
	if apply_stun:
		stun_timer -= _delta
		stun_progress_bar.value = (stun_timer / 5.0) * 100.0
		
		if stun_timer <= 0:
			stun_progress_panel.visible = false
			apply_stun = false
			check_if_player_can_buy()
			if pickaxe_level != 0:
				helper_manager.remove_stun("Pickaxe")
				pickaxe_upgrade_label.text = pickaxe_upgrade_label.text.substr(0, pickaxe_upgrade_label.text.length() - 22)
			if drill_level != 0:
				helper_manager.remove_stun("Drill")
				drill_upgrade_label.text = drill_upgrade_label.text.substr(0, drill_upgrade_label.text.length() - 22)
			if dynamite_level != 0:
				helper_manager.remove_stun("Dynamite")
				dynamite_upgrade_label.text = dynamite_upgrade_label.text.substr(0, dynamite_upgrade_label.text.length() - 22)
			if laser_level != 0:
				helper_manager.remove_stun("Laser")
				laser_upgrade_label.text = laser_upgrade_label.text.substr(0, laser_upgrade_label.text.length() - 22)
			if atomizer_level != 0:
				helper_manager.remove_stun("Atomizer")
				atomizer_upgrade_label.text = atomizer_upgrade_label.text.substr(0, atomizer_upgrade_label.text.length() - 22)

func click_past_level():
	if boss_level:
		level -= 1
		infinite_level = true
		update_level_display(true)
		stop_boss_timer()
		reset_game()
	
func click_next_level():
	if infinite_level:
		level += 1
		infinite_level = false
		reset_game(true)
		update_level_display(true)
		
func apply_stun_action():
	apply_stun = true
	stun_timer = 5.0
	stun_progress_panel.visible = true
	
	clicker_upgrade_block_panel.visible = true
	pickaxe_upgrade_block_panel.visible = true
	drill_upgrade_block_panel.visible = true
	dynamite_upgrade_block_panel.visible = true
	laser_upgrade_block_panel.visible = true
	atomizer_upgrade_block_panel.visible = true
	if pickaxe_level != 0:
		helper_manager.apply_stun("Pickaxe")
		pickaxe_upgrade_label.text += " [color=red]x2[/color]"
	if drill_level != 0:
		helper_manager.apply_stun("Drill")
		drill_upgrade_label.text += " [color=red]x2[/color]"
	if dynamite_level != 0:
		helper_manager.apply_stun("Dynamite")
		dynamite_upgrade_label.text += " [color=red]x2[/color]"
	if laser_level != 0:
		helper_manager.apply_stun("Laser")
		laser_upgrade_label.text += " [color=red]x2[/color]"
	if atomizer_level != 0:
		helper_manager.apply_stun("Atomizer")
		atomizer_upgrade_label.text += " [color=red]x2[/color]"

func check_if_player_can_buy():
	if !apply_stun:
		if coins.is_greater_than_or_equal_to(clicker_next_cost):
			clicker_upgrade_block_panel.visible = false
		else:
			clicker_upgrade_block_panel.visible = true
			
		if coins.is_greater_than_or_equal_to(pickaxe_next_cost):
			pickaxe_upgrade_block_panel.visible = false
			pickaxe_locked_panel.visible = false
		else:
			pickaxe_upgrade_block_panel.visible = true
			
		if pickaxe_level > 0:
			if coins.is_greater_than_or_equal_to(drill_next_cost):
				drill_upgrade_block_panel.visible = false
				drill_locked_panel.visible = false
			else:
				drill_upgrade_block_panel.visible = true
				
		if drill_level > 0:
			if coins.is_greater_than_or_equal_to(dynamite_next_cost):
				dynamite_upgrade_block_panel.visible = false
				dynamite_locked_panel.visible = false
			else:
				dynamite_upgrade_block_panel.visible = true
		
		if dynamite_level > 0:
			if coins.is_greater_than_or_equal_to(laser_next_cost):
				laser_upgrade_block_panel.visible = false
				laser_locked_panel.visible = false
			else:
				laser_upgrade_block_panel.visible = true
			
		if laser_level > 0:
			if coins.is_greater_than_or_equal_to(atomizer_next_cost):
				atomizer_upgrade_block_panel.visible = false
				atomizer_locked_panel.visible = false
			else:
				atomizer_upgrade_block_panel.visible = true
			
			
			
			
			
# Call from save manager
func save_game():
	SaveManager.save_game({
		"level": level,
		"next_level_in": next_level_in,
		"infinite_level": infinite_level,
		"coins": {
			"mantissa": coins.mantissa,
			"exponent": coins.exponent
		},
		"clicker_upgrade_level": clicker_upgrade_level,
		"helpers": {
			"pickaxe": {
				"level": pickaxe_level,
				"timer_time_left": helper_manager.get_timer_time_left("Pickaxe")
			},
			"drill": {
				"level": drill_level,
				"timer_time_left": helper_manager.get_timer_time_left("Drill")
			},
			"dynamite": {
				"level": dynamite_level,
				"timer_time_left": helper_manager.get_timer_time_left("Dynamite")
			},
			"laser": {
				"level": laser_level,
				"timer_time_left": helper_manager.get_timer_time_left("Laser")
			},
			"atomizer": {
				"level": atomizer_level,
				"timer_time_left": helper_manager.get_timer_time_left("Atomizer")
			},
		}
	})

# Call save manager to load
func load_game():
	# Init BigNumbers
	coins.mantissa = 0
	pickaxe_dps.mantissa = 0
	drill_dps.mantissa = 0
	dynamite_dps.mantissa = 0
	laser_dps.mantissa = 0
	atomizer_dps.mantissa = 0
	
	var game_data = SaveManager.load_game()
	if game_data != null:
		level = game_data.level
		next_level_in = game_data.next_level_in
		infinite_level = game_data.infinite_level
		coins.mantissa = game_data.coins.mantissa
		coins.exponent = game_data.coins.exponent
		clicker_upgrade_level = game_data.clicker_upgrade_level
		pickaxe_level = game_data.helpers.pickaxe.level
		drill_level = game_data.helpers.drill.level
		dynamite_level = game_data.helpers.dynamite.level
		laser_level = game_data.helpers.laser.level
		atomizer_level = game_data.helpers.atomizer.level
	
	coins_label.text = big_numbers_to_string(coins)
	check_if_player_can_buy()
	
	# Init UI
	# click upgrade
	clicker_next_cost = big_number_calcul_fixed_base(0, 10, 1.5, clicker_upgrade_level)
	var clicker_damage: BigNumber = BigNumber.new()
	clicker_damage.mantissa = 1
	clicker_damage.plus_equals(clicker_upgrade_level)
	clicker_upgrade_label.text = "Clicker - lvl " + str(clicker_upgrade_level) + "\n" + big_numbers_to_string(clicker_damage) + " per click"
	clicker_upgrade_button_label.text = "[color=gold]" + big_numbers_to_string(clicker_next_cost) + "\ncoins[/color]"
	
	# pickaxe
	pickaxe_next_cost = big_number_calcul_fixed_base(0, 50, 1.6, pickaxe_level)
	if pickaxe_level == 0:
		pickaxe_upgrade_label.text = "[color=gray]Pickaxe[/color]\nLocked"
	else: 
		pickaxe_damage = big_number_calcul_fixed_exponent(0, 0.7, pickaxe_level, 1.4)
		if (helper_manager.is_stopped("Pickaxe") or pickaxe_level == 1 or pickaxe_level == 25 or pickaxe_level == 50 or pickaxe_level == 100):
			if (pickaxe_level >= 1 && pickaxe_level <= 24):
				pickaxe_cooldown = 2
				helper_manager.update_timer("Pickaxe", pickaxe_cooldown)
			elif (pickaxe_level >= 25 && pickaxe_level <= 49):
				pickaxe_cooldown = 1
				helper_manager.update_timer("Pickaxe", pickaxe_cooldown)
			elif (pickaxe_level >= 50 && pickaxe_level <= 99):
				pickaxe_cooldown = 0.5
				helper_manager.update_timer("Pickaxe", pickaxe_cooldown)
			elif (pickaxe_level >= 100):
				pickaxe_cooldown = 0.1
				helper_manager.update_timer("Pickaxe", pickaxe_cooldown)
		
		helper_manager.set_timer_time_left("Pickaxe", float(game_data.helpers.pickaxe.timer_time_left))
		
		if (pickaxe_level == 24 or pickaxe_level == 49 or pickaxe_level == 99):
			pickaxe_upgrade_button_color.modulate = Color("ffde00")
			pickaxe_next_cost.multiply_equals(10)
		else:
			pickaxe_upgrade_button_color.modulate = Color("929191")
			
		pickaxe_dps = pickaxe_damage.divide(pickaxe_cooldown)
		pickaxe_upgrade_label.text = "[color=gray]Pickaxe[/color] - lvl " + str(pickaxe_level) + "\n" + big_numbers_to_string(pickaxe_dps) + " dps\nEvery " + float_to_str(pickaxe_cooldown) + "s"
	pickaxe_upgrade_button_label.text = "[color=gold]" + big_numbers_to_string(pickaxe_next_cost) + "\ncoins[/color]"
	
	# drill
	drill_next_cost = big_number_calcul_fixed_base(0, 50, 1.6, drill_level)
	if drill_level == 0:
		drill_upgrade_label.text = "[color=c46a2d]Drill[/color]\nLocked"
	else: 
		drill_damage = big_number_calcul_fixed_exponent(0, 0.7, drill_level, 1.4)
		if (helper_manager.is_stopped("Drill") or drill_level == 1 or drill_level == 25 or drill_level == 50 or drill_level == 100):
			if (drill_level >= 1 && drill_level <= 24):
				helper_manager.update_timer("Drill", 2)
				drill_cooldown = 2
			elif (drill_level >= 25 && drill_level <= 49):
				helper_manager.update_timer("Drill", 1)
				drill_cooldown = 1
			elif (drill_level >= 50 && drill_level <= 99):
				helper_manager.update_timer("Drill", 0.5)
				drill_cooldown = 0.5
			elif (drill_level >= 100):
				helper_manager.update_timer("Drill", 0.1)
				drill_cooldown = 0.1
				
		helper_manager.set_timer_time_left("Drill", float(game_data.helpers.drill.timer_time_left))
		
		if (drill_level == 24 or drill_level == 49 or drill_level == 99):
			drill_upgrade_button_color.modulate = Color("ffde00")
			drill_next_cost.multiply_equals(10)
		else:
			drill_upgrade_button_color.modulate = Color("c46a2d")
			
		drill_dps = drill_damage.divide(drill_cooldown)
		drill_upgrade_label.text = "[color=c46a2d]Drill[/color] - lvl " + str(drill_level) + "\n" + big_numbers_to_string(drill_dps) + " dps\nEvery " + float_to_str(drill_cooldown) + "s"
	drill_upgrade_button_label.text = "[color=gold]" + big_numbers_to_string(drill_next_cost) + "\ncoins[/color]"
	
	# dynamite
	dynamite_next_cost = big_number_calcul_fixed_base(0, 50, 1.6, dynamite_level)
	if dynamite_level == 0:
		dynamite_upgrade_label.text = "[color=red]Dynamite[/color]\nLocked"
	else: 
		dynamite_damage = big_number_calcul_fixed_exponent(0, 0.7, dynamite_level, 1.4)
		if (helper_manager.is_stopped("Dynamite") or dynamite_level == 1 or dynamite_level == 25 or dynamite_level == 50 or dynamite_level == 100):
			if (dynamite_level >= 1 && dynamite_level <= 24):
				helper_manager.update_timer("Dynamite", 2)
				dynamite_cooldown = 2
			elif (dynamite_level >= 25 && dynamite_level <= 49):
				helper_manager.update_timer("Dynamite", 1)
				dynamite_cooldown = 1
			elif (dynamite_level >= 50 && dynamite_level <= 99):
				helper_manager.update_timer("Dynamite", 0.5)
				dynamite_cooldown = 0.5
			elif (dynamite_level >= 100):
				helper_manager.update_timer("Dynamite", 0.1)
				dynamite_cooldown = 0.1
				
		helper_manager.set_timer_time_left("Dynamite", float(game_data.helpers.dynamite.timer_time_left))
		
		if (dynamite_level == 24 or dynamite_level == 49 or dynamite_level == 99):
			dynamite_upgrade_button_color.modulate = Color("ffde00")
			dynamite_next_cost.multiply_equals(10)
		else:
			dynamite_upgrade_button_color.modulate = Color("ff0000")
			
		dynamite_dps = dynamite_damage.divide(dynamite_cooldown)
		dynamite_upgrade_label.text = "[color=red]Dynamite[/color] - lvl " + str(dynamite_level) + "\n" + big_numbers_to_string(dynamite_dps) + " dps\nEvery " + float_to_str(dynamite_cooldown) + "s"
	dynamite_upgrade_button_label.text = "[color=gold]" + big_numbers_to_string(dynamite_next_cost) + "\ncoins[/color]"
	
	# laser
	laser_next_cost = big_number_calcul_fixed_base(0, 50, 1.6, laser_level)
	if laser_level == 0:
		laser_upgrade_label.text = "[color=2d92fd]Laser[/color]\nLocked"
	else: 
		laser_damage = big_number_calcul_fixed_exponent(0, 0.7, laser_level, 1.4)
		if (helper_manager.is_stopped("Laser") or laser_level == 1 or laser_level == 25 or laser_level == 50 or laser_level == 100):
			if (laser_level >= 1 && laser_level <= 24):
				helper_manager.update_timer("Laser", 2)
				laser_cooldown = 2
			elif (laser_level >= 25 && laser_level <= 49):
				helper_manager.update_timer("Laser", 1)
				laser_cooldown = 1
			elif (laser_level >= 50 && laser_level <= 99):
				helper_manager.update_timer("Laser", 0.5)
				laser_cooldown = 0.5
			elif (laser_level >= 100):
				helper_manager.update_timer("Laser", 0.1)
				laser_cooldown = 0.1
				
		helper_manager.set_timer_time_left("Laser", float(game_data.helpers.laser.timer_time_left))
		
		if (laser_level == 24 or laser_level == 49 or laser_level == 99):
			laser_upgrade_button_color.modulate = Color("ffde00")
			laser_next_cost.multiply_equals(10)
		else:
			laser_upgrade_button_color.modulate = Color("2d92fd")
			
		laser_dps = laser_damage.divide(laser_cooldown)
		laser_upgrade_label.text = "[color=2d92fd]Laser[/color] - lvl " + str(laser_level) + "\n" + big_numbers_to_string(laser_dps) + " dps\nEvery " + float_to_str(laser_cooldown) + "s"
	laser_upgrade_button_label.text = "[color=gold]" + big_numbers_to_string(laser_next_cost) + "\ncoins[/color]"
	
	# atomizer
	atomizer_next_cost = big_number_calcul_fixed_base(0, 50, 1.6, atomizer_level)
	if atomizer_level == 0:
		atomizer_upgrade_label.text = "[color=a8f16e]Atomizer[/color]\nLocked"
	else: 
		atomizer_damage = big_number_calcul_fixed_exponent(0, 0.7, atomizer_level, 1.4)
		if (helper_manager.is_stopped("Atomizer") or atomizer_level == 1 or atomizer_level == 25 or atomizer_level == 50 or atomizer_level == 100):
			if (atomizer_level >= 1 && atomizer_level <= 24):
				helper_manager.update_timer("Atomizer", 2)
				atomizer_cooldown = 2
			elif (atomizer_level >= 25 && atomizer_level <= 49):
				helper_manager.update_timer("Atomizer", 1)
				atomizer_cooldown = 1
			elif (atomizer_level >= 50 && atomizer_level <= 99):
				helper_manager.update_timer("Atomizer", 0.5)
				atomizer_cooldown = 0.5
			elif (atomizer_level >= 100):
				helper_manager.update_timer("Atomizer", 0.1)
				atomizer_cooldown = 0.1
				
		helper_manager.set_timer_time_left("Atomizer", float(game_data.helpers.atomizer.timer_time_left))
		
		if (atomizer_level == 24 or atomizer_level == 49 or atomizer_level == 99):
			atomizer_upgrade_button_color.modulate = Color("ffde00")
			atomizer_next_cost.multiply_equals(10)
		else:
			atomizer_upgrade_button_color.modulate = Color("a8f16e")
			
		atomizer_dps = atomizer_damage.divide(atomizer_cooldown)
		atomizer_upgrade_label.text = "[color=a8f16e]Atomizer[/color] - lvl " + str(atomizer_level) + "\n" + big_numbers_to_string(atomizer_dps) + " dps\nEvery " + float_to_str(atomizer_cooldown) + "s"
	atomizer_upgrade_button_label.text = "[color=gold]" + big_numbers_to_string(atomizer_next_cost) + "\ncoins[/color]"

	coins_reward = big_number_calcul_fixed_exponent(1 + 5000000000, 0.6, level, 1.5)
	update_coins_per_second()
	
# =========================
# EXIT GAME SAVE
# =========================

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()
