extends TextureButton

class_name Tile

var x: int
var y: int
var isBomb: bool = false
var isRevealed: bool = false
var isFlagged: bool = false
var max_hp: int
var hp: int
var isDark: bool = false

const DARK_ONE: Rect2 = Rect2(Vector2(0, 0), Vector2(16,16))
const DARK_TWO: Rect2 = Rect2(Vector2(32, 0), Vector2(16,16))
const DARK_THREE: Rect2 = Rect2(Vector2(64, 0), Vector2(16,16))
const DARK_FOUR: Rect2 = Rect2(Vector2(96, 0), Vector2(16,16))
const DARK_FIVE: Rect2 = Rect2(Vector2(0, 16), Vector2(16,16))
const DARK_SIX: Rect2 = Rect2(Vector2(32, 16), Vector2(16,16))
const DARK_SEVEN: Rect2 = Rect2(Vector2(64, 16), Vector2(16,16))
const DARK_EIGHT: Rect2 = Rect2(Vector2(96, 16), Vector2(16,16))
const DARK_UNREVEALED: Rect2 = Rect2(Vector2(0, 32), Vector2(16,16))
const DARK_REVEALED: Rect2 = Rect2(Vector2(32, 32), Vector2(16,16))
const DARK_FLAG: Rect2 = Rect2(Vector2(64, 32), Vector2(16,16))

const LIGHT_ONE: Rect2 = Rect2(Vector2(16, 0), Vector2(16,16))
const LIGHT_TWO: Rect2 = Rect2(Vector2(48, 0), Vector2(16,16))
const LIGHT_THREE: Rect2 = Rect2(Vector2(80, 0), Vector2(16,16))
const LIGHT_FOUR: Rect2 = Rect2(Vector2(112, 0), Vector2(16,16))
const LIGHT_FIVE: Rect2 = Rect2(Vector2(16, 16), Vector2(16,16))
const LIGHT_SIX: Rect2 = Rect2(Vector2(48, 16), Vector2(16,16))
const LIGHT_SEVEN: Rect2 = Rect2(Vector2(80, 16), Vector2(16,16))
const LIGHT_EIGHT: Rect2 = Rect2(Vector2(112, 16), Vector2(16,16))
const LIGHT_UNREVEALED: Rect2 = Rect2(Vector2(16, 32), Vector2(16,16))
const LIGHT_REVEALED: Rect2 = Rect2(Vector2(48, 32), Vector2(16,16))
const LIGHT_FLAG: Rect2 = Rect2(Vector2(80, 32), Vector2(16,16))

const GREEN_FLAG: Rect2 = Rect2(Vector2(96, 32), Vector2(16,16))
const BOMB: Rect2 = Rect2(Vector2(112, 32), Vector2(16,16))

@onready var dark_breaking_panel: Panel = %DarkBreakingPanel
@onready var light_breaking_panel: Panel = %LightBreakingPanel

func initialize(grid_x: int, grid_y: int, grid_hp):
	x = grid_x
	y = grid_y
	max_hp = grid_hp
	hp = max_hp
	
func change_texture(newTexture: Rect2):
	var atlas = AtlasTexture.new()
	atlas.atlas = texture_normal.atlas
	atlas.region = newTexture
	texture_normal = atlas

func change_dark_texture(number: int):
	match number:
		0: 
			change_texture(DARK_REVEALED)
		1: 
			change_texture(DARK_ONE)
		2: 
			change_texture(DARK_TWO)
		3: 
			change_texture(DARK_THREE)
		4: 
			change_texture(DARK_FOUR)
		5: 
			change_texture(DARK_FIVE)
		6: 
			change_texture(DARK_SIX)
		7: 
			change_texture(DARK_SEVEN)
		8: 
			change_texture(DARK_EIGHT)

func change_light_texture(number: int):
	match number:
		0: 
			change_texture(LIGHT_REVEALED)
		1: 
			change_texture(LIGHT_ONE)
		2: 
			change_texture(LIGHT_TWO)
		3: 
			change_texture(LIGHT_THREE)
		4: 
			change_texture(LIGHT_FOUR)
		5: 
			change_texture(LIGHT_FIVE)
		6: 
			change_texture(LIGHT_SIX)
		7: 
			change_texture(LIGHT_SEVEN)
		8: 
			change_texture(LIGHT_EIGHT)
