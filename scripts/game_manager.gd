extends Node

# ========================
# CONSTANTS
# ========================

# Grid & Game
const TILE = preload("uid://cbctdxy3ecxmn")
const AUTOSAVE_INTERVAL: float = 30.0
const STUN_DURATION: float = 5.0

const GRID_SIZES: Array[int] = [5, 6, 7, 10, 12]
const TABLE_NB_BOMBS: Dictionary = {
	5: 3,
	6: 8,
	7: 12,
	10: 18,
	12: 22
}

# Miners configuration
const MINERS: Dictionary = {
	"Pickaxe": {
		"base_cost": 25,
		"cost_exponent": 1.6,
		"damage_exponent": 0.7,
		"damage_base": 1.4,
		"color": Color("929191"),
		"locked_color": Color("929191"),
		"threshold_color": Color("ffde00"),
		"label_color": "[color=929191]",
		"cooldowns": [2, 1, 0.5, 0.1]
	},
	"Drill": {
		"base_cost": 80,
		"cost_exponent": 1.65,
		"damage_exponent": 1.0,
		"damage_base": 1.45,
		"color": Color("c46a2d"),
		"locked_color": Color("c46a2d"),
		"threshold_color": Color("ffde00"),
		"label_color": "[color=c46a2d]",
		"cooldowns": [2, 1, 0.5, 0.1]
	},
	"Dynamite": {
		"base_cost": 200,
		"cost_exponent": 1.7,
		"damage_exponent": 1.3,
		"damage_base": 1.5,
		"color": Color("ff0000"),
		"locked_color": Color("ff0000"),
		"threshold_color": Color("ffde00"),
		"label_color": "[color=red]",
		"cooldowns": [2, 1, 0.5, 0.1]
	},
	"Laser": {
		"base_cost": 500,
		"cost_exponent": 1.75,
		"damage_exponent": 1.6,
		"damage_base": 1.55,
		"color": Color("2d92fd"),
		"locked_color": Color("2d92fd"),
		"threshold_color": Color("ffde00"),
		"label_color": "[color=2d92fd]",
		"cooldowns": [2, 1, 0.5, 0.1]
	},
	"Atomizer": {
		"base_cost": 1500,
		"cost_exponent": 1.8,
		"damage_exponent": 1.9,
		"damage_base": 1.6,
		"color": Color("a8f16e"),
		"locked_color": Color("a8f16e"),
		"threshold_color": Color("ffde00"),
		"label_color": "[color=a8f16e]",
		"cooldowns": [2, 1, 0.5, 0.1]
	}
}

const UPGRADE_THRESHOLDS: Array[int] = [24, 49, 99]
const CLICKER_COST_BASE: int = 10
const CLICKER_COST_EXPONENT: float = 1.5

# ========================
# NODES & REFERENCES
# ========================

@onready var grid_container: GridContainer = %GridContainer
@onready var camera: Camera2D = %Camera
@onready var helper_manager = $HelperManager
@onready var boss_timer: Timer = %BossTimer
var autosave_timer: Timer
# ========================
# GAME STATE
# ========================

var grid_size: int = 5
var nb_total_tiles: int
var nb_tiles_left_to_discover: int
var tiles: Array[Tile] = []
var gameStarted: bool = false
var win: bool = false
var game_over: bool = false
var boss_level: bool = false

var hps_of_tile: BigNumber
var coins_reward: BigNumber

# Player stats
var level: int = 1
var next_level_in: int = 10
var coins: BigNumber = BigNumber.new()
var infinite_level: bool = false
var coins_per_second: BigNumber = BigNumber.new()
var offline_income: BigNumber

# Clicker upgrade
var clicker_upgrade_level: int = 0
var clicker_next_cost: BigNumber
var clicker_damage: BigNumber = BigNumber.new()

# Miners: level, cooldown, dps, cost, damage
var miners_data: Dictionary = {}

# Stun mechanic
var apply_stun: bool = false
var stun_timer: float

var rng = RandomNumberGenerator.new()

const MAX_OFFLINE_SECONDS := 60 * 60 * 2 # 2h max

# UI - Main labels
@onready var coins_label: Label = %CoinsLabel
@onready var coins_reward_label: RichTextLabel = %CoinsReward
@onready var hp_label: Label = %HPsLabel
@onready var hp_progress_bar: ProgressBar = %HPsProgressbar

# UI - Level panels
@onready var prior_level_panel: Button = %PriorLevelPanel
@onready var current_level_panel: Panel = %CurrentLevelPanel
@onready var next_level_panel: Button = %NextLevelPanel
@onready var next_level_in_label: RichTextLabel = %LevelRemainingLabel

# UI - Clicker
@onready var clicker_upgrade_label: RichTextLabel = %LabelClickerUpgrade
@onready var clicker_upgrade_button_label: RichTextLabel = %LabelClickerUpgradeButton
@onready var clicker_upgrade_button_color: Panel = %LabelClickerUpgradeButtonColor
@onready var clicker_upgrade_block_panel: Panel = %BlockPanelClicker

# UI - Boss
@onready var boss_panel: Panel = %Boss
@onready var boss_label: Label = %BossLabel
@onready var boss_progress_bar: ProgressBar = %BossProgressbar

# UI - Stun
@onready var stun_progress_panel: Panel = %StunProgress
@onready var stun_progress_bar: ProgressBar = %StunProgressBar

# UI - Miners (individual references kept for direct access)
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

# UI - Offline income
@onready var offline_income_control: Control = %OfflineIncome
@onready var offline_income_label: Label = %OfflineIncomeLabel
@onready var offline_income_progress_bar: ProgressBar = %OfflineIncomeProgressBar

# UI - Miners dictionaries for iteration
var miners_ui: Dictionary = {}

func _ready() -> void:
	init_miners_ui()
	init_miners_data()
	
	# Autosave timer setup
	autosave_timer = Timer.new()
	autosave_timer.wait_time = AUTOSAVE_INTERVAL
	autosave_timer.timeout.connect(save_game)
	autosave_timer.autostart = true
	add_child(autosave_timer)

	load_game()
	
	boss_timer.timeout.connect(on_boss_timer_timeout)
	
	reset_game(true)

# ========================
# INITIALIZATION
# ========================

func init_miners_ui() -> void:
	"""Initialize UI node references for all miners"""
	miners_ui = {
		"Pickaxe": {
			"label": pickaxe_upgrade_label,
			"button_label": pickaxe_upgrade_button_label,
			"button_color": pickaxe_upgrade_button_color,
			"block_panel": pickaxe_upgrade_block_panel,
			"locked_panel": pickaxe_locked_panel
		},
		"Drill": {
			"label": drill_upgrade_label,
			"button_label": drill_upgrade_button_label,
			"button_color": drill_upgrade_button_color,
			"block_panel": drill_upgrade_block_panel,
			"locked_panel": drill_locked_panel
		},
		"Dynamite": {
			"label": dynamite_upgrade_label,
			"button_label": dynamite_upgrade_button_label,
			"button_color": dynamite_upgrade_button_color,
			"block_panel": dynamite_upgrade_block_panel,
			"locked_panel": dynamite_locked_panel
		},
		"Laser": {
			"label": laser_upgrade_label,
			"button_label": laser_upgrade_button_label,
			"button_color": laser_upgrade_button_color,
			"block_panel": laser_upgrade_block_panel,
			"locked_panel": laser_locked_panel
		},
		"Atomizer": {
			"label": atomizer_upgrade_label,
			"button_label": atomizer_upgrade_button_label,
			"button_color": atomizer_upgrade_button_color,
			"block_panel": atomizer_upgrade_block_panel,
			"locked_panel": atomizer_locked_panel
		}
	}

func init_miners_data() -> void:
	"""Initialize miners data structure"""
	for miner_name in MINERS.keys():
		var config: Dictionary = MINERS[miner_name]
		miners_data[miner_name] = {
			"level": 0,
			"damage": BigNumber.new(),
			"cooldown": 0.0,
			"dps": BigNumber.new(),
			"next_cost": big_number_calcul_fixed_base(0, config["base_cost"], config["cost_exponent"], 0)
		}
		miners_data[miner_name]["damage"].mantissa = 0
		miners_data[miner_name]["dps"].mantissa = 0

func place_bombs(tileClicked: Tile):
	var nbBombLeftToPlace: int = 0
	
	while nbBombLeftToPlace < TABLE_NB_BOMBS[grid_size]:
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
	coins_reward = big_number_calcul_fixed_exponent(1, 0.6, level, 1.5)
	boss_label.text = "BOSS ! " + str(round(boss_timer.wait_time * 10) / 10.0).rstrip("0").rstrip(".") + "s"
		
	next_level_in_label.visible = true
	if (level == 1 and next_level_in == 10):
		grid_size = 5
		boss_panel.visible = false
		boss_level = false
	elif (level == 1 and next_level_in == 9):
		grid_size = 6
		boss_panel.visible = false
		boss_level = false
	elif (level == 1 and next_level_in == 8):
		grid_size = 7
		boss_panel.visible = false
		boss_level = false
	elif ((level) % 10 == 5):
		grid_size = 10
		hps_of_tile.multiply_equals(5)
		coins_reward.multiply_equals(5)
		boss_panel.visible = true
		boss_level = true
		next_level_in_label.visible = false
	elif ((level) % 10 == 0):
		grid_size = 12
		hps_of_tile.multiply_equals(10)
		coins_reward.multiply_equals(10)
		boss_panel.visible = true
		boss_level = true
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
	nb_total_tiles = grid_size * grid_size - TABLE_NB_BOMBS[grid_size]
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

# ========================
# UPGRADES
# ========================

func clicker_upgrade_button() -> void:
	if apply_stun:
		return
	
	var cost: BigNumber = big_number_calcul_fixed_base(0, CLICKER_COST_BASE, CLICKER_COST_EXPONENT, clicker_upgrade_level)
	if not coins.is_greater_than_or_equal_to(cost):
		return
	
	coins.minus_equals(cost)
	coins_label.text = big_numbers_to_string(coins)
	clicker_upgrade_level += 1
	clicker_next_cost = big_number_calcul_fixed_base(0, CLICKER_COST_BASE, CLICKER_COST_EXPONENT, clicker_upgrade_level)
	
	if clicker_upgrade_level in UPGRADE_THRESHOLDS:
		clicker_upgrade_button_color.modulate = Color("ffde00")
		clicker_next_cost.multiply_equals(10)
	else:
		clicker_upgrade_button_color.modulate = Color("ffffff")
	
	_calculate_clicker_damage()
	clicker_upgrade_label.text = "Clicker - lvl %d\n%s per click" % [clicker_upgrade_level, big_numbers_to_string(clicker_damage)]
	clicker_upgrade_button_label.text = "[color=gold]%s\ncoins[/color]" % big_numbers_to_string(clicker_next_cost)
	check_if_player_can_buy()

func pickaxe_upgrade_button() -> void:
	upgrade_miner("Pickaxe")

func drill_upgrade_button() -> void:
	upgrade_miner("Drill")

func dynamite_upgrade_button() -> void:
	upgrade_miner("Dynamite")

func laser_upgrade_button() -> void:
	upgrade_miner("Laser")

func atomizer_upgrade_button() -> void:
	upgrade_miner("Atomizer")

func upgrade_miner(miner_name: String) -> void:
	"""Generic upgrade function for all miners"""
	if apply_stun:
		return
	
	var config: Dictionary = MINERS[miner_name]
	var data: Dictionary = miners_data[miner_name]
	var cost: BigNumber = big_number_calcul_fixed_base(0, config["base_cost"], config["cost_exponent"], data["level"])
	print(coins)
	print(cost)
	if not coins.is_greater_than_or_equal_to(cost):
		return
	
	coins.minus_equals(cost)
	coins_label.text = big_numbers_to_string(coins)
	data["level"] += 1
	
	# Update damage based on level
	data["damage"] = big_number_calcul_fixed_exponent(0, config["damage_exponent"], data["level"], config["damage_base"])
	
	# Update cooldown - always recalculate based on current level
	var new_cooldown: float = _get_cooldown_for_level(data["level"], config["cooldowns"])
	if new_cooldown != data["cooldown"] or helper_manager.is_stopped(miner_name) or data["level"] in [1, 25, 50, 100]:
		data["cooldown"] = new_cooldown
		helper_manager.update_timer(miner_name, data["cooldown"])
	
	# Calculate next cost
	data["next_cost"] = big_number_calcul_fixed_base(0, config["base_cost"], config["cost_exponent"], data["level"])
	
	# Apply threshold multiplier if at special levels
	if data["level"] in UPGRADE_THRESHOLDS:
		miners_ui[miner_name]["button_color"].modulate = config["threshold_color"]
		data["next_cost"].multiply_equals(10)
	else:
		miners_ui[miner_name]["button_color"].modulate = config["color"]
	
	# Update DPS
	var damage_copy: BigNumber = BigNumber.new()
	damage_copy.mantissa = data["damage"].mantissa
	damage_copy.exponent = data["damage"].exponent
	data["dps"] = damage_copy.divide(data["cooldown"])
	
	update_coins_per_second()
	
	# Update UI
	_update_miner_ui(miner_name)
	check_if_player_can_buy()

func _get_cooldown_for_level(level_to_test: int, cooldowns: Array) -> float:
	"""Get cooldown based on level thresholds"""
	if level_to_test <= 24:
		return cooldowns[0]
	elif level_to_test <= 49:
		return cooldowns[1]
	elif level_to_test <= 99:
		return cooldowns[2]
	else:
		return cooldowns[3]

func _update_miner_ui(miner_name: String) -> void:
	"""Update UI for a specific miner"""
	var config: Dictionary = MINERS[miner_name]
	var data: Dictionary = miners_data[miner_name]
	var ui: Dictionary = miners_ui[miner_name]
	
	if data["level"] == 0:
		ui["label"].text = "%s%s[/color]\nLocked" % [config["label_color"], miner_name]
	else:
		ui["label"].text = "%s%s[/color] - lvl %d\n%s dps\nEvery %ss" % [
			config["label_color"],
			miner_name,
			data["level"],
			big_numbers_to_string(data["dps"]),
			float_to_str(data["cooldown"])
		]
	
	ui["button_label"].text = "[color=gold]%s\ncoins[/color]" % big_numbers_to_string(data["next_cost"])
		
func update_coins_per_second():
	var total_dps: BigNumber = BigNumber.new()
	total_dps.mantissa = 0
	for miner_name in MINERS.keys():
		total_dps.plus_equals(miners_data[miner_name]["dps"])
	
	coins_per_second = coins_reward.multiply(total_dps).divide(hps_of_tile)
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
					check_tile(tile, miners_data["Pickaxe"]["damage"], true)
				"Drill":
					check_tile(tile, miners_data["Drill"]["damage"], true)
				"Dynamite":
					check_tile(tile, miners_data["Dynamite"]["damage"], true)
				"Laser":
					check_tile(tile, miners_data["Laser"]["damage"], true)
				"Atomizer":
					check_tile(tile, miners_data["Atomizer"]["damage"], true)
			
			action_done = true
			
func _calculate_clicker_damage():
	"""Calculate clicker damage based on current upgrade level"""
	var multiplier = 1
	if clicker_upgrade_level >= 100:
		multiplier = 6
	elif clicker_upgrade_level >= 50:
		multiplier = 4
	elif clicker_upgrade_level >= 25:
		multiplier = 2
	clicker_damage.mantissa = 1
	clicker_damage.exponent = 0
	clicker_damage.plus_equals(clicker_upgrade_level * multiplier)

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
		floored.floor_value()
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
		floored.floor_value()
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
		stun_progress_bar.value = (stun_timer / STUN_DURATION) * 100.0
		
		if stun_timer <= 0:
			_remove_stun_effect()

func _remove_stun_effect() -> void:
	"""Remove stun effect and restore UI"""
	stun_progress_panel.visible = false
	apply_stun = false
	check_if_player_can_buy()
	
	for miner_name in MINERS.keys():
		if miners_data[miner_name]["level"] != 0:
			helper_manager.remove_stun(miner_name)
			# Remove the " [color=red]x2[/color]" suffix that was added
			var ui_label = miners_ui[miner_name]["label"]
			ui_label.text = ui_label.text.substr(0, ui_label.text.length() - 22)

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
	stun_timer = STUN_DURATION
	stun_progress_panel.visible = true
	
	clicker_upgrade_block_panel.visible = true
	for miner_name in MINERS.keys():
		miners_ui[miner_name]["block_panel"].visible = true
		if miners_data[miner_name]["level"] != 0:
			helper_manager.apply_stun(miner_name)
			miners_ui[miner_name]["label"].text += " [color=red]x2[/color]"

func check_if_player_can_buy():
	if apply_stun:
		return
	
	# Clicker
	if coins.is_greater_than_or_equal_to(clicker_next_cost):
		clicker_upgrade_block_panel.visible = false
	else:
		clicker_upgrade_block_panel.visible = true
	
	# Pickaxe (first miner, always available)
	if coins.is_greater_than_or_equal_to(miners_data["Pickaxe"]["next_cost"]):
		pickaxe_upgrade_block_panel.visible = false
		pickaxe_locked_panel.visible = false
	else:
		pickaxe_upgrade_block_panel.visible = true
	
	if miners_data["Pickaxe"]["level"] == 0:
		miners_ui["Pickaxe"]["label"].text = "%s%s[/color]\nLocked" % [MINERS["Pickaxe"]["label_color"], "Pickaxe"]
	
	# Other miners: only available if previous miner is unlocked
	var prev_available: bool = miners_data["Pickaxe"]["level"] > 0
	_update_miner_availability("Drill", prev_available)
	
	prev_available = miners_data["Drill"]["level"] > 0
	_update_miner_availability("Dynamite", prev_available)
	
	prev_available = miners_data["Dynamite"]["level"] > 0
	_update_miner_availability("Laser", prev_available)
	
	prev_available = miners_data["Laser"]["level"] > 0
	_update_miner_availability("Atomizer", prev_available)

func _update_miner_availability(miner_name: String, is_available: bool) -> void:
	"""Update buy button visibility for a miner based on availability"""
	var data: Dictionary = miners_data[miner_name]
	var ui: Dictionary = miners_ui[miner_name]
	
	if not is_available:
		ui["block_panel"].visible = true
		ui["locked_panel"].visible = true
		return
	
	if coins.is_greater_than_or_equal_to(data["next_cost"]):
		ui["block_panel"].visible = false
		ui["locked_panel"].visible = false
	else:
		ui["block_panel"].visible = true
			
	if data["level"] == 0:
		ui["label"].text = "%s%s[/color]\nLocked" % [MINERS[miner_name]["label_color"], miner_name]
			
			
			
# ========================
# SAVE/LOAD
# ========================

func save_game():
	var helpers_data: Dictionary = {}
	for miner_name in MINERS.keys():
		helpers_data[miner_name.to_lower()] = {
			"level": miners_data[miner_name]["level"],
			"timer_time_left": helper_manager.get_timer_time_left(miner_name)
		}
	
	SaveManager.save_game({
		"level": level,
		"next_level_in": next_level_in,
		"infinite_level": infinite_level,
		"coins": {
			"mantissa": coins.mantissa,
			"exponent": coins.exponent
		},
		"coins_per_second": {
			"mantissa": coins_per_second.mantissa,
			"exponent": coins_per_second.exponent
		},
		"clicker_upgrade_level": clicker_upgrade_level,
		"helpers": helpers_data,
		"offline_time": {
			"last_unix": Time.get_unix_time_from_system(),
			"last_date": Time.get_datetime_dict_from_system(),
		}
	})

func load_game():
	# Init coins
	coins.mantissa = 0
	coins_per_second.mantissa = 0
	clicker_damage.mantissa = 1
	
	var game_data = SaveManager.load_game()
	if game_data != null:
		level = game_data.level
		next_level_in = game_data.next_level_in
		infinite_level = game_data.infinite_level
		coins.mantissa = game_data.coins.mantissa
		coins.exponent = game_data.coins.exponent
		clicker_upgrade_level = game_data.clicker_upgrade_level
		coins_per_second.mantissa = game_data.coins_per_second.mantissa
		coins_per_second.exponent= game_data.coins_per_second.exponent
		
		# Load miners data
		for miner_name in MINERS.keys():
			var miner_key: String = miner_name.to_lower()
			if miner_key in game_data.helpers:
				miners_data[miner_name]["level"] = game_data.helpers[miner_key].level
				_load_miner_ui(miner_name, game_data.helpers[miner_key].timer_time_left)
		
		# Initialize miners that weren't in save data (new game)
		for miner_name in MINERS.keys():
			if miners_data[miner_name]["level"] == 0:
				_load_miner_ui(miner_name, 0.0)
		
		# Recalculate next_cost for all miners based on loaded levels
		for miner_name in MINERS.keys():
			var config: Dictionary = MINERS[miner_name]
			var data: Dictionary = miners_data[miner_name]
			data["next_cost"] = big_number_calcul_fixed_base(0, config["base_cost"], config["cost_exponent"], data["level"])
			# Update UI to reflect the recalculated cost
			_update_miner_ui(miner_name)
		
		# Offline income
		var offline_seconds = get_offline_seconds(game_data.offline_time)
		
		if offline_seconds > 0:
			offline_income_control.visible = true
			offline_income_progress_bar.value = clamp(float(offline_seconds) / 7200.0 * 100.0, 0.0, 100.0)
			
			offline_income = coins_per_second.multiply(offline_seconds)
			offline_income_label.text = "+ " + big_numbers_to_string(offline_income) + " coins"
	else:
		# New game: initialize miners UI
		for miner_name in MINERS.keys():
			_load_miner_ui(miner_name, 0.0)
	
	coins_label.text = big_numbers_to_string(coins)
	_update_clicker_ui()
	check_if_player_can_buy()
	
	coins_reward = big_number_calcul_fixed_exponent(1, 0.6, level, 1.5)

func get_offline_seconds(saved_data) -> int:
	var current_unix = Time.get_unix_time_from_system()
	var current_date = Time.get_datetime_dict_from_system()

	var elapsed = current_unix - saved_data.last_unix

	if elapsed < 0:
		return 0

	if elapsed > MAX_OFFLINE_SECONDS:
		elapsed = MAX_OFFLINE_SECONDS

	if current_date.year < saved_data.last_date.year:
		return 0

	return int(elapsed)

func close_offline_income():
	offline_income_control.visible = false
	coins.plus_equals(offline_income)
	coins_label.text = big_numbers_to_string(coins)
	check_if_player_can_buy()

func _load_miner_ui(miner_name: String, timer_time_left: float) -> void:
	"""Load and setup UI for a specific miner"""
	var config: Dictionary = MINERS[miner_name]
	var data: Dictionary = miners_data[miner_name]
	var ui: Dictionary = miners_ui[miner_name]
	
	# Calculate next cost regardless of level
	data["next_cost"] = big_number_calcul_fixed_base(0, config["base_cost"], config["cost_exponent"], data["level"])
	
	if data["level"] == 0:
		ui["label"].text = "%s%s[/color]\nLocked" % [config["label_color"], miner_name]
	else:
		# Calculate damage and cooldown
		data["damage"] = big_number_calcul_fixed_exponent(0, config["damage_exponent"], data["level"], config["damage_base"])
		data["cooldown"] = _get_cooldown_for_level(data["level"], config["cooldowns"])
		
		# Update helper timer
		if helper_manager.is_stopped(miner_name) or data["level"] in [1, 25, 50, 100]:
			helper_manager.update_timer(miner_name, data["cooldown"])
		
		helper_manager.set_timer_time_left(miner_name, timer_time_left)
		
		# Apply threshold multiplier
		if data["level"] in UPGRADE_THRESHOLDS:
			ui["button_color"].modulate = config["threshold_color"]
			data["next_cost"].multiply_equals(10)
		else:
			ui["button_color"].modulate = config["color"]
		
		# Update DPS
		var damage_copy: BigNumber = BigNumber.new()
		damage_copy.mantissa = data["damage"].mantissa
		damage_copy.exponent = data["damage"].exponent
		data["dps"] = damage_copy.divide(data["cooldown"])
	
	# Update UI
	_update_miner_ui(miner_name)

func _update_clicker_ui() -> void:
	"""Update clicker UI"""
	clicker_next_cost = big_number_calcul_fixed_base(0, CLICKER_COST_BASE, CLICKER_COST_EXPONENT, clicker_upgrade_level)
	
	_calculate_clicker_damage()
	
	if clicker_upgrade_level in UPGRADE_THRESHOLDS:
		clicker_upgrade_button_color.modulate = Color("ffde00")
		clicker_next_cost.multiply_equals(10)
	else:
		clicker_upgrade_button_color.modulate = Color("ffffff")
	
	clicker_upgrade_label.text = "Clicker - lvl %d\n%s per click" % [clicker_upgrade_level, big_numbers_to_string(clicker_damage)]
	clicker_upgrade_button_label.text = "[color=gold]%s\ncoins[/color]" % big_numbers_to_string(clicker_next_cost)

	
# =========================
# EXIT GAME SAVE
# =========================

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()
